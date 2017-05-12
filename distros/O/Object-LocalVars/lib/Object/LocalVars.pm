use 5.008;
use strict;
use warnings;

package Object::LocalVars;
# ABSTRACT: Outside-in objects with local aliasing of $self and object variables
our $VERSION = '0.21'; # VERSION

#--------------------------------------------------------------------------#
# Required modules
#--------------------------------------------------------------------------#

use Config;
use Carp;
use Scalar::Util 1.09 qw( weaken refaddr );

#--------------------------------------------------------------------------#
# Exporting -- wrap import so we can check for necessary warnings
#--------------------------------------------------------------------------#

use Exporter ();

our @EXPORT = qw(   
    caller give_methods new BUILDALL CLONE DESTROY 
    MODIFY_SCALAR_ATTRIBUTES MODIFY_CODE_ATTRIBUTES 
);

sub import {

    # check if threads are available
    if( $Config{useithreads} ) {
        my $caller = caller(0);
        
        # Warn about sharing, but not for Test:: modules which always
        # share if any threads are enabled
        if ( $INC{'threads/shared.pm'} && ! $INC{'Test/Builder.pm'} ) {
            carp   "Warning: threads::shared is enabled, but $caller uses"
                 . " Object::LocalVars (which does not allow shared objects)";
        }
    }
    
    # Hand off the rest of the import
    goto &Exporter::import;
}

#--------------------------------------------------------------------------#
# Declarations
#--------------------------------------------------------------------------#
                    
my (%public_methods, %protected_methods, %private_methods);

my %base_class_of;

my %prefixes_for;

#--------------------------------------------------------------------------#
# accessor_style
#--------------------------------------------------------------------------#

sub accessor_style {
    my (undef, $prefix) = @_;
    croak "Method accessor_style() requires a hash reference"
        if not ref $prefix eq 'HASH';
    my $class = caller(0);
    $prefixes_for{ $class } = $prefix;
}

#--------------------------------------------------------------------------#
# base_object
#--------------------------------------------------------------------------#

sub base_object {
    no strict 'refs';
    my (undef, $base) = @_;
    my $class = caller(0);
    $base_class_of{ $class } = $base;
    
    # import it if not already in @ISA
    if ( ! grep { $_ eq $base } @{$class."::ISA"} ) {
        push @{$class."::ISA"}, $base;
        $base =~ s{::}{/}g;
        $base .= ".pm";
        eval { require $base };
        croak $@ if $@ ne '';
    }

    # change to other form of new
    {
        no warnings 'redefine';
        *{$class."::new"} = \&_new_with_base;
    }
    
}

#--------------------------------------------------------------------------#
# caller
#--------------------------------------------------------------------------#

# custom caller routine ignores this module and keeps looking upwards.
# can't use Sub::Uplevel due to an off-by-one issue in the current version

use subs 'caller';
sub caller {
    my ($uplevel) = @_;
    $uplevel ||= 0;
    $uplevel++ while ( (CORE::caller($uplevel+1))[0] eq __PACKAGE__ );
    my @caller = CORE::caller($uplevel+1);
    return wantarray ? ( @_ ? @caller : @caller[0 .. 2] ) : $caller[0];
}

#--------------------------------------------------------------------------#
# give_methods
#--------------------------------------------------------------------------#

sub give_methods {
    my $package = caller;
    for ( @{$public_methods{$package}} ) {
        _install_wrapper($package, $_, "public");
    };
    for ( @{$protected_methods{$package}} ) {
        _install_wrapper($package, $_, "protected");
    };
    for ( @{$private_methods{$package}} ) {
        _install_wrapper($package, $_, "private");
    };
    return 1;
}

#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#

sub new {
    no strict 'refs';
    my ($class, @args) = @_;
    die "new can't be called on an object" if ref($class);

    # create blessed object
    my $self = \do{ my $scalar };
    bless $self, $class;

    # call initializer
    return BUILDALL( $class, $self, @args );
}

sub _new_with_base {
    no strict 'refs';
    my ($class, @args) = @_;
    die "new can't be called on an object" if ref($class);

    # create blessed object
    my $base_class = $base_class_of{ $class };
    my $prebuild = *{$class."::PREBUILD"}{CODE};
    my @filtered_args 
        = defined $prebuild ? $prebuild->($base_class, @args) : @args;
    my $self = $base_class->new( @filtered_args ); 
    bless $self, $class;
    my $addr = refaddr $self;
    ${$class . "::TRACKER"}{$addr} = $self;
    weaken ${$class . "::TRACKER"}{$addr}; # don't let this stop destruction

    # call initializer -- but skip base_class
    { 
        local @{$class."::ISA"} 
            = grep { $_ ne $base_class } @{$class."::ISA"};
        return BUILDALL( $class, $self, @_ );
    }
}

