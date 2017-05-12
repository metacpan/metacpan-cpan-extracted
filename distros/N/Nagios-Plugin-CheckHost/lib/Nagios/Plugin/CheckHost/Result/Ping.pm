package Nagios::Plugin::CheckHost::Result::Ping;

use strict;
use warnings;

use base "Nagios::Plugin::CheckHost::Result";

sub calc_rtt {
    my ($self, $node) = @_;

    my $result = $self->{results}->{$node};
    return unless $result;
    $result = $result->[0];
    return unless $result and $result->[0];

    my $avg = 0;
    my $total = 0;
    foreach my $check (@$result) {
        if ($check->[0] eq "OK") {
            $avg += $check->[1];
            $total += 1;
        }
    }
    return unless $total;
    $avg/$total;
}

sub calc_loss {
    my ($self, $node) = @_;

    my $result = $self->{results}->{$node};
    return 1 unless $result;
    $result = $result->[0];
    return 1 unless $result and $result->[0];

    my ($success, $fail) = (0, 0);
    foreach my $check (@$result) {
        if (uc $check->[0] eq "OK") {
            $success++;
        } else {
            $fail++;
        }
    }
    
    $fail/($fail+$success);
}

1;
