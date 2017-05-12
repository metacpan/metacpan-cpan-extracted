package TAP::Tree::Iterator;

use strict;
use warnings;
use v5.10.1;
use utf8;

use Carp;

sub new {
    my $class  = shift;
    my %params = @_;

    my ( $pkg, undef, undef ) = caller;
    if ( $pkg ne 'TAP::Tree' ) {
        croak "Invalid call! This module must be called from inside TAP::Tree.";
    }

    my $self = {
        tap_tree    => $params{tap_tree},
        subtest     => $params{subtest},

        index_recursive => [],
        index_testline  => 0,
    };

    bless $self, $class;

    return $self;
}

sub next {
    my $self = shift;

    my $next = ( $self->{subtest} ) ? $self->_next_subtest : $self->_next;

    return $next;
}

sub _next_subtest {
    my $self = shift;

    return if ( ! defined $self->{index_testline} );

    # get current test
    my $test = {
        plan        => $self->{tap_tree}{plan},
        testline    => $self->{tap_tree}{testline},
    };

    for my $index ( @{ $self->{index_recursive} } ) {
        my $current = $test->{testline}[$index]{subtest};

        $test = $current;
    }

    # get current testline
    my $testline = ( defined $test->{testline}[$self->{index_testline}] ) ?
        $test->{testline}[$self->{index_testline}] : undef;

    my $next = {
        test        => $test,
        testline    => $testline,
        indent      => scalar @{ $self->{index_recursive} },
    };

    # set next index
    if ( $testline && $testline->{subtest} ) {
        push @{ $self->{index_recursive} }, $self->{index_testline};
        $self->{index_testline} = 0;

        return $next;
    }

    if ( defined $test->{testline}[$self->{index_testline} + 1 ] ) {
        $self->{index_testline} += 1; 
        return $next;
    }

    my $found;
    while ( @{ $self->{index_recursive} } ) {
        my $index_next = pop @{ $self->{index_recursive} };

        my $nexttest = {
            testline    => $self->{tap_tree}{testline},
        };

        for my $i ( @{ $self->{index_recursive} } ) {
            my $current = $nexttest->{testline}[$i]{subtest};

            $nexttest = $current;
        }

        if ( defined $nexttest->{testline}[$index_next + 1] ) {
            $found = $index_next + 1;
            last;
        }
    }

    if ( $found ) {
        $self->{index_testline} = $found;
    } else {
        $self->{index_testline} = undef;
    }

    return $next;
}

sub _next {
    my $self = shift;

    my $test = {
        plan        => $self->{tap_tree}{plan},
        testline    => $self->{tap_tree}{testline},
    };
        
    if ( defined $self->{tap_tree}{testline}[$self->{index_testline}] ) {
        my $testline = $self->{tap_tree}{testline}[$self->{index_testline}];

        $self->{index_testline}++;
        
        return { test => $test, testline => $testline, indent => 0 };
    } else {
        return;
    }
}

1;

__END__

=pod

=head1 NAME

TAP::Tree::Iterator - The iterator of the TAP::Tree

=head1 DESCRIPTION

See L<TAP::Tree>.

=cut
