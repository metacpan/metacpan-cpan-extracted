package Nagios::Plugin::Threshold::Group;

use strict;
use warnings;

use Carp qw(croak);
use Monitoring::Plugin::Functions qw(OK WARNING CRITICAL);

sub new {
    my ($class, %args) = @_;

    my $single_threshold = delete $args{single_threshold} or croak 'single_threshold missed';
    my $group_threshold  = delete $args{group_threshold} or croak 'group_threshold missed';

    bless {
        single_threshold => $single_threshold,
        group_threshold  => $group_threshold,
    }, $class;
}

sub get_value_status {
    my ($self, $value) = @_;

    $self->{single_threshold}->get_status($value);
}

sub get_status {
    my ($self, $values) = @_;

    $values = [$values] if ref $values eq '';

    my $st = $self->{single_threshold};
    my $gt = $self->{group_threshold};

    my $s = {
        Monitoring::Plugin::Functions::OK       => 0,
        Monitoring::Plugin::Functions::WARNING  => 0,
        Monitoring::Plugin::Functions::CRITICAL => 0,
    };

    foreach my $value (@$values) {
        $s->{$st->get_status($value)}++;
    }

    my $criticals = $s->{Monitoring::Plugin::Functions::CRITICAL};
    my $status = $gt->get_status($criticals);
    return $status if $status != OK;

    if ($gt->warning->is_set) {
        my $warnings = $s->{Monitoring::Plugin::Functions::WARNING};
        return WARNING if $gt->warning->check_range($warnings + $criticals);
    }

    OK
}

1;
