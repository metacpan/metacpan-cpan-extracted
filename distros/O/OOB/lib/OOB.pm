package OOB;            # fool various source parsers
package OOB::function;  # keep OOB namespace as clean as possible

# be as strict and verbose as possible
use strict;
use warnings;

# version
$OOB::VERSION = '0.13';

# modules that we need
use Scalar::Util qw( blessed refaddr reftype );
use Sub::Identify qw( sub_fullname );

# the actual out-of-band data
my %data;

# set DEBUG constant if appropriate
BEGIN {
    my $debug = 0 + ( $ENV{OOB_DEBUG} || 0 );
    eval "sub DEBUG () { $debug }";

    # we're debugging
    if ($debug) {
        warn "OOB debugging enabled\n";

        # create OOB::dump
        no warnings 'once';
        *OOB::dump = sub {
            require Data::Dumper;
            if ( defined wantarray ) {
                return wantarray ? %data : \%data;
            }
            warn Data::Dumper::Dumper( \%data );
        }
    }

    # can't use __PACKAGE__, so we use __OOB__
    eval "sub __OOB__ () { 'OOB' }";
}    #BEGIN

# coderefs of stolen DESTROY methods by class
my %stolen = ( __OOB__ . '' => \&DESTROY );

# install cloaking functions
BEGIN {
    no warnings 'redefine';

    # cloak ourselves from "blessed"
    *Scalar::Util::blessed = sub ($) {
        my $blessed = blessed $_[0];
        return if !$blessed;
        return $blessed->isa(__OOB__) ? undef : $blessed;
    };

    # determine whether someone else already stole ref()
    my $old_ref = \&CORE::GLOBAL::ref;
    eval { $old_ref->() };
    $old_ref = undef if $@ =~ m#CORE::GLOBAL::ref#;
    warn "CORE::ref function was already stolen\n"
      if DEBUG and $old_ref;

    # cloak ourselves from "ref"
    *CORE::GLOBAL::ref = sub {
        my $blessed = blessed $_[0];
        return reftype $_[0] if $blessed and $blessed->isa(__OOB__);
        return $old_ref ? $old_ref->( $_[0] ) : CORE::ref $_[0];
    };

    # determine whether someone else already stole blessed()
    my $old_bless = \&CORE::GLOBAL::bless;
    eval { $old_bless->() };
    $old_bless = undef if $@ =~ m#CORE::GLOBAL::bless#;
    warn "CORE::bless function was already stolen\n"
      if DEBUG and $old_bless;

    # make sure reblessing OOB objects does the right thing
    *CORE::GLOBAL::bless = sub {
        my $blessed = blessed $_[0];
        my $class   = $_[1] || caller();

        # make sure we can DESTROY if a new class
        _register_DESTROY($class) if $blessed and $stolen{$blessed};

        return $old_bless
          ? $old_bless->( $_[0], $class )
          : CORE::bless $_[0], $class;
    };
}    #BEGIN

# what we may export
my %export_ok;
@export_ok{ qw(
  OOB_get
  OOB_reset
  OOB_set
) } = ();

# enable final debugger if necessary
END {
    if (DEBUG) {
        require Data::Dumper;
        warn "Final state of OOB data:\n";
        warn Data::Dumper::Dumper( \%data );
    }
}

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Functional Interface
#
#-------------------------------------------------------------------------------
# OOB_get
#
#  IN: 1 reference to value
#      2 key to fetch
#      3 package in which key lives (optional)
# OUT: 1 value or undef

sub OOB_get {

    # we're debugging
    if ( DEBUG > 1 ) {
        my $id  = _unique_id( $_[0] );
        my $key = _generate_key( $_[1], $_[2] );
        warn "OOB_get with @_: $id -> $key\n";
    }

    # return value without autovivifying
    if ( my $values = $data{ _generate_key( $_[1], $_[2] ) } ) {
        return $values->{ _unique_id( $_[0] ) };
    }

    return;
}    #OOB_get

#-------------------------------------------------------------------------------
# OOB_reset
#
#  IN: 1 reference to value
#      2 package in which key lives (optional)
# OUT: 1 hash ref with all values

sub OOB_reset {

    # we're debugging
    if ( DEBUG > 1 ) {
        my $id  = _unique_id( $_[0] );
        warn "OOB_reset with @_: $id\n";
    }

    # which values to remove?
    my $id = _unique_id( $_[0] );

    # need to tell the world what we removed
    if ( defined wantarray ) {
        my %removed =
          map  { $_ => delete $data{$_}->{$id} }
          grep { exists $data{$_}->{$id} }
          keys %data;
          return \%removed;
    }

    # no need to tell what we deleted
    delete $_->{$id} foreach values %data;

    return;
}    #OOB_reset

