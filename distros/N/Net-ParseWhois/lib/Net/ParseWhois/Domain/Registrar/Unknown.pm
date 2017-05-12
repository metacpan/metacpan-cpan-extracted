package Net::ParseWhois::Domain::Registrar::Unknown;

require 5.004;
use strict;

@Net::ParseWhois::Domain::Registrar::Unknown::ISA = qw(Net::ParseWhois::Domain::Registrar);
$Net::ParseWhois::Domain::Registrar::Unknown::VERSION = 0.1;

sub rdebug { 0 }

# class not really used yet. follow_referral does check now for unknown_registrar..

1;
