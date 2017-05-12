package TAP::Formatter::Diffable;
use strict;
use warnings;
use base 'TAP::Base', 'TAP::Formatter::File';
use accessors qw(sessions);

=head1 NAME

TAP::Formatter::Diffable - Diff friendly (ie sorted) TAP output.

=head1 SYNOPSIS

  prove -j5 --formatter=TAP::Formatter::Diffable t

=head1 DESCRIPTION

Delays TAP output until the entire test suite has completed.

Sorts test output by test filename.  This way tests alway display in the same order, even when processing in parallel.

Skips over passing tests, unless they are marked as TODO.  These are skipped to make the diff easier to matchup when test numbers change slightly.

Sorts the final "Test Results"



=over

=item Example Pass

 All tests successful.
 Files=1, Tests=1,
 Result: PASS

=item Example Fail

 Failed test 'Example failred test'
 #   at t/00-load.t line 6.
 # Looks like you planned 1 test but ran 2.
 # Looks like you failed 1 test of 2 run.
 [t/00-load.t]
 not ok 2 - Example failred test


 Test Summary Report
 -------------------
 t/00-load.t (Wstat: 256 Tests: 2 Failed: 1)
   Failed test:  2
   Non-zero exit status: 1
   Parse errors: Bad plan.  You planned 1 tests but ran 2.
 Files=1, Tests=2,
 Result: FAIL

=back

=cut

use vars qw($VERSION);
$VERSION = '0.15';

sub _initialize {
    my ($self, $hash) = @_;
    $self->sessions( [] );
    $self->$_( $hash->{$_} ) for keys %$hash;
    return $self;
}

sub _output {
    my $self = shift;
    print @_;
}

sub open_test {
    my ($self, $test, $parser) = @_;
    my $session = TAP::Formatter::Diffable::Session->new({
        test => $test,
        parser => $parser,
        formatter => $self,
    });
    push @{ $self->sessions }, $session;
    return $session;
}

sub summary {
    my $self = shift;

    my %sessions;
    $sessions{ $_->test } = $_ for @{ $self->sessions };

    # Sorting by test, that's what this module is all about.
    # Sorted output is diffable.
    for (sort keys %sessions) {
        $sessions{ $_ }->is_interesting or next;
        $self->_output( $sessions{ $_ }->as_report );
        $self->_output( "\n" );
    }

    # Elapsed time makes the output undiffable.
    no warnings 'redefine';
    local *TAP::Parser::Aggregator::timestr = sub { "" };

    # Make sure the "Test Summary Report" is sorted
    my @tmp = sort @{$_[0]->{'parse_order'}};
    $_[0]->{'parse_order'} = \@tmp;

    $self->SUPER::summary(@_);
}


package TAP::Formatter::Diffable::Session;
use base 'TAP::Base';
use accessors qw( test formatter parser results );

sub _initialize {
    my ($self, $hash) = @_;
    $self->results( [] );
    $self->$_( $hash->{$_} ) for keys %$hash;
    return $self;
}

sub result {
    my ($self, $result) = @_;

    return unless $result->is_test;
    return if $result->is_actual_ok and not $result->has_todo;
    return if $result->has_todo and not $result->is_actual_ok;

    push @{ $self->results }, $result->as_string;
}

sub close_test {
}

sub is_interesting {
    my ($self) = @_;
    return ! ! @{ $self->results };
};

sub as_report {
    my ($self) = @_;
    return join "", map "$_\n", "[" . $self->test . "]", @{ $self->results };
}

1;
