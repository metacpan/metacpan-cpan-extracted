#!perl

use Test::More tests => 9;

BEGIN {
	use_ok('PulseAudio') || print "Bail out!\n";
	use_ok('PulseAudio::Card');
	use_ok('PulseAudio::Client');
	use_ok('PulseAudio::Sink');
	use_ok('PulseAudio::SinkInput');
	use_ok('PulseAudio::Source');
	use_ok('PulseAudio::SourceOutput');
	use_ok('PulseAudio::Module');
	use_ok('PulseAudio::Sample');
}

diag( "Testing PulseAudio $PulseAudio::VERSION, Perl $], $^X" );
