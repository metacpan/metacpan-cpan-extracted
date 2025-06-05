# [[[ HEADER ]]]
#use RPerl;
package Perl::Structure::SSENumberPair;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.004_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Structure);
use Perl::Structure;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ SUB-TYPES ]]]

package sse_number_pair;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
use parent qw(Perl::Structure::SSENumberPair);

sub new_from_singleton_duplicate {
    { my sse_number_pair $RETURN_TYPE };
    ( my number $single ) = @ARG;
    my sse_number_pair $retval = Perl::Structure::SSENumberPair::new('sse_number_pair');
    $retval->[0] = $single;
    $retval->[1] = $single;
    return $retval;
}

# NEED TEST
sub new_from_pair {
    { my sse_number_pair $RETURN_TYPE };
    ( my number $pair_0, my number $pair_1 ) = @ARG;
    my sse_number_pair $retval = Perl::Structure::SSENumberPair::new('sse_number_pair');
    $retval->[0] = $pair_0;
    $retval->[1] = $pair_1;
    return $retval;
}

package constant_sse_number_pair;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
use parent qw(Perl::Structure::SSENumberPair);

sub new_from_singleton_duplicate {
    { my constant_sse_number_pair $RETURN_TYPE };
    ( my number $single ) = @ARG;
    my constant_sse_number_pair $retval = Perl::Structure::SSENumberPair::new('constant_sse_number_pair');
    $retval->[0] = $single;
    $retval->[1] = $single;
    return $retval;
}

# NEED TEST
sub new_from_pair {
    { my constant_sse_number_pair $RETURN_TYPE };
    ( my number $pair_0, my number $pair_1 ) = @ARG;
    my constant_sse_number_pair $retval = Perl::Structure::SSENumberPair::new('constant_sse_number_pair');
    $retval->[0] = $pair_0;
    $retval->[1] = $pair_1;
    return $retval;
}

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Structure::SSENumberPair;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes

# [[[ OPERATOR OVERLOADING ]]]

use overload
    '+' => \&sse_add,
    '-' => \&sse_sub,
    '*' => \&sse_mul,
    '/' => \&sse_div;

# [[[ SUBROUTINES & OO METHODS ]]]

sub sse_add {
    ( my $argument_left, my $argument_right, my $arguments_swap ) = @ARG;
    if (not(ref $argument_left) or not($argument_left->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE addition on non-SSE data ' . q{'} . $argument_left . q{'} . ', croaking';
    }
    if (not(ref $argument_right) or not($argument_right->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE addition on non-SSE data ' . q{'} . $argument_right . q{'} . ', croaking';
    }
    my sse_number_pair $retval = sse_number_pair->new();
    $retval->[0] = $argument_left->[0] + $argument_right->[0];
    $retval->[1] = $argument_left->[1] + $argument_right->[1];
    return $retval; 
}

sub sse_sub {
    ( my $argument_left, my $argument_right, my $arguments_swap ) = @ARG;
    if (not(ref $argument_left) or not($argument_left->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE subtraction on non-SSE data ' . q{'} . $argument_left . q{'} . ', croaking';
    }
    if (not(ref $argument_right) or not($argument_right->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE subtraction on non-SSE data ' . q{'} . $argument_right . q{'} . ', croaking';
    }
    my sse_number_pair $retval = sse_number_pair->new();
    if ($arguments_swap) {
        $retval->[0] = $argument_right->[0] - $argument_left->[0];
        $retval->[1] = $argument_right->[1] - $argument_left->[1];
    }
    else {
        $retval->[0] = $argument_left->[0] - $argument_right->[0];
        $retval->[1] = $argument_left->[1] - $argument_right->[1];
    }
    return $retval; 
}

sub sse_mul {
    ( my $argument_left, my $argument_right, my $arguments_swap ) = @ARG;
    if (not(ref $argument_left) or not($argument_left->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE multiplication on non-SSE data ' . q{'} . $argument_left . q{'} . ', croaking';
    }
    if (not(ref $argument_right) or not($argument_right->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE multiplication on non-SSE data ' . q{'} . $argument_right . q{'} . ', croaking';
    }
    my sse_number_pair $retval = sse_number_pair->new();
    $retval->[0] = $argument_left->[0] * $argument_right->[0];
    $retval->[1] = $argument_left->[1] * $argument_right->[1];
    return $retval; 
}

sub sse_div {
    ( my $argument_left, my $argument_right, my $arguments_swap ) = @ARG;
    if (not(ref $argument_left) or not($argument_left->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE division on non-SSE data ' . q{'} . $argument_left . q{'} . ', croaking';
    }
    if (not(ref $argument_right) or not($argument_right->isa('Perl::Structure::SSENumberPair'))) {
        croak 'Attempt to perform SSE division on non-SSE data ' . q{'} . $argument_right . q{'} . ', croaking';
    }
    my sse_number_pair $retval = sse_number_pair->new();

#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_left->[0] = ', $argument_left->[0], "\n";
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_left->[1] = ', $argument_left->[1], "\n";
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_right->[0] = ', $argument_right->[0], "\n";
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_right->[1] = ', $argument_right->[1], "\n";

    if ($arguments_swap) {
        if (($argument_left->[0] + 0) == 0) {
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_left->[0] IS ZERO', "\n";
            $retval->[0] = Perl::Type::Scalar::INFINITY_VALUE();
        }
        else {
            $retval->[0] = $argument_right->[0] / $argument_left->[0];
        }
        if (($argument_left->[1] + 0) == 0) {
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_left->[1] IS ZERO', "\n";
            $retval->[1] = Perl::Type::Scalar::INFINITY_VALUE();
        }
        else {
            $retval->[1] = $argument_right->[1] / $argument_left->[1];
        }
    }
    else {
        if (($argument_right->[0] + 0) == 0) {
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_right->[0] IS ZERO', "\n";
            $retval->[0] = Perl::Type::Scalar::INFINITY_VALUE();
        }
        else {
            $retval->[0] = $argument_left->[0] / $argument_right->[0];
        }
        if (($argument_right->[1] + 0) == 0) {
#print {*STDERR} 'in SSENumberPair::sse_div(), have $argument_right->[1] IS ZERO', "\n";
            $retval->[1] = Perl::Type::Scalar::INFINITY_VALUE();
        }
        else {
            $retval->[1] = $argument_left->[1] / $argument_right->[1];
        }
    }
    return $retval; 
}

# DEV NOTE: using blessed arrayref as object instead of blessed hashref, not valid RPerl
sub new {
    { my Perl::Structure::SSENumberPair $RETURN_TYPE };
    ( my string $class ) = @ARG;
    my Perl::Structure::SSENumberPair $retval = bless [], $class;
    return $retval;
}

1;    # end of class