#-------------------------------------------------------------------------------
# OOB_set
#
#  IN: 1 reference to value
#      2 key to set
#      3 value to set
#      4 package in which key lives (optional)
# OUT: 1 any old value
#      2 id of value (optional, refaddr derived)

sub OOB_set {

    # scalar specified
    if ( !reftype $_[0] ) {
        CORE::bless \$_[0], __OOB__;
    }

    # already blessed and not seen before
    elsif ( my $blessed = blessed $_[0] ) {
        _register_DESTROY($blessed);
    }

    # not blessed yet, so bless it now
    else {
        CORE::bless $_[0], __OOB__;
    }

    # we're debugging
    if ( DEBUG > 1 ) {
        my $id  = _unique_id( $_[0] );
        my $key = _generate_key( $_[1], $_[3] );
        warn "OOB_set with @_: $id -> $key\n";
    }

    # want to know old value
    if ( defined wantarray ) {
        my $id  = _unique_id( $_[0] );
        my $key = _generate_key( $_[1], $_[3] );
        my $old = $data{$key}->{$id};
        $data{$key}->{$id} = $_[2];
        return wantarray ? ( $old, $id ) : $old;
    }

    # just set it
    $data{ _generate_key( $_[1], $_[3] ) }->{ _unique_id( $_[0] ) } = $_[2];

    return;
}    #OOB_set

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
# import
#
# Export any constants requested
#
#  IN: 1 class (ignored)
#      2..N constants to be exported / attributes to be defined

sub OOB::import {
    my $class = shift;

    # nothing to export / defined
    if (!@_) {
        return;
    }

    # we want all constants
    elsif ( @_ == 1 and $_[0] eq ':all' ) {
        @_ = keys %export_ok;
    }

    # assume none exportables are attributes
    elsif ( my @attributes = grep { !exists $export_ok{$_} } @_ ) {
        _register_attribute( $class, $_ ) foreach @attributes;

        # reduce to real exportables
        @_ = grep { exists $export_ok{$_} } @_;
    }

    # something to export
    if (@_) {

        # determine namespace to export to
        my $namespace = caller() . '::';
        warn "Exporting @_ to $namespace\n" if DEBUG;

        # export requested constants
        no strict 'refs';
        *{$namespace.$_} = \&$_ foreach @_;
    }

    return;
}    #OOB::import

#-------------------------------------------------------------------------------
# AUTOLOAD
#
# Manage auto-creation of missing methods
#
#  IN: 1 class
#      2 key
#      3 value to set