#--------------------------------------------------------------------------#
# BUILDALL
#--------------------------------------------------------------------------#

sub BUILDALL {
    no strict 'refs';
    my ($class, $self, @args) = @_;
    
    # return if we've already initialized this class
    my $addr = refaddr $self;
    return $self if ( exists ${$class . "::TRACKER"}{$addr} );

    # otherwise register $self in the tracker and continue
    ${$class . "::TRACKER"}{$addr} = $self;
    weaken ${$class . "::TRACKER"}{$addr}; # don't let this stop destruction
    
    # initialize superclasses if they can
    for my $superclass (@{"${class}::ISA"}) {
        if ( my $super_buildall = $superclass->can( 'BUILDALL' ) ) {
            my $prebuild = *{$class."::PREBUILD"}{CODE};
            my @filtered_args = 
                defined $prebuild ? $prebuild->($superclass, @args) : @args;
            $super_buildall->($superclass, $self, @filtered_args);
        }
    }
    
    # initialize self if we have an initializer
    *{$class."::BUILD"}{CODE}->($self, @args) 
        if defined *{$class."::BUILD"}{CODE};
    return $self;
}

#--------------------------------------------------------------------------#
# CLONE
#--------------------------------------------------------------------------#

sub CLONE {
    no strict 'refs';
    my $class = shift;
    for my $old_obj_id ( keys %{$class . "::TRACKER"} ) {
        my $new_obj_id = refaddr(
            ${$class . "::TRACKER"}{$old_obj_id}
        );
        for my $prop ( keys %{"${class}::DATA::"} ) {
            my $qualified_name = $class . "::DATA::$prop";
            $$qualified_name{ $new_obj_id } = $$qualified_name{ $old_obj_id };
            delete $$qualified_name{ $old_obj_id };
        }
        ${$class . "::TRACKER"}{$new_obj_id} = $new_obj_id;
        delete ${$class . "::TRACKER"}{$old_obj_id};
    }
    return 1;
}

#--------------------------------------------------------------------------#
# DESTROY
#--------------------------------------------------------------------------#

sub DESTROY {
    no strict 'refs';
    my ($self, $class) = @_;
    $class ||= ref $self;
    
    # return if we've already destructed this class
    my $addr = refaddr $self;
    return if ( ! exists ${$class . "::TRACKER"}{$addr} );
    
    # otherwise mark that we're destroying this class and continue
    delete ${$class . "::TRACKER"}{$addr};
    
    # demolish and free data for this class
    *{$class."::DEMOLISH"}{CODE}->($self) 
        if defined *{$class."::DEMOLISH"}{CODE};
    for ( keys %{"${class}::DATA::"} ) {
        delete (${"${class}::DATA::$_"}{$addr});
    }

    # destroy all superclasses
    for my $superclass ( @{"${class}::ISA"} ) {
        if ( my $super_destroyer = $superclass->can("DESTROY") ) {
            $super_destroyer->($self, $superclass);
        }
    }

}

#--------------------------------------------------------------------------#
# MODIFY_CODE_ATTRIBUTES
#--------------------------------------------------------------------------#

sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $referent, @attrs) = @_;
    for my $attr (@attrs) {
        no strict 'refs';
        if ( $attr =~ /^(?:Method|Pub)$/ ) {
            push @{$public_methods{$package}}, $referent;
            undef $attr;
        }
        elsif ($attr eq "Prot") {
            push @{$protected_methods{$package}}, $referent;
            undef $attr;
        }
        elsif ($attr eq "Priv") {
            push @{$private_methods{$package}}, $referent;
            undef $attr;
        }
    }
    return grep {defined} @attrs;    
}

#--------------------------------------------------------------------------#
# MODIFY_SCALAR_ATTRIBUTES
#--------------------------------------------------------------------------#

sub MODIFY_SCALAR_ATTRIBUTES {
    my ($OL_PACKAGE, $referent, @attrs) = @_;
    for my $attr (@attrs) {
        no strict 'refs';
        if ($attr eq "Pub") {
            _install_accessors( $OL_PACKAGE, $referent, "public", 0 );
            undef $attr;
        } 
        elsif ($attr eq "Prot") {
            _install_accessors( $OL_PACKAGE, $referent, "protected", 0 );
            undef $attr;
        }
        elsif ( $attr =~ /^(?:Prop|Priv)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "private", 0 );
            undef $attr;
        }
        elsif ( $attr =~ /^(?:ReadOnly)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "readonly", 0 );
            undef $attr;
        }
        elsif ($attr =~ /^(?:Class|ClassPriv)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "private", 1 );
            undef $attr;
        }
        elsif ($attr =~ /^(?:ClassProt)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "protected", 1 );
            undef $attr;
        }
        elsif ($attr =~ /^(?:ClassPub)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "public", 1 );
            undef $attr;
        }
        elsif ($attr =~ /^(?:ClassReadOnly)$/ ) {
            _install_accessors( $OL_PACKAGE, $referent, "readonly", 1 );
            undef $attr;
        }
        else {
            # we don't really care
        }
    }
    return grep {defined} @attrs;    
}

