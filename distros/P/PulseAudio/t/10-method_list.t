#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use PulseAudio;

my %pacmd = (
	'PulseAudio' => [qw/
		list-modules
		list-cards
		list-sinks
		list-sources
		list-samples
		list-clients
		list-sink-inputs
		list-source-outputs
		stat
		info
		shared
		exit
		
		load-module
		load-sample
		load-sample-lazy
		load-sample-dir-lazy

		help
		describe-module
		suspend
		set-log-level
		set-log-meta
		set-log-time
		set-log-backtrace
		dump
		dump-volumes

		get_sample_by
		get_sink_by
		get_module_by
		get_source_output_by
		get_sink_input_by
		get_card_by
		get_client_by
		get_sample_by
	/]
	, 'PulseAudio::Sink' => [qw/
		exec
		set-sink-volume
		set-sink-mute
		set-default-sink
		set-sink-port
		suspend-sink
		update-sink-proplist
		play-sample
		play-file
	/]
	, 'PulseAudio::SinkInput' => [qw/
		set-sink-input-volume
		set-sink-input-mute
		move-sink-input
		update-sink-input-proplist
		kill-sink-input
	/]
	, 'PulseAudio::Source' => [qw/
		exec
		set-source-volume
		set-source-mute
		set-default-source
		set-source-port
		suspend-source
		update-source-proplist
	/]
	, 'PulseAudio::SourceOutput' => [qw/
		set-source-output-volume
		set-source-output-mute
		move-source-output
		update-source-output-proplist
		kill-source-output
	/]
	, 'PulseAudio::Card' => [qw/
		set-card-profile
	/]
	, 'PulseAudio::Client' => [qw/
		kill-client
	/]
	, 'PulseAudio::Module' => [qw/
		unload-module
	/]
	, 'PulseAudio::Sample' => [qw/
		remove-sample
		play-sample
	/]
);


while ( my ( $module, $methods ) = each %pacmd ) {
	my @method_list = $module->meta->get_all_method_names;

	subtest "$module includes methods and test coverage" => sub {
	
		subtest "[$module] API (inclues methods)" => sub {
			plan tests => scalar @{$methods};

			## Test that every command mentioned here is installed
			foreach my $name (map _cmd_to_method_name($_), @{$methods} ) {

				my $search = quotemeta($name);
				ok (
					(grep m/$search/, @method_list)
					, "Matching method for [$name] on [$module]"
				);

			}
		};

		subtest "[$module] Test coverage" => sub {
			my @commands = grep $_->{name} !~ /^_/, @{$module->_commands};
			plan tests => scalar @commands;
			
			foreach my $cmd ( @commands ) {
				my $name = $cmd->{name};
				ok (
					$name ~~ @$methods
					, "Command [$name] was tested for on [$module]"
				);
			}

		};

		done_testing();

	}

}

done_testing();

sub _cmd_to_method_name {
	my ($cmd) = @_;
	$cmd =~ tr/- /_/d;
	$cmd;
}
