package Net::Hadoop::Oozie::TheJudge;
$Net::Hadoop::Oozie::TheJudge::VERSION = '0.110';
use 5.010;
use strict;
use warnings;

use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };
use Moo;
use Net::Hadoop::Oozie;

has 'oozie' => (
    is      => 'rw',
    default => sub {
        Net::Hadoop::Oozie->new
    },
    lazy    => 1,
);

has 'badge' => (
    is      => 'rw',
    default => sub { 'x' },
    lazy    => 1,
);

has name => (
    is => 'rw',
    default => sub { 'TheJudge' },
);

sub question {
    my $self = shift;
    my $opt  = @_ > 1 ? {@_} : $_[0];
    my $name = $self->name;

    my $oozie = $self->oozie;

    die 'Not an options hashref' if ref $opt ne 'HASH';

    # retrieve the last $len actions for a coordinator for analysis; this should be
    # large enough allow the front of the queue to be discarded if there are many
    # actions in READY state
    ( my $len = $opt->{len} ) ||= 1000;

    # if we have no success in the last threshold(s) that actually ran, throw
    # an alert
    ( my $soft_limit = $opt->{suspend} ) ||= 10;
    ( my $hard_limit = $opt->{kill} )    ||= 20;

    if ( $len < $soft_limit || $len < $hard_limit ) {
        die "'len' should be higher than 'soft' and 'hard'; there's no point otherwise";
    }

    if ( $soft_limit > $hard_limit ) {
        die "'soft' should be lower than 'hard'; there's no point otherwise"
    }

    my $job_id = $opt->{coord} || die "No coordinator ID!";

    my($job, $job_error);
    eval {
        $job = $oozie->job_exists(
                    $job_id,
                    {
                        len   => $len,
                        order => 'desc',
                    },
                );
        1;
    } or do {
        $job_error = $@ || 'Zombie error';
    };

    if ( ! $job ) {
        warn sprintf 'Could not retrieve details for coord id %s. %s',
                        $job_id,
                        $job_error ? "Error: $job_error" : 'Job does not exist.',
                    ;
        return;
    }

    if ( $job->{status} eq 'KILLED' ) {
        return { verdict => 'R.I.P. citizen' };
    }

    my $actions = $job->{actions} || return { verdict => "free" };

    # take the actions in order; discard all the READY/PREP ones at the front of
    # the queue, then check the rest
    while ( my $ax = shift @$actions ) {
        if ( $ax->{status} !~ /(READY|WAITING|PREP|RUNNING)/ ) {
            unshift @$actions, $ax;
            last;
        }
    }

    # keep $hard_limit elements, bail out if the first $soft_limit ones are not all
    # KILLED
    splice @$actions, $hard_limit;

    my $total_killed  = grep { $_->{status} && $_->{status} eq 'KILLED' }
                            @{ $actions }[ 0 .. $soft_limit - 1 ]
                        ;
    if ( $total_killed < $soft_limit ) {
        DEBUG && printf STDERR "[%s] KILLED: %s < %s\t- [%s] %s (%s)\n",
                        $name,
                        $total_killed,
                        $soft_limit,
                        $self->badge,
                        $job_id,
                        $job->{coordJobName},
        ;
        return {};
    }

    my $stats;

    for (@$actions) {
        $stats->{ $_->{status} }++;
        $stats->{total}++;
    }

    my $sentence = $stats->{KILLED} == $hard_limit ? 'KILLED' : 'SUSPENDED';
    my $out = sprintf "[%s] Coordinator %s (%s) should be %s\n",
                            $self->badge,
                            $job_id,
                            $job->{coordJobName},
                            $sentence,
                    ;

    $out .= sprintf "Latest %s actions are:\n", $stats->{total};

    for (qw(SUCCEEDED KILLED)) {
        $out .= sprintf "  %-10s: %.2f%%\n",
                            $_,
                            ( $stats->{$_} || 0 ) / $stats->{total} * 100,
                ;
    }

    for (@$actions) {
        $out .= sprintf "action %s (%s) %s\n",
                            @{$_}{qw/ actionNumber lastModifiedTime status/ },
                ;
    }

    $out .= sprintf qq{\n\nOozie console:\n\n%s/?job=%s\n},
                        $oozie->oozie_uri,
                        $job_id,
            ;

    return {
        guilty   => 1,
        sentence => lc $sentence,
        text     => $out,
    };

    # we could check the % KILLED and % SUCCEEDED over a longer period,
    # optionally with a weight like (0.9 ^ days(time - lastModifiedEpoch))
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::Oozie::TheJudge

=head1 VERSION

version 0.110

=head1 SYNOPSIS

    use Net::Hadoop::TheJudge;
    # TODO

=head1 SYNOPSIS

    my $verdict = Net::Hadoop::Oozie::TheJudge->new->question(
        len     => 1000,
        kill    => 20,
        suspend => 10,
        coord   => shift(),
    );

    print $verdict->{text} if $verdict->{guilty};

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 NAME

Net::Hadoop::Oozie::TheJudge - Will tell you the verdict on coordinators

=head1 ATTRIBUTES

=head2 oozie

The L<Net::Hadoop::Oozie> instance used to fetch information.

=head2 badge

The name of the cluster.

=head2 name

The name of the program.

=head1 METHODS

=head2 question

TODO.

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