#--------------------------------------------------------------------------#
# _findsym
#--------------------------------------------------------------------------#

my %symcache;
sub _findsym {
    no strict 'refs';
    my ($pkg, $ref, $type) = @_;
    return $symcache{$pkg,$ref} if $symcache{$pkg,$ref};
    $type ||= ref($ref);
    my $found;
    foreach my $sym ( values %{$pkg."::"} ) {
        return $symcache{$pkg,$ref} = \$sym
            if *{$sym}{$type} && *{$sym}{$type} == $ref;
    }
}

#--------------------------------------------------------------------------#
# _gen_accessor
#--------------------------------------------------------------------------#

sub _gen_accessor {
    my ($package, $name, $classwide) = @_;
    return $classwide 
        ? "return \$${package}::CLASSDATA{${name}}"
        : "return \$${package}::DATA::${name}" .
          "{refaddr( \$_[0] )}" ;
}

#--------------------------------------------------------------------------#
# _gen_class_locals
#--------------------------------------------------------------------------#

sub _gen_class_locals {
    no strict 'refs';
    my $package = shift;
    my $evaltext = "";
    my @props = keys %{$package."::CLASSDATA"};
    return "" unless @props;
    my @globs = map { "*${package}::$_" } @props;
    my @refs = map { "\\\$${package}::CLASSDATA{$_}" } @props;
    $evaltext .= "  local ( " .  join(", ", @globs) .  " ) = ( " .
                   join(", ", @refs) . " );\n";
    return $evaltext;
}

#--------------------------------------------------------------------------#
# _gen_acc_mut
#--------------------------------------------------------------------------#

sub _gen_acc_mut {
    my ($package, $name, $classwide) = @_;
    return $classwide
        ? "return (\@_ > 1) ? " .
          "\$${package}::CLASSDATA{${name}} = \$_[1] : " .
          "\$${package}::CLASSDATA{${name}} ; " .
          "\n" 
        : "return (\@_ > 1) ? " .
          "\$${package}::DATA::${name}" . "{refaddr( \$_[0] )} = \$_[1] : " .
          "\$${package}::DATA::${name}" . "{refaddr( \$_[0] )} " .
          "\n";
}

#--------------------------------------------------------------------------#
# _gen_mutator
#--------------------------------------------------------------------------#

sub _gen_mutator {
    my ($package, $name, $classwide) = @_;
    return $classwide
        ? "\$${package}::CLASSDATA{${name}} = \$_[1];\n" .
          "return \$_[0] "
        : "\$${package}::DATA::${name}" .
          "{refaddr( \$_[0] )} = \$_[1];\n" .
          "return \$_[0]";
}

#--------------------------------------------------------------------------#
# _gen_object_locals
#--------------------------------------------------------------------------#

sub _gen_object_locals {
    no strict 'refs';
    my $package = shift;
    my @props = keys %{$package."::DATA::"};
    return "" unless @props;
    my $evaltext = "  my \$id;\n"; # need to define it
    $evaltext .= "  \$id = refaddr(\$obj) if ref(\$obj);\n";
    my @globs = map { "*${package}::$_" } @props;
    my @refs = map { "\\\$${package}::DATA::$_ {\$id}" } @props;
    $evaltext .= "  local ( " .  join(", ", @globs) .  " ) = ( " .
                   join(", ", @refs) . " ) if \$id;\n";
    return $evaltext;
}

#--------------------------------------------------------------------------#
# _gen_privacy
#--------------------------------------------------------------------------#

sub _gen_privacy {
    my ($package, $name, $privacy) = @_;
    SWITCH: for ($privacy) {
        /public/    && do { return "" };

        /protected/ && do { return 
            "  my (\$caller) = caller();\n" .
            "  croak q/$name is a protected method and can't be called from ${package}/\n".
            "    unless \$caller->isa( '$package' );\n"
        };

        /private/ && do { return
            "  my (\$caller) = caller();\n" .
            "  croak q/$name is a private method and can't be called from ${package}/\n".
            "    unless \$caller eq '$package';\n"
        };
    }
}

#--------------------------------------------------------------------------#
# _install_accessors
#--------------------------------------------------------------------------#

