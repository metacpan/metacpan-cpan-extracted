#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('App::PNGCrush');
	use_ok( 'POE::Component::App::PNGCrush' );
}

diag( "Testing POE::Component::App::PNGCrush $POE::Component::App::PNGCrush::VERSION, Perl $], $^X" );

my $o = POE::Component::App::PNGCrush->spawn(debug=>1);
isa_ok($o, 'POE::Component::App::PNGCrush');
can_ok($o, qw(spawn run shutdown session_id));
$o->shutdown;

$poe_kernel->run;