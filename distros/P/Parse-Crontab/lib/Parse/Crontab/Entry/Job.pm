package Parse::Crontab::Entry::Job;
use strict;
use warnings;
use Try::Tiny;

use Mouse;
extends 'Parse::Crontab::Entry';
use Parse::Crontab::Schedule;

has command => (
    is  => 'rw',
    isa => 'Str',
);

has schedule => (
    is  => 'rw',
    isa => 'Parse::Crontab::Schedule',
    handles => [qw/minute hour day month day_of_week definition user/],
);

has has_user_field => (
    is  => 'ro',
    isa => 'Bool',
    default => undef,
);

no Mouse;

sub BUILD {
    my $self = shift;

    my $line = $self->line;
    my $definition;
    my $command;
    my $user;

    my %args;
    if (($definition) = $line =~ /^@([^\s]+)/) {

        if ($self->has_user_field) {
            ($user, $command) = (split /\s+/, $line, 3)[1,2];
        }
        else {
            $command = (split /\s+/, $line, 2)[1];
        }

        %args = (
            definition => $definition,
            user       => $user,
        );
    }
    else {
        my $entity_num = $self->has_user_field ? 7 : 6;
        my @entities = split /\s+/, $line, $entity_num;
        my ($min, $hour, $day, $month, $dow, $com);

        if ($self->has_user_field) {
            ($min, $hour, $day, $month, $dow, $user, $com) = @entities;
        }
        else {
            ($min, $hour, $day, $month, $dow, $com) = @entities;
        }
        unless ($com) {
            $self->set_error(sprintf '[%s] is not valid cron job', $self->line);
            return;
        }
        $command = $com;
        %args = (
            minute      => $min,
            hour        => $hour,
            day         => $day,
            month       => $month,
            day_of_week => $dow,
            user        => $user,
        );
    }

    unless ($command) {
        $self->set_error(sprintf '[%s] is not valid cron job', $self->line);
        return;
    }
    $self->command($command);

    try {
        $self->schedule(Parse::Crontab::Schedule->new(%args));

        my @warnings = $self->schedule->_check_warnings;
        $self->set_warning($_) for @warnings;
    }
    catch {
        $self->set_error(sprintf 'schedule error! %s', $_);
    };

}

__PACKAGE__->meta->make_immutable;