sub _install_accessors {
    my ($package,$scalarref,$privacy,$classwide) = @_;
    no strict 'refs';

    # find name from reference
    my $symbol = _findsym($package, $scalarref) or die;
    my $name = *{$symbol}{NAME};

    # make the property exist to be found by give_methods()
    if ($classwide) {  
        ${$package."::CLASSDATA"}{$name} = undef;
    }
    else {
        %{$package."::DATA::".$name} = ();
    }

    # determine names for accessor/mutator
    my $get = $prefixes_for{ $package }{get};
    my $set = $prefixes_for{ $package }{set};
    my $acc = ( defined $get ? $get : q{}     ) . $name;
    my $mut = ( defined $set ? $set : q{set_} ) . $name;

    # install accessors
    return if $privacy eq "private"; # unless private 
    my $accessor_privacy = $privacy eq 'readonly' ? 'public'    : $privacy;
    my $mutator_privacy  = $privacy eq 'readonly' ? 'protected' : $privacy;
    my $evaltext;
    if ( $acc ne $mut ) {
        $evaltext = 
                "*${package}::${acc} = sub { \n" .
                    _gen_privacy( $package, $name, $accessor_privacy ) .
                    _gen_accessor( $package, $name, $classwide ) .
                "\n}; \n\n" .
                "*${package}::${mut} = sub { \n" .
                    _gen_privacy( $package, "set_$name", $mutator_privacy ) .
                    _gen_mutator( $package, $name, $classwide ) .
                "\n}; "
        ; # $evaltext
    }
    else {
        $evaltext = 
                "*${package}::${mut} = sub { \n" .
                    _gen_privacy( $package, "set_$name", $mutator_privacy ) .
                    _gen_acc_mut( $package, $name, $classwide ) .
                "\n}; "
        ; # $evaltext
    }
        
    eval $evaltext; ## no critic
    die $@ if $@;
    return;
}    

#--------------------------------------------------------------------------#
# _install_wrapper
#--------------------------------------------------------------------------#

