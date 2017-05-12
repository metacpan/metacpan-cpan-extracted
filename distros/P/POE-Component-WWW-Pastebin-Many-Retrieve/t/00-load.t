#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('WWW::Pastebin::Many::Retrieve');
    use_ok('POE::Component::NonBlockingWrapper::Base');
	use_ok( 'POE::Component::WWW::Pastebin::Many::Retrieve' );
}

diag( "Testing POE::Component::WWW::Pastebin::Many::Retrieve $POE::Component::WWW::Pastebin::Many::Retrieve::VERSION, Perl $], $^X" );

my $poco = POE::Component::WWW::Pastebin::Many::Retrieve->spawn(debug=>1);
isa_ok($poco, 'POE::Component::WWW::Pastebin::Many::Retrieve');
can_ok($poco, qw(spawn retrieve shutdown session_id));
$poco->shutdown;
$poe_kernel->run;