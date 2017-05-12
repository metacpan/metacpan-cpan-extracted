package Symbol::Opaque;

our $VERSION = '0.03';

use 5.006001;
use strict;
use warnings;
no warnings 'uninitialized';
use Class::Multimethods::Pure;
use Exporter;
use Scalar::Util qw<readonly>;
use base 'Exporter';

our @EXPORT = qw<defsym free id _()>;

sub _() {
    Symbol::Opaque::Anything->new;
}

sub free($) {
    Symbol::Opaque::Free->new(\$_[0]);
}

sub id($) {
    Symbol::Opaque::Id->new($_[0]);
}

sub makesymdef {
    my ($name) = @_;
    sub {
        my @args;
        for my $i (0..$#_) {
            if (!defined $_[$i] && !readonly $_[$i]) {
                push @args, free $_[$i];
            }
            else {
                push @args, $_[$i];
            }
        }
        Symbol::Opaque::Symbol->new($name, @args);
    };
}

sub defsym {
    my ($name) = @_;
    no strict 'refs';
    my $package = caller;
    *{"$package\::$name"} = makesymdef $name;
}

multi UNIFY => (Any, Any) => sub {
    my ($a, $b) = @_;
    $a eq $b and sub { };
};

multi UNIFY => ('Symbol::Opaque::Free', Any) => sub {
    my ($var, $thing) = @_;
    $var->bind($thing);
};

multi UNIFY => (subtype('Symbol::Opaque::Free', sub { $_[0]->bound }), Any) => sub {
    my ($var, $thing) = @_;
    UNIFY($var->value, $thing);
};

multi UNIFY => ('Symbol::Opaque::Symbol', Any) => sub { 
    0; 
};

multi UNIFY => ('Symbol::Opaque::Symbol', 'Symbol::Opaque::Symbol') => sub {
    my ($sa, $sb) = @_;
    return 0 unless $sa->name eq $sb->name;

    UNIFY([$sa->args], [$sb->args]);
};

multi UNIFY => ('Symbol::Opaque::Anything', Any) => sub {
    sub { };
};

multi UNIFY => ('ARRAY', 'ARRAY') => sub {
    my ($a, $b) = @_;
    return 0 unless @$a == @$b;
    
    my @rollback;
    for my $i (0..$#$a) {
        my $code = UNIFY($a->[$i], $b->[$i]);
        if ($code) {
            push @rollback, $code;
        }
        else {
            $_->() for @rollback;
            return 0;
        }
    }

    return sub { $_->() for @rollback };
};

# Hash-hash unification is a little subtle.
# The right hash has to have every key-value pair as the left hash,
# but the right may have extra keys and that's okay.
multi UNIFY => ('HASH', 'HASH') => sub {
    my ($a, $b) = @_;

    my @keys = keys %$a;
    for (@keys) {
        return 0 unless exists $b->{$_};
    }
    UNIFY([ @$a{@keys} ], [ @$b{@keys} ]);
};

package Symbol::Opaque::Ops;

use Class::Multimethods::Pure multi => 'UNIFY';

use overload
    '<<' => sub { ! !UNIFY($_[0], $_[1]) },
    '>>' => sub { ! !UNIFY($_[1], $_[0]) },
    '""' => sub { overload::StrVal($_[0]) },
;

package Symbol::Opaque::Symbol;

use base 'Symbol::Opaque::Ops';

sub new {
    my ($class, $name, @args) = @_;
    bless {
        name => $name,
        args => \@args,
    } => ref $class || $class;
}

sub name {
    my ($self) = @_;
    $self->{name};
}

sub args {
    my ($self) = @_;
    @{$self->{args}};
}

package Symbol::Opaque::Free;

use base 'Symbol::Opaque::Ops';

sub new {
    my ($class, $ref) = @_;
    undef $$ref;
    bless {
        ref => $ref,
    } => ref $class || $class;
}