sub _install_wrapper {
    my ($package,$coderef,$privacy) = @_;
    no strict 'refs';
    no warnings 'redefine';
    my $symbol = _findsym($package, $coderef) or die;
    my $name = *{$symbol}{NAME};
    *{$package."::METHODS::$name"} = $coderef;
    my $evaltext = "*${package}::${name} = sub {\n". 
            _gen_privacy( $package, $name, $privacy ) .
            "  my \$obj = shift;\n" .
            "  local \$${package}::self = \$obj;\n" .
            _gen_class_locals($package) .
            _gen_object_locals($package) .
            "  local \$Carp::CarpLevel = \$Carp::CarpLevel + 2;\n".
            "  ${package}::METHODS::${name}(\@_);\n".
        "}\n"
    ; # my
    # XXX print "\n\n$evaltext\n\n";
    eval $evaltext; ## no critic
    die $@ if $@;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::LocalVars - Outside-in objects with local aliasing of $self and object variables

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  package My::Object;
  use strict;
  use Object::LocalVars;
 
  give_methods our $self;  # this exact line is required
 
  our $field1 : Prop;
  our $field2 : Prop;
 
  sub as_string : Method { 
    return "$self has properties '$field1' and '$field2'";
  }

=head1 DESCRIPTION

B<Do not use for production purposes!>

I<This is an experimental module I developed when exploring inside-out objects.
It is no longer supported, but is left on CPAN as an example of the kind of 
strange OO approaches that are possible with Perl.>

This module helps developers create "outside-in" objects.  Properties (and
C<$self>) are declared as package globals.  Method calls are wrapped such that
these globals take on a local value that is correct for the specific calling
object and the duration of the method call.  I.e. C<$self> is locally aliased
to the calling object and properties are locally aliased to the values of the
properties for that object.  The package globals themselves only declare
properties in the package and hold no data themselves.  Data are stored in a
separate namespace for each property, keyed off the reference memory addresses
of the objects.

Outside-in objects are similar to "inside-out" objects, which store data in a
single lexical hash (or closure) for each property, which is keyed off the
reference memory addresses of the objects.  Both differ from classic Perl
objects, which hold data for the object directly using a blessed reference or
closure to a data structure, typically a hash.  For both outside-in and
inside-out objects, data are stored centrally and the blessed reference is
simply a key to look up the right data in the central data store.

The use of package variables for outside-in objects allows for the use of
dynamic symbol table manipulation and aliasing.  As a result, Object::LocalVars
delivers a variety of features -- though with some corresponding drawbacks.

=head2 Features

=over

=item * 

Provides C<$self> automatically to methods without 'C<my $self = shift>' and
the like

=item * 

Provides dynamic aliasing of properties within methods -- methods can access
properties directly as variables without the overhead of calls to
accessors or mutators, eliminating the overhead of these calls in methods  

=item * 

Array and hash properties may be accessed via direct dereference of  
simple variables, allowing developers to push, pop, splice, etc. without
the usual tortured syntax to dereference an accessor call

=item *

Properties no longer require accessors to have compile time syntax checking
under strictures (i.e. 'C<use strict>'); 'public' properties have accessors
automatically provided as needed

=item * 

Uses attributes to mark properties and methods, but only in the BEGIN phase so
should be mod_perl friendly (though this has not been tested yet)

=item *

Provides attributes for public, protected and private properties, class
properties, and methods

=item *

Orthogonality -- can subclass just about any other class, regardless of
implementation. 

=item *

Multiple inheritance supported in initializers and destructors (though only one
superclass can be of a special, orthogonal type)

=item *

Minimally thread-safe -- objects are safely cloned across thread boundaries (or
a pseudo-fork on Win32)

=item *

Achieves these features without source filtering

=back

=head2 Drawbacks

=over

=item * 

Method inefficiency -- wrappers around methods create extra overhead on method
calls

=item *

Accessor inefficiency -- privacy checks and extra indirection through package
symbol tables create extra overhead (compared to direct hash dereferencing
of classic Perl objects)

=item *

Minimal encapsulation -- data are hidden but still publicly accessible,
unlike approaches that use lexicals or closures to create strong encapsulation;
(will be addressed in a future release)

=item *

Does not support L<threads::shared> -- objects existing before a new thread is
created will persist into the new thread, but changes in an object cannot be
reflected in the corresponding object in the other thread

=back

=head2 Design principles

I<Simplicity>

Object::LocalVars was written to simplify writing classes in Perl by
removing the need for redundant and awkward code. E.g.:

 sub foo {
     my $self = shift;                 # e.g. repetitive
     push @{$self->some_list}, "foo";  # e.g. awkward
 }    

Instead, Object::LocalVars uses  a more elegant, readable and minimalist
approach:

 our $some_list : Prop;
 
 sub foo : Method {
     push @$some_list, "foo";
 }

As with Perl, "easy things should be easy; difficult things should be possible"
and there should be a smooth learning curve from one to the other.

I<Accessors and mutators>

A major objective of Object::LocalVars is a significant reduction in the need
for accessors (and mutators).  In general, accessors break the OO encapsulation
paradigm by revealing or allowing changes to internal object state.  However,
accessors are common in Perl for two big reasons:

=over

=item *

Accessors offer typo protection.  Compare:

 $self->{created}; # correct
 $self->{craeted}; # typo
 $self->craeted(); # typo, but caught at compile time

=item *

Automatically generating accessors is easy

=back

As a result, the proliferation of accessors opens up the class internals unless
additional protections are added to the accessors to make them private.  

With Object::LocalVars's aliasing, properties stay private by default and don't
I<need> an accessor for typo safety.  If protected or public accessors are
needed for subclasses or external code to check state, these can be requested
as needed.

=head2 Terminology

Object-oriented programming suffers from a plethora of terms used to describe
certain features and characteristics of classes and objects.  Perl further
complicates this by using these or related terms for other features entirely
(e.g. attributes).  (And Perl 6 swaps around these definitions again.)  Within
this documentation, terms are used as follows:

=over

=item *

I<class> -- represents a model of associated states and behaviors in terms of
I<properties> and I<methods>; in Perl, a I<class> is represented by a
C<package>

=item *

I<object> -- represents a specific instance of a I<class>;  in Perl, an
I<object> is represented by a reference to a data structure blessed into a
particular C<package> 

=item *

I<property> -- represents a particular state of a I<class> or I<object>;
I<properties> which are common to all I<objects> of a I<class> are referred to
as I<class properties>; I<properties> which can be unique to each I<object> of
a I<class> are referred to as I<object properties>; in Object::LocalVars,
I<properties> are represented by package variables marked with an appropriate
I<attribute>

=item *

I<method> -- represents a behavior exhibited by a I<class>;
I<methods> which do not depend on I<object properties> are referred to as
I<class methods>; I<methods> which depends on I<object properties> are referred
to as I<object methods>; in Object::LocalVars, I<methods> are represented by 
subroutines marked with an appropriate I<attribute>

=item *

I<accessors> -- used generically to refer to both 'accessors' and 'mutators',
I<methods> which respectively read and change I<properties>.

=item *

I<attribute> -- code that modifies variable and subroutine declarations; in
Perl, I<attributes> are separated from variable or subroutine declarations with
a colon (e.g. 'C<our $name : Prop>'); see perldoc for L<attributes> for more
details

=back

=head1 USAGE

=head2 Getting Started

The most minimal usage of Object::LocalVars consists of importing it with
C<use> and calling the C<give_methods> routine:

 use Object::Localvars;
 give_methods our $self;  # Required

This automatically imports attribute handlers to mark properties and methods
and imports several necessary, supporting subroutines that provide basic class
functionality such as object construction and destruction.  To support
environments such as C<mod_perl>, which have no C<CHECK> or C<INIT> phases, all
attributes take effect during the C<BEGIN> phase when the module is compiled
and executed.  The C<give_methods> subroutine provides the run-time setup
aspect of this and must always appear as shown.

=head2 Declaring Object Properties

Properties are declared by specifying a package variable using the keyword
C<our> and an appropriate attribute.  There are several attributes (and aliases
for attributes) available which result in different degrees of privacy and
different resulting rules for creating accessors.

While properties are declared as an C<our> variable, they are stored elsewhere
in a private package namespace.  When methods are called, a wrapper function
temporarily I<aliases> these package variables using C<local> to their proper
class or object property values.  This allows for seamless access to 
properties, as if they were normal variables.  For example, dereferencing a
list property:

 our $favorites_list : Prop;  
 
 sub add_favorite : Method {
   my $new_item = shift;
   push @$favorites_list, $new_item;
 }

Object::LocalVars provides the following attributes for object properties:

=over

=item *

C<:Prop> or C<:Priv>

  our $prop1 : Prop;
  our $prop2 : Priv;

Either of these attributes declare a private property.  Private properties are
aliased within methods, but no accessors are created.  This is the
recommended default unless specific alternate functionality is needed. Of
course, developers are free to write methods that act as accessors,
and provide additional behavior such as argument validation.

=item *

C<:Prot>

  our $prop3 : Prot;

This attribute declares a protected property.  Protected properties are aliased
within methods, and an accessor and mutator are created.  However, the accessor
and mutator may only be called by the declaring package or a subclass of it.

=item *

C<:Pub>

  our $prop4 : Pub;

This attribute declares a public property.  Public properties are aliased
within methods, and an accessor and mutator are created that may be called from
anywhere.

=item *

C<:ReadOnly>

  our $prop5 : ReadOnly;

This attribute declares a read-only property.  Read-only properties are aliased
within methods, and an accessor and mutator are created.  The accessor is
public, but the mutator is protected.

=back

=head2 Declaring Class Properties

Class properties work like object properties, but the value of a class property
is the same in all object or class methods.

Object::LocalVars provides the following attributes for class properties:

=over

=item *

C<:Class> or C<:ClassPriv>

  our $class1 : Class;
  our $class2 : ClassPriv;

Either of these attributes declare a private class property.  Private class
properties are aliased within methods, but no accessors are
created.  This is the recommended default unless specific alternate
functionality is needed.

=item *

C<:ClassProt>

  our $class3 : ClassProt;

This attribute declares a protected class property.  Protected class properties
are aliased within methods, and an accessor and mutator are created.  However,
the accessor and mutator may only be called by the declaring package or a
subclass of it.

=item *

C<:ClassPub>

  our $class4 : ClassPub;

This attribute declares a public class property.  Public class properties are
aliased within methods, and an accessor and mutator are created that may be
called from anywhere.

=item *

C<:ClassReadOnly>

  our $class5 : ClassReadOnly;

This attribute declares a read-only class property.  Read-only class properties
are aliased within methods, and an accessor and mutator are created.  The
accessor is public, but the mutator is protected.

=back

=head2 Declaring Methods

  sub foo : Method {
    my ($arg1, $arg2) = @_;  # no need to shift $self
    # $self and all properties automatically aliased
  }

As with properties, methods are indicated by the addition of an attribute to a
subroutine declaration.  When these marked subroutines are called, a wrapper
function ensures that C<$self> and all properties are aliased appropriately and
passes only the remaining arguments to the marked subroutine.  Class properties
are always aliased to the current values of the class properties.  If
the method is called on an object, all object properties are aliased to
the state of that object.  These aliases are true aliases, not copies.  Changes
to the alias change the underlying properties.

Object::LocalVars provides the following attributes for subroutines:

=over

=item *

C<:Method> or C<:Pub>

 sub fcn1 : Method { }
 sub fcn2 : Pub { }

Either of these attributes declare a public method.  Public methods may be
called from anywhere.  This is the recommended default unless specific
alternate functionality is needed.

=item *

C<:Prot>

 sub fcn3 : Prot { }

This attribute declares a protected method.  Protected methods may be called
only from the declaring package or a subclass of it.  

=item *

C<:Priv>

 sub fcn4 : Priv { }

This attribute declares a private method.  Private methods may only be called
only from the declaring package.  See L</Hints and Tips> for good style for
calling private methods.

=back

=head2 Accessors and Mutators

 # property declarations
 
 our $name : Pub;   # :Pub creates an accessor and mutator
 our $age  : Pub;
 
 # elsewhere in code
 
 $obj->set_name( 'Fred' )->set_age( 23 );
 print $obj->name;

Properties that are public or protected automatically have appropriate
accessors and mutators generated.  By default, these use an Eiffel-style
syntax, e.g.:  C<< $obj->x() >> and C<< $obj->set_x() >>.  Mutators return
the calling object, allowing method chaining.

The prefixes for accessors and mutators may be altered using the
C<accessor_style()> class method.

=head2 Constructors and Destructors

Object::LocalVars automatically provides the standard constructor, C<new>, an
initializer, C<BUILDALL>, and the standard destructor, C<DESTROY>.  Each calls
a series of functions to manage initialization and destruction within the
inheritance model.

When C<new> is called, a new blessed object is created.  By default, this
object is an anonymous scalar.  (See L</CONFIGURATION OPTIONS> for 
how to use another type of object as a base instead.)

After the object is created, C<BUILDALL> is used to recursively initialize
superclasses using their C<BUILDALL> methods.  A user-defined C<PREBUILD>
routine can modify the arguments passed to superclasses.  The object is then
initialized using a user-defined C<BUILD>.  (This approach resembles the Perl6
object initialization model.)

A detailed program flow follows:

=over

=item *

Within C<new>: The name of the calling class is shifted off the argument list

=item * 

Within C<new>: A reference to an anonymous scalar is blessed into the calling
class

=item *

Within C<new>: C<BUILDALL> is called as an object method on the blessed
reference with a copy of the arguments to C<new>

=item *

Within C<BUILDALL>: subroutine returns if initialization for the current
class has already been done for this object

=item *

Within C<BUILDALL>: for each superclass listed in C<@ISA>, if the superclass
can call C<BUILDALL>, then C<PREBUILD> (if it exists) is called with the
name of the superclass and a copy of the remaining argument list to C<new>.
The superclass C<BUILDALL> is then called as an object method using the new
blessed reference and the results of the C<PREBUILD>.  If C<PREBUILD> does
not exist, then any C<BUILDALL> is called with a copy of the arguments to
C<new>.

=item *

Within C<BUILDALL>: if a C<BUILD> method exists, it is called as a method
using a copy of the arguments to C<new>

=back

During object destruction, the process works in reverse.  In C<DESTROY>,
user-defined cleanup for the object's class is handled with C<DEMOLISH> (if it
exists).  Then, memory for object properties is freed.  Finally, C<DESTROY> is
called for each superclass in C<@ISA> which can do C<DESTROY>.