sub OOB::AUTOLOAD {

    # attempting to call debug when not debugging
    return if $OOB::AUTOLOAD eq 'OOB::dump';
    
    # don't know what to do with it
    my $class = shift;
    if ( !$class->isa(__OOB__) ) {
        require Carp;
        Carp::croak( "Undefined subroutine $OOB::AUTOLOAD" );
    }

    # seems to be an attribute we don't know about
    if ( @_ == 2 ) {
        require Carp;
        $OOB::AUTOLOAD =~ m#::(\w+)$#;
        Carp::croak( "Attempt to set unregistered OOB attribute '$1'" );
    }

    # registration
    elsif ( !@_ ) {
        _register_attribute( $OOB::AUTOLOAD =~ m#^(.*)::(\w+)$# );
    }

    return;
}    #OOB::AUTOLOAD

#-------------------------------------------------------------------------------
# DESTROY
#
#  IN: 1 instantiated object

sub OOB::DESTROY {

    # what is the id?
    my $id  = _unique_id( $_[0] );

    # we're debugging
    if (DEBUG) {
        warn "OOB::DESTROY with @_: $id\n";
    }

    # perform the deletion
    delete $_->{$id} foreach values %data;

    return;
}    #OOB::DESTROY
    
#-------------------------------------------------------------------------------
#
# Internal methods
#
#-------------------------------------------------------------------------------
# _generate_key
#
# Return the key of the given parameters
#
#  IN: 1 basic key value
#      2 any package specification (default: 2 levels up)
# OUT: 1 key to be used in internal hash

sub _generate_key {

    # fetch the namespace
    my $namespace = defined $_[1]
      ? ( "$_[1]" ? "$_[1]--" : '' )
      : ( caller(1) )[0] . '--';

    return $namespace . $_[0];
}    #_generate_key

#-------------------------------------------------------------------------------
# _register_attribute
#
# Register a new class method
#
#  IN: 1 namespace
#      2 key

sub _register_attribute {
    my ( $namespace, $key ) = @_;

    # install a method to handle it
    no strict 'refs';
    *{ $namespace . '::' . $key } = sub {
        return if @_ < 2; # another registration and huh?
        return @_ == 3
         ? OOB_set( $_[1], $key => $_[2], $namespace )
         : OOB_get( $_[1], $key, $namespace );
    };
}    #_register_attribute

#-------------------------------------------------------------------------------
# _register_DESTROY
#
#  IN: 1 class to register DESTROY method for

sub _register_DESTROY {
    my $blessed = shift;

    # already has DESTROY method installed
    return if $stolen{$blessed};

    # there is a DESTROY method, need to insert ours
    if ( my $destroy = $blessed->can('DESTROY') ) {
        $stolen{$blessed} = $destroy;
        my $fullname = sub_fullname($destroy);
        no strict 'refs';
        *$fullname = sub { $destroy->( $_[0] ); &OOB::DESTROY( $_[0] ) };
    }

    # no DESTROY method yet, to set one
    else {
        no strict 'refs';
        *{ $blessed . '::DESTROY' } = $stolen{$blessed} = \&OOB::DESTROY;
    }
}     #_register_DESTROY

#-------------------------------------------------------------------------------
# _unique_id
#
# Return the key of the given parameters
#
#  IN: 1 reference to value to work with
# OUT: 1 id to be used in internal hash

sub _unique_id {

    # no ref, make it!
    my $reftype = reftype $_[0];
    if ( !$reftype ) {
        return refaddr \$_[0];
    }

    # special handling for refs to refs
    elsif ( $reftype eq 'REF' ) {
        my $ref = ${$_[0]};
        $ref = ${$ref} while reftype $ref eq 'REF';
        return refaddr $ref;
    }

    # just use the refaddr
    return refaddr $_[0];
}    #_unique_id


#-------------------------------------------------------------------------------

__END__

=head1 NAME

OOB - out of band data for any data structure in Perl

=head1 VERSION

This documentation describes version 0.13.

=head1 SYNOPSIS

 # object oriented interface
 use OOB;

 # register attributes
 use OOB qw( ContentType EpochStart Currency Accept );

 or:

 OOB->ContentType;
 OOB->EpochStart;
 OOB->Currency;
 OOB->Accept;
 OOB->Filename;

 # scalars (or scalar refs)
 OOB->ContentType( $message, 'text/html' );
 my $type = OOB->ContentType($message);
 print <<"MAIL";
 Content-Type: $type

 $message
 MAIL

 # arrays
 OOB->EpochStart( \@years, 1970 );
 my $offset = OOB->EpochStart( \@years );
 print $offset + $_ , $/ foreach @years;

 # hashes
 OOB->Currency( \%salary, 'EUR' );
 my $currency = OOB->Currency( \%salary );
 print "$_: $salary{$_} $currency\n" foreach sort keys %salary;

 # subroutines
 OOB->Accept( \&frobnicate, \@classes );
 my $classes = OOB->Accept( \&frobnicate );

 # blessed objects
 OOB->Filename( $handle, $filename );
 my $filename = OOB->Filename($handle);

 # functional interface
 use OOB qw( OOB_set OOB_get OOB_reset );

 package Foo;
 OOB_set( $scalar, key => $value );
 my $value = OOB_get( \@array, 'key' );
 OOB_reset( \%hash );

 package Bar;
 my $value = OOB_get( $arrayref, 'key', 'Foo' ); # other module's namespace

=head1 DESCRIPTION

This module makes it possible to assign any out of band data (attributes)
to any Perl data structure with both a functional and an object oriented
interface.  Out of band data is basically represented by a key / value pair.

=head2 Object Oriented Interface

The object oriented interface allows you to easily define globally accessible
meta-data attributes.  To prevent problems by poorly typed attribute names,
you need to register a new attribute at least once before being able to set
it.  Attempting to access any non-existing meta-data attributes will B<not>
result in an error, but simply return undef.

Registration of an attribute is simple. Either you specify its name when
you use the C<OOB> module, at compile time:

 use OOB qw( ContentType );

Just calling it as a class method on the C<OOB> module at runtime is also
enough to allow the attribute:

 use OOB;
 OOB->ContentType; # much later

After that, you can use that attribute on any Perl data structure:

 OOB->ContentType( $string,  'text/html' ); # scalars don't need to be ref'ed
 OOB->ContentType( \$string, 'text/html' ); # same as above
 OOB->ContentType( \@array,  'text/html' );
 OOB->ContentType( \%hash,   'text/html' );
 OOB->ContentType( \&sub,    'text/html' );
 OOB->ContentType( *FILE,    'text/html' ); # globs
 OOB->ContentType( $handle,  'text/html' ); # blessed objects

=head2 Functional Interface

The functional interface gives more flexibility but may not be as easy to
type.  The functional interface binds the given attribut names to the
namespace from which it is being called (but this can be overridden if
necessary).

 use OOB qw( OOB_set OOB_get OOB_reset ); # nothing exported by default

 package Foo;
 OOB_set( $string, ContentType => 'html' );
 my $type = OOB_get( $string, 'ContentType' );        # same namespace ("Foo")

 package Bar;
 my $type = OOB_get( $string, 'ContentType', 'Foo' ); # other namespace
 OOB_set( $string, ContentType => "text/$type" );     # attribute in "Bar"

 OOB_set( $string,  ContentType => 'text/html' ); # scalars don't need refs,
 OOB_set( \$string, ContentType => 'text/html' ); # equivalent to object
 OOB_set( \@array,  ContentType => 'text/html' ); # oriented examples, but
 OOB_set( \%hash,   ContentType => 'text/html' ); # limited to the current
 OOB_set( \&sub,    ContentType => 'text/html' ); # namespace
 OOB_set( \*FILE,   ContentType => 'text/html' );
 OOB_set( \$handle, ContentType => 'text/html' );

=head1 THEORY OF OPERATION

The functional interface of the C<OOB> pragma basically uses the C<refaddr>
of the given value as an internal key to create an "inside-out" hash ref with
the given keys and values.  If the value is not blessed yet, it will be
blessed in the C<OOB> class, so that it can perform cleanup operations once
the value goes out of scope.

If a blessed value is specified, the DESTROY method of the class of the
object is stolen, so that C<OOB> can perform its cleanup after the original
DESTROY method was called.  This is only supported if the L<Sub::Identify>
module is also installed.  If that module cannot be found, a warning will
be issued once to indicate that no cleanup can be performed for blessed
objects, and execution will then continue as normal.

To prevent clashes between different modules use of the out-of-band data,
the package name of the caller is automatically added to any key specified,
thereby giving each package its own namespace in the C<OOB> environment.
However, if need be, a module can access data from another package by the
additional specification of its namespace.

The object oriented interface is really nothing more than synctactic sugar
on top of the functional interface.  The namespace that is being used by all
of the attributes specified with the object oriented interface is the C<OOB>
package itself.

To hide the fact that Perl data structures have suddenly become blessed,
the C<OOB> module cloaks itself from being seen by L<Scalar::Util>'s
C<blessed> function, as well as the core C<ref> function.

=head1 CAVEATS

=head2 Cloaking

The fact that the C<OOB> module is wrapping the core functions C<ref()> and
bless(), may produce unexpected results when the C<OOB> module is loaded
late.  Only code that gets compiled B<after> the C<OOB> module has been
loaded, will properly cloak the fact that C<OOB> has blessed the data structure
being tested with C<ref()>.  A similar issue exists with re-blessing objects
and the wrapping of the core function C<bless>.  It may therefore be advisable
set the PERL5OPT environment variable to include loading of the C<OOB> module
as the very first thing to load.  The can be e.g.  be done by prefixing:

 PERL5OPT=-MOOB

to the call to your script, or to add a:

 use OOB;

to the startup Perl script in a mod_perl environment.

Unfortunately, any XS code accessing the builtin C<ref> and C<bless> core
functions directly, will bypass the cloaking mechanism and therefore report
unblessed data structures as being blessed in the C<OOB> class (or a sub class
of that).

=head1 REQUIRED MODULES

 Scalar::Util (1.14)
 Sub::Identify (0.02)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Juerd Waalboer for the insight that you don't need to keep a reference on
a blessed Perl data structure such as a scalar, array or hash, but instead
can use B<any> reference to that data structure to find out its blessedness.

Dave Rolsky for pointing out I meant "out-of-band" data, rather than
"out-of-bounds".  Oops!

Johan Lodin for pointing out potential problems with ref() and late loading of
the C<OOB> module.

=head1 COPYRIGHT

Copyright (c) 2008 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