sub bind {
    my ($self, $thing) = @_;
    ${$self->{ref}} = $thing;
    sub {
        undef ${$self->{ref}};
    };
}

sub bound {
    my ($self) = @_;
    defined ${$self->{ref}};
}

sub value {
    my ($self) = @_;
    ${$self->{ref}};
}

package Symbol::Opaque::Anything;

use base 'Symbol::Opaque::Ops';

sub new {
    my ($class) = @_;
    bless {} => ref $class || $class;
}

1;

=head1 NAME

Symbol::Opaque - ML-ish data constructor pattern matching

=head1 SYNOPSIS

    use Symbol::Opaque;

    BEGIN { 
        defsym('foo');   # define the constructor "foo"
        defsym('bar');   # define the constructor "bar"
    }

    if ( foo(my $x) << foo(4) ) {    # bind foo(4) into foo($x)
        # $x is now 4
    }
    
    if ( foo(13, bar(my $x)) << foo(13, bar("baz")) ) {
        # $x is now "baz"
    }

    if ( foo(my $x) << bar(42) ) {
        # not executed: foo(X) doesn't match bar(42)
    }

=head1 DESCRIPTION

This module allows the creation of data constructors, which can then be
conditionally unified like in Haskell or ML.  When you use the B<binding>
operator C<<< << >>>, between two structures, this module tries to bind any
I<free variables> on the left in order to make the structures the same. 
For example:

    foo(my $x) << foo(14)           # true, $x becomes 14

This will make $x equal 14, and then the operator will return true.  Sometimes
it is impossible to make them the same, and in that case no variables are
changed and the operator returns false.  For instance:

    foo(my $x, 10) << foo(20, 21)   # impossible: false, $x is undef

This makes it possible to write cascades of tests on a value:

    my $y = foo(20, 21);
    if (foo("hello", my $x) << $y) {
        ...
    }
    elsif (foo(my $x, 21) << $y) {
        # this gets executed: $x is 20
    }
    else {
        die "No match";
    }

(Yes, Perl lets you declare the same variable twice in the same cascade -- just
not in the same condition).

Before you can do this, though, you have to tell Perl that C<foo> is such a
data constructor.  This is done with the exported C<defsym> routine.  It is
advisable that you do this in a C<BEGIN> block, so that the execution path
doesn't have to reach it for it to be defined:

    BEGIN {
        defsym('foo');   # foo() is a data constructor
    }

If two different modules both declare a 'foo' symbol, I<they are considered the
same>.  The reason this isn't dangerous is because the only thing that can ever
differ about two symbols is their name: there is no "implementation" defined.

The unification performed is I<unidirectional>: you can only have free
variables on the left side.

The unification performed is I<nonlinear>: you can mention the same free
variable more than once:

    my $x;   # we must declare first when there is more than one mention
    foo($x, $x) << foo(4, 4);  # true; $x = 4
    foo($x, $x) << foo(4, 5);  # false

Unification of arrays is performed by comparing them elementwise, just like the
arguments of a structure.

Unification of hashes is done like so:  Every key that the target (left) hash
has, the source (right) hash must also, and their values must unify.  However,
the source hash may have keys that the target hash does not, and the two hashes
will still unify.  This is so you can support "property lists", and unify
against structures that have certain properties.

A variable is considered free if it is writable (this is true of all variables
that you'll pass in), undefined, and in the top level of a constructor.  That
is:

    foo([1, my $x]) << foo([1,2])

Will not unify $x, since it is not directly in a data constructor.  To get
around this, you can explicitly mark variables as free with the C<free> 
function:

    foo([1, free my $x]) << foo([1,2])  # success: $x == 2

Sometimes you have a situation where you're unifying against a structure,
and you want something to be in a position, but you don't care what it is.
The C<_> marker is used in this case:

    foo([1, _]) << foo([1, 2])   # success: no bindings
    
=head1 SEE ALSO

L<Logic>

=head1 AUTHOR

Luke Palmer <lrpalmer at gmail dot com>