Both C<BUILDALL> and C<DESTROY> handle "diamond" inheritance patterns 
appropriately.  Initialization and destruction will only be done once for
each superclass for any given object.

=head2 Hints and Tips

I<Calling private methods>

Good style for private method calling in traditional Perl object-oriented
programming is to call private methods directly, C<< foo($self,@args) >>,
rather than with method lookup, C<< $self->foo(@args) >>.  This avoids 
unintentionally calling a subclass method of the same name if a subclass
happens to provide one.

I<Avoiding hidden internal data>

For a package using Object::LocalVars, e.g. C<My::Package>, object properties
are stored in C<My::Package::DATA>, class properties are stored in
C<My::Package::CLASSDATA>, methods are stored in C<My::Package::METHODS>, and
objects are tracked for cloning in C<My::Package::TRACKER>. Do not access these
areas directly or overwrite them with other global data or unexpected results
are guaranteed to occur.

(In a future release of this module, this storage approach should be replaced
by fully-encapsulated anonymous symbol tables.)

=head1 METHODS TO BE WRITTEN BY A DEVELOPER

=head2 C<PREBUILD()>

 sub PREBUILD {
     my ($superclass, @args) = @_;
     # filter @args in some way
     return @args;
 }

This subroutine may be written to filter arguments given to C<BUILDALL> before
passing them to a superclass C<BUILDALL>.  I<This must not be tagged with a
C<:Method> attribute> or equivalent as it is called before the object is fully
initialized.  The primary purpose of this subroutine is to strip out any
arguments that would cause the superclass initializer to die and/or to add any
default arguments that should always be passed to the superclass.

