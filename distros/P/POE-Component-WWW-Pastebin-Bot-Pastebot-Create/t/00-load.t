#!/usr/bin/env perl

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::Pastebin::Bot::Pastebot::Create');
	use_ok( 'POE::Component::WWW::Pastebin::Bot::Pastebot::Create' );
}

diag( "Testing POE::Component::WWW::Pastebin::Bot::Pastebot::Create $POE::Component::WWW::Pastebin::Bot::Pastebot::Create::VERSION, Perl $], $^X" );

my $o = POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn(debug=>1);
isa_ok($o,'POE::Component::WWW::Pastebin::Bot::Pastebot::Create');
can_ok($o, qw(spawn paste shutdown session_id));
$o->shutdown;
$poe_kernel->run;