#!/usr/bin/perl

use warnings;
use strict;

use lib './blib/lib';
use lib '../blib/lib';

use Test::More tests => 22;
use POE::Kernel;
use POE::Session::MessageBased;

POE::Session::MessageBased->create(
	inline_states => {
		_start => sub {
			my ($message, @params) = @_;
			ok($message->isa("POE::Session::Message"), "inline message is ok");
			$message->kernel->yield( count => 2 );
		},
		count => sub {
			my ($message, $count) = @_;
			pass("inline got count $count");
			if ($count < 10) {
				$message->kernel->yield( count => ++$count );
			}
		},
		_stop => sub {
			pass("inline test stopped");
		}
	},
);

POE::Session::MessageBased->create(
	object_states => [
		main->new() => {
			_start => "_poe_handle_start",
			count  => "_poe_handle_count",
			_stop  => "_poe_handle_stop",
		}
	],
);

POE::Kernel->run();
exit;

sub new { return bless {}, shift }

sub _poe_handle_start {
	my ($self, $message, @params) = @_;
	die unless ref($message->object) eq "main";
	ok($message->isa("POE::Session::Message"), "object message is ok");
	$message->kernel->yield( count => 13 );
}

sub _poe_handle_count {
	my ($self, $message, $count) = @_;
	die unless ref($message->object) eq "main";
	pass("object counter $count");
	if ($count < 21) {
		$message->kernel->yield( count => ++$count );
	}
}

sub _poe_handle_stop {
	pass("object test stopped");
}