=head2 C<BUILD()>

 # Assuming our $counter : Class;
 sub BUILD : Method {
     my %init = ( %defaults, @_ );
     $prop1 = $init{prop1};
     $counter++;
 }

This method may be written to initialize the object after it is created.  If
available, it is called at the end of C<BUILDALL>.  The C<@_> array contains
the original array passed to C<BUILDALL>.

=head2 C<DEMOLISH()>

  # Assume our $counter : Class;
 sub DEMOLISH : Method {
     $counter--;
 }

This method may be defined to provide some cleanup actions when the object goes
out of scope and is destroyed.  If available, it is called at the start of
the destructor (i.e C<DESTROY>).

=head1 METHODS AUTOMATICALLY EXPORTED

These methods will be automatically exported for use.  This export can 
be prevented by passing the method name preceded by a "!" in a list 
after the call to "use Object::LocalVars".  E.g.:

  use Object::LocalVars qw( !new );

This is generally not needed and is strongly discouraged, but is available
should developers need some very customized behavior in C<new> or C<DESTROY>
that can't be achieved with C<BUILD> and C<DEMOLISH>.

=head2 C<give_methods()>

  give_methods our $self;

Installs wrappers around all subroutines tagged as methods.  This function
(and the declaration of C<our $self>) I<must> be used in all classes built
with Object::LocalVars.  It should only be called once for any class.

