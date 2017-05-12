package Perl6::Classes;

use Filter::Simple;
use Text::Balanced qw{extract_quotelike extract_codeblock 
                      extract_variable  extract_multiple};

our $VERSION = "0.22";

# This whole file is a pile of ascii feces.

my $identifier = qr/(?: :: )? 
                    [a-zA-Z_] \w*
                    (?: :: [a-zA-Z_] \w*)*/x;

my $signature  = qr/(?:
                        \s* [\\;\&\%\@\$]
                      )* \s*/x;

my $traits = qr/is \s+ [a-zA-Z_]\w*
                 (?: \s+ is \s+ [a-zA-Z_]\w* )*/x;

my $scope_trait = qr/^ (?: public|protected|private ) $/x;


{   my $symno = '000000';
    sub newclass {
        "__class_" . $symno++
    }
}

sub proccode {
    my ($str, $cls) = @_;

    my $pos = pos;      # Ugh, why doesn't pos localize with $_ ?!
    $str = filter($str);
    pos = $pos;

    $str =~ s/^\s*\{/{my \$self = local \$_ = shift; /;
    $str =~ s/([\$\@\%])\.([a-zA-Z_]\w*)/$1\{\$self->{_data_$cls}{_attr_$2}}/g;
    $str
}

sub parse {
    local $_ = shift;
    my $cls = shift;

    my @components;
    my $ws;

    die unless m/\G \s*\{/gx;

    CHUNK:
    while (length > pos) {
            if (/\G (\s+)/cgx) { $ws .= $1; }
            elsif (/\G (\# [^\n]* \n)/cgx) { $ws .= $1; }
            elsif (/\G has \s* ([\$\@\%])\.([a-zA-Z_]\w*) \s* \;/cgx) {
                push @components, {
                    ws   => $ws,
                    type => 'attr',
                    name => $2,
                    sigil => $1
                };
                undef $ws;
            }
            elsif (/\G sub    \s+ ($identifier)
                             \s*? ( \( ( $signature ) \) )? (\s+ $traits)?/cgx) {
                my @traits = grep { /\S/ && $_ ne 'is' } split /\s+/, $4;
                my ($scope) = grep { /$scope_trait/ } @traits;
                my $code = (extract_codeblock)[0];
                push @components, {
                    ws   => $ws,
                    type => 'sub',
                    name => $1,
                    sig  => ($2 ? "(\$$3)" : "(\$@)"),
                    code => proccode($code, $cls),
                    scope => ($scope || 'public'),
                };
                undef $ws;
            }
            elsif (/\G method \s+ ($identifier)
                             \s*? ( \( ( $signature ) \) )? (\s+ $traits)?/cgx) {
                my @traits = grep { /\S/ && $_ ne 'is' } split /\s+/, $4;
                my ($scope) = grep { /$scope_trait/ } @traits;
                my ($name, $sig, $insig) = ($1, $2, $3);
                my $code = (extract_codeblock)[0];
                push @components, {
                    ws   => $ws,
                    type => 'method',
                    name => $name,
                    sig  => ($sig ? "(\$$insig)" : "(\$@)"),
                    code => proccode($code, $cls),
                    scope => ($scope || 'public'),
                };
                undef $ws;
            }
            elsif (/\G submethod \s+ ($identifier)
                                 \s*? ( \( ( $signature ) \) )? (\s+ $traits)?/cgx) {
                my @traits = grep { /\S/ && $_ ne 'is' } split /\s+/, $4;
                my ($scope) = grep { /$scope_trait/ } @traits;
                my $code = (extract_codeblock)[0];

                push @components, {
                    ws   => $ws,
                    type => 'submethod',
                    name => $1,
                    sig  => ($2 ? "(\$$3)" : "(\$@)"),
                    code => proccode($code, $cls),
                    scope => ($scope || 'private'),
                };
                undef $ws;
            }
            elsif (/\G \}/cgx) {
                push @components, {
                    ws => $ws,
                    type => 'empty',
                };
                last CHUNK;
            }
            else {
                die "Bad token (near '" . 
                    substr($_, pos, 15) . "')";
            }
    }
   
   \@components;
}

sub generate_class {
    my ($name, $data, $base) = @_;

    my %scopecode = (
        private   => sub { qq{require Carp; Carp::croak("Private $_[1] $name\::$_[0]") unless }.
                           qq{caller =~ /^$name(?:__|\$)/; } },
        protected => sub { qq{require Carp; Carp::croak("Protected $_[1] $name\::$_[0]") unless } .
                           qq{caller->isa('$name') || $name->isa(scalar caller); } },
        public    => sub { "" },
    );

    my ($newstruct, $destroystruct, $emptystruct);
    $emptystruct = pop @$data if $data->[-1]->{type} eq 'empty';

    for (@$data) {
        if ($_->{name} eq 'new') {
            $newstruct = $_;
        }
        elsif ($_->{name} eq 'DESTROY') {
            $destroystruct = $_;
        }
    }

    unless ($newstruct) {
        $newstruct = {
            type => 'sub',
            name => 'new',
            sig  => '',
            scope => 'public',
        };
        push @$data, $newstruct;
    }

    unless ($destroystruct) {
        $destroystruct ||= {
            type => 'submethod',
            name => 'DESTROY',
            sig  => '',
            scope => 'public',
        };
        push @$data, $destroystruct;
    }

# Checks

    {   my %seen;
        for (@$data) {
            if ($_->{type} ne 'attr' && $_->{type}) {
                if (exists $seen{$_->{name}}) {
                    die "Duplicate name $_";
                }
                $seen{$_}++;
            }
        }
    }

# New routine

    {
    my $newcode = " { ";

    for (@$data) { # update the closures (???)
        if ($_->{type} eq 'sub') {
            $newcode .= "\$_sub_$_->{name}; ";
        }
    }

    $newcode .= 'my $_class = shift; my $_self = bless {';

    for (@$base) {
        $newcode .= "do { my \$_cl = $_->new; (_parent_$_ => \$_cl, \%\$_cl) }, ";
    }

    $newcode .= "_data_$name => {";
    
    for (@$data) {
        if ($_->{type} eq 'attr') {
            $newcode .= "_attr_$_->{name} => undef, ";
        }
    }

    $newcode .= "}, ";
    
    for (@$data) {
        if ($_->{type} eq 'method' || $_->{type} eq 'submethod') {
            $newcode .= "_$_->{type}_$_->{name} => \$_$_->{type}_$_->{name}, ";
        }
    }
    for (@$data) {
        if ($_->{type} eq 'sub') {
            $newcode .= "_sub_$_->{name} => sub { my \$self = shift; " .
                "\$_sub_$_->{name}->(\${\$self->{_class}}, \@_) }, ";
        }
    }
    
    $newcode .= "_class => \\\$_ret, } => '${name}__object'; " .
                "\$_self->BUILD(\@_) if \$_self->can('BUILD'); \$_self }; ";

    $newstruct->{code} = $newcode;
    }  # End of new routine

    # DESTROY routine
    {
        my $descode = "{ \$_[0]->DESTRUCT if \$_[0]->can('DESTRUCT'); ";
        for (reverse @$base) {
            $descode .= "\$_[0]->$_\::DESTROY;";
        }
        $descode .= " }";
        $destroystruct->{code} = $descode;
    }  # End of DESTROY routine

    my $ret = "{ package $name; my \$_ret; ";
    for (@$data) {
        if ($_->{type} ne 'attr') {
            $ret .= "my \$_$_->{type}_$_->{name}; "
        }
    }
    for (@$data) {
        if ($_->{type} eq 'attr') {
            $ret .= "$_->{ws}";
        }
        else {
            $ret .= "$_->{ws} \$_$_->{type}_$_->{name} = sub $_->{sig} $_->{code}; ";
        }
    }

    $ret .= '$_ret = bless { ';

    for (@$data) {
        if ($_->{type} eq 'sub') {
            $ret .= "_sub_$_->{name} => \$_sub_$_->{name}, ";
        }
    }
    $ret .= "} => '${name}__class'; ";

# Class methods
    $ret .= "{ package ${name}__class; ";

    for (@$data) {
        if ($_->{type} eq 'sub') {
            $ret .= "sub $_->{name} $_->{sig} { " . $scopecode{$_->{scope}}->($_->{name}, $_->{type}) . 
                    "goto &{ref \$_[0] ? \$_[0]{_sub_$_->{name}} : \$_sub_$_->{name}} } ";
        }
    }

# Inheritable methods

    $ret .= "package ${name}; ";
    $ret .= "use base '${name}__class'; ";

    for (@$base) {
        $ret .= "use base '$_'; ";
    }
    
    for (@$data) {
        if ($_->{type} eq 'method') {
            $ret .= "sub $_->{name} $_->{sig} { " . $scopecode{$_->{scope}}->($_->{name}, $_->{type}) .
                    "goto &{\$_[0]{_method_$_->{name}}} }";
        }
    }
    
# Object methods
    
    $ret .= "package ${name}__object; ";
    $ret .= "use base '$name'; ";

    for (@$data) {
        if ($_->{type} eq 'submethod') {
            $ret .= "sub $_->{name} $_->{sig} { " . $scopecode{$_->{scope}}->($_->{name}, $_->{type}) .
                    "goto &{\$_[0]{_submethod_$_->{name}}} }";
        }
    }

    $ret .= "} \$_ret; } $emptystruct->{ws}";

    $ret;
}

sub extract_class {
    local $_ = shift if @_;
        
    my $ret;
    if (/\G class (\s+ $identifier)? (\s+ $traits)? (?= \s* \{ )/cgx) {
        my @inherit = grep { /\S/ && $_ ne 'is' } split /\s+/, $2;
        
        my $anon;
        my $name = $1;
        unless ($name) {
            $name = newclass;
            $anon = 1;
        }
        $name =~ s/^\s*//;
        my $code = (extract_codeblock)[0];
        my $ppos = pos;
        my $data = parse($code, $name);
        pos = $ppos;
        
        $ret = generate_class($name, $data, \@inherit);
        if ($anon) {
            $ret = "do $ret";
        }
        else {
            $ret = "$ret;";
        }
    }
    $ret;
}

sub filter {
    local $_ = shift if @_;
    my @parts = extract_multiple(undef, [
                            qr/\s+/,
                            sub { scalar extract_class },
                            qr/#[^\n]*/,
                            sub { scalar extract_quotelike },
                            sub { scalar extract_variable },
                            qr/.[^\&\%\@\$"'q#c]*/,
                            ]);
    join '', @parts;
}

FILTER {
    $_ = filter;
}

__END__

=head1 NAME

    Perl6::Classes - First class classes in Perl 5

=head1 SYNOPSIS

    use Perl6::Classes;
    
    class Composer {
        submethod BUILD { print "Giving birth to a new composer\n" }
        method compose { print "Writing some music...\n" }
    }
    
    class ClassicalComposer is Composer {
        method compose { print "Writing some muzak...\n" }
    }
    
    class ModernComposer is Composer {
        submethod BUILD($) { $.length = shift }
        method compose() { print((map { int rand 10 } 1..$.length), "\n") }
        has $.length;
    }
    
    my $beethoven = new ClassicalComposer;
    my $barber    = new ModernComposer 4;
    my $mahler    = ModernComposer->new(400);

    $beethoven->compose;   # Writing some muzak...
    $barber->compose       # 7214
    compose $mahler;       # 89275869347968374698756....

=head1 DESCRIPTION

C<Perl6::Classes> allows the creation of (somewhat) Perl 6-style classes
in Perl 5.  The following features are currently supported:

=over 4

=item * C<sub>s, C<method>s, and C<submethod>s

And their respective scoping rules.

=item * Attributes

Which are available through the C<has> keyword, and look like C<$.this>.

=item * Inheritance

Both single and multiple inheritance are available through the C<is> keyword.

=item * Signatures

Signatures on C<method>s, C<sub>s, and C<submethod>s are supported, but
just the Perl 5 kind. 

=item * Data hiding

Using the C<public>, C<protected>, and C<private> traits, you can enforce
(run-time) data hiding.  This is not supported on attributes, which are
always C<private>.

=item * Anonymous classes

That respect closures.  You can now nest them inside methods of other classes, 
even other anonymous ones!

=back

The C<Perl6::Classes> module augments Perl's syntax with a new declarator:
C<class>.  It offers the advantage over Perl's standard OO mechanism that
it is conceptually easier to see (especially for those from a C++/Java 
background).  It offers the disadvantage, of course, of being less versatile.

=head2 Declarations

Inside a C<class>, the following things can be declared:

=over 4

=item C<method>

A method is a routine on an object of the class that can be inherited by
derived classes.  Declare it just like a C<sub>, with the word C<method>
in place of C<sub>.  Both C<$_> and C<$self> are set to the invocant,
and the arguments (without the invocant) are passed in C<@_>.  By default,
C<method>s are public.

=item C<sub>

A good ol' familiar sub is a method that takes the class itself as an
invocant.  It may not use attributes, but you can call it from an object
and it acts polymorphically.  In any case, C<$_> and C<$self> are set
to the class name for a named class, and the class object for one of
the anonymous variety.  By default, C<sub>s are public.

=item C<submethod>

A submethod is just like a C<method>, except that it does not participate
in inheritance.   Most often, routines that create, initialize, or destroy
the current object fall into this category (Wall).  They are declared and
behave just like C<method>s, otherwise.  Except they default to private.

=item C<has>

C<has> declares an attribute, which is some private instance data.  They
generally look like C<$.this>, but can look like C<@.that> or C<%.uhm>,
too.  They behave like scalars, arrays, and hashes (respectively), too,
except that there's just a dot in front of their name.  So, you can
dereference C<%.uhm> with C<$.uhm{right}>.  They are always private, and
can't be declared otherwise.

=back

=head2 Inheritance

You may inherit as many classes as you like by following the name of the
declared class (or the absence of one, in the case of anonymous classes)
with repeated "is ClassName"s.  For instance:

    class Pegasus is Human is Horse { ... }

A derived class (C<Pegasus> in this case) inherits all C<sub>s and C<method>s
(but not C<submethod>s) of its base classes (C<Human> and C<Horse>).  All
of these behave "more polymorphically" than regular Perl 5 inheritance with
C<use base> and C<@ISA>.  For instance:

    class Base { method go { ... } }
    class Derived is Base { method go { ... } }
    
    my $b = new Base;
    my $d = new Derived;
    $b->go;          # Base::go
    $d->go;          # Derived::go
    my $method = \&Base::go;
    $b->$method;     # Base::go
    $d->$method      # Derived::go

Whether this is a bug or a feature is left to the opinion of the reader.

No, you can't derive from an anonymous class.  No, not even if it's in
a variable.  Don't mistake that for not being able to derive anonymous
classes from named ones, though.  You're allowed to do that.

=head2 Constructors and Destructors

There are two layers of constructors and destructors.  There's the Perl
constructor, often called C<new>, which actually constructs the
object.  Then there's the initializer, which C++ and Java call the 
constructor, under the name C<BUILD>.  C<Perl6::Classes> takes care of
the constructor for you, and allows you to specify the initializer, 
usually as a C<submethod>.

The naming is a bit less intuitive as far as destructors.  Perl herself
doesn't let you specify a real destructor, just a de-initialzer which is
called just before the memory is reclaimed.  This is under the name
C<DESTROY>.  But C<Perl6::Classes> handles that for you and allows you
to specify C<DESTRUCT>, which essentially does the same thing, except
when you're inheriting.

C<Perl6::Classes> doesn't pay attention to (de-)initializer return values,
so if an error occurs, you should throw an exception.  Perl will ignore
the exception if it's in the destructor.

=head3 Constructors and Destructors and Inheritance

When you're inheriting base classes, each base class's constructor is
called before the derived one, in the order specified on the declaration
line.  This happens even if the derived class explicitly specifies an
initializer.  Similarly, each base class's destructor is called I<after>
the derived one, in the reverse order.

=head2 Data Hiding

C<Perl6::Classes> offers standard run-time data protection, for whatever
it's worth.  It is specified on methods (and subs and submethods) by using
traits.  Particularly, C<is public>, C<is protected>, and C<is private>.
Traits are specified right after the signature (or the absence thereof)
of a declaration.  For instance:

    class Thingy {
        method describe { print $_->description, "\n"; }
        method baseclass is protected { "Thingy" }
        method description is private { "This " . $->baseclass . " is neat" }
    }

This class allows you to override anything, but is probably hoping you'll
override C<description>.  However, clients of C<Thingy> can only access
C<describe>.  Classes derived from C<Thingy> may access C<describe> and
C<baseclass>, and only the C<describe> method (and other potential C<Thingy>
methods) can access C<description>.  

=head3 Data Hiding and Constructors

It is sometimes useful to make a private or protected constructor, saying that
"only my children or I are allowed to make me".  But, making C<BUILD> private
doesn't work, becuase C<BUILD> is called through the implicit C<sub new>.  What
you really need to do is make C<new> private.  This is how:

    class Handle {
       sub new is private { ... }
       sub makeHandle { new Handle }
    }

Now, C<new Handle> from outside the class will cause an error, but C<makeHandle>
works fine.  You may put yada-yada-yada (...) inside that as in the example,
as the codeblock specified is never compiled.  The declaration there is just
to specify scope.

Note that a class with a private constructor may not effectively be derived from,
as it will croak when the derived class tries to construct it.  However, it is
possible to specify an abstract class by making the constructor C<protected>.

=head2 Traps for the unwary

As just mentioned, C<new>'s body is never compiled.  You could catch yourself
off guard by specifying a body, and seeing it never run.  Future versions
may check that the body of new is either unspecified or exactly "...".

Do not attempt to explicitly bless into a C<Perl6::Classes> class.  Always use
the C<new> function.  Sure, a real package is created, but the subs in it don't
behave how you'd think they would.

=head1 BUGS

There are undoubtedly bugs that I don't mention here.  I mean, it's a source
filter.

=over 4

=item *

Code like this:

    class Foo is Bar { 
        method go { $_->Bar::go }
    }

Doesn't work the way you want it to.  Instead, it calls Foo::go.

=item *

At the moment, line numbers in your source get all messed up by using
a C<class>.

=back

=head1 SEE ALSO

L<perlobj>, L<Class::Struct>, L<Class::*>

=head1 AUTHOR

Both the C<Perl6::Classes> module and this documentation were written
by Luke Palmer (C<fibonaci@babylonia.flatirons.org>).

This module is licenced under the same terms as Perl itself.  Copyright
(C) 2003, Luke Palmer.
