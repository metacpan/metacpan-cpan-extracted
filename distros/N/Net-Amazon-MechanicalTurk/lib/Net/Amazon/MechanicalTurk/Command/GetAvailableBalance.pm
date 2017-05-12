package Net::Amazon::MechanicalTurk::Command::GetAvailableBalance;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::GetAvailableBalance - Get your accounts available balance.

A convenience method for getting your accounts available balance.

=head1 SYNOPSIS

    printf "Available Balance %s\n", $mturk->getAvailableBalance;

=cut 


sub getAvailableBalance {
    my $mturk = shift;
    return $mturk->GetAccountBalance->{AvailableBalance}[0]{Amount}[0];
}

return 1;