=head2 C<new()>

 my $obj = Some::Class->new( @arguments );

The constructor.  Classes built with Object::LocalVars have this available by
default and do not need their own constructor.

=head2 C<caller()>

 my $caller = caller(0);

This subroutine is exported automatically and emulates the built-in C<caller>
with the exception that if the caller is Object::LocalVars (i.e. from a wrapper
function), it will continue to look upward in the calling stack until the first
non-Object::LocalVars package is found.

=head2 C<BUILDALL()>

The initializer.  It is initially called by C<new> and then recursively calls
C<BUILDALL> for all superclasses.  Arguments for superclass initialization are
filtered through C<PREBUILD>.  It should not be called by users.

=head2 C<CLONE()>

When threads are used, this subroutine is called by perl when a new thread is
created to ensure objects are properly cloned to the new thread.  Users
shouldn't call this function directly and it must not be overridden.  

=head2 C<DESTROY()>

A destructor.  This is not used within Object::LocalVars directly but is
exported automatically when Object::LocalVars is imported.  C<DESTROY> calls
C<DEMOLISH> (if it exists), frees object property memory, and then calls
C<DESTROY> for every superclass in C<@ISA>.  It should not be called by users.

=head1 CONFIGURATION OPTIONS

=head2 C<accessor_style()>

 package My::Class;
 use Object::LocalVars;
 BEGIN {
     Object::LocalVars->accessor_style( {
         get => 'get_',
         set => 'set_'
     });
 }

This class method changes the prefixes for accessors and mutators.  When
called from within a C<BEGIN> block before properties are declared, it will
change the style of all properties subsequently declared.  It takes as an
argument a hash reference with either or both of the keys 'get' and 'set'
with the values indicating the accessor/mutator prefix to be used.

If the prefix is the same for both, an combined accessor/mutator will be
created that sets the value of the property if an argument is passed and
always returns the value of the property. E.g.:

 package My::Class;
 use Object::LocalVars;
 BEGIN {
     Object::LocalVars->accessor_style( {
         get => q{},
         set => q{}
     });
 }
 
 our $age : Pub;
 
 # elsewhere
 $obj->age( $obj->age() + 1 );  # increment age by 1

Combined accessor/mutators are treated as mutators for the interpretation of 
privacy settings.

=head2 C<base_object()>

 package My::Class; 
 use Object::LocalVars; 
 Object::LocalVars->base_object( 'Another::Class' ); 
 give_methods our $self;

This class method changes the basic blessed object type for the calling package
from being an anonymous scalar to a fully-fledged object of the given type.
This allows classes build with Object::LocalVars to subclass any type of class,
regardless of its underlying implementation (e.g. a hash) -- though only a
single class can be subclassed in such a manner.  C<PREBUILD> (if it exists) is
called on the arguments to C<new> before generating the base object using its
constructor.  The object is then re-blessed into the proper class.  Other
initializers are run as normal based on @ISA, but the base class is not
initialized again.

If the given base class does not already exist in @ISA, it is imported with
C<require> and pushed onto the @ISA stack, similar to the pragma L<base>.

=head1 BENCHMARKING

Forthcoming.  In short, Object::LocalVars can be faster than traditional
approaches if the ratio of property access within methods is high relative to
number of method calls.  It is slower than traditional approaches if there are
many method calls that individually do little property access.  In general,
Object::LocalVars trades off coding elegance and clarity for speed of
execution.  

=head1 SEE ALSO

These other modules provide similar functionality and/or inspired this one. 
Quotes are from their respective documentations.

=over

=item *

L<Attribute::Property> -- "easy lvalue accessors with validation"; uses
attributes to mark object properties for accessors; validates lvalue usage
with a hidden tie

=item *

L<Class::Std> -- "provides tools that help to implement the 'inside out object'
class structure"; based on the book I<Perl Best Practices>; nice support for
multiple-inheritance and operator overloading

=item *

L<Lexical::Attributes> -- "uses a source filter to hide the details of the
Inside-Out technique from the user"; API based on Perl6 syntax; provides 
C<$self> automatically to methods

=item *

L<Spiffy> -- "combines the best parts of Exporter.pm, base.pm, mixin.pm and
SUPER.pm into one magic foundation class"; "borrows ideas from other OO
languages like Python, Ruby, Java and Perl 6"; optionally uses source filtering
to provide C<$self> automatically to methods

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Object-LocalVars/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Object-LocalVars>

  git clone https://github.com/dagolden/Object-LocalVars.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
