package Nagios::NSCA::Client::Base;
use strict;
use warnings;
use base 'Nagios::NSCA::Base';

our $VERSION = sprintf("%d", q$Id: Base.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

sub settings {
    my ($self, %args) = @_;
    no warnings;  # Crush redefined warnings.
    require Nagios::NSCA::Client::Settings;
    return Nagios::NSCA::Client::Settings->new(%args);
}

1;
