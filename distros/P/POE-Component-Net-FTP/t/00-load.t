#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('Net::FTP');
    use_ok('POE::Component::NonBlockingWrapper::Base');
	use_ok( 'POE::Component::Net::FTP' );
}

diag( "Testing POE::Component::Net::FTP $POE::Component::Net::FTP::VERSION, Perl $], $^X" );
my $o = POE::Component::Net::FTP->spawn(debug=>1);

isa_ok($o, 'POE::Component::Net::FTP');
can_ok($o, qw(spawn process session_id shutdown));
$o->shutdown;
$poe_kernel->run;
