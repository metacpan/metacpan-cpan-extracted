#!/usr/bin/perl

package RecordingHandler;

use strict;
use warnings;

use Test::More qw(no_plan);
use File::Path qw(remove_tree);

BEGIN { 
    remove_tree("test-recording");
    use_ok("Runops::Recorder::Reader"); 
}

# Generate some data
qx{$^X -Mblib -MRunops::Recorder=test-recording t/data/example.pl};
fail "Failed to generate test data" if $? or !-e "test-recording/main.data";

my $keyframes;
my $switched_files;
my $next_statements;
my $enter_subs;
my $die;
my $keyframe_timestamps;

my %handlers = (
    on_keyframe => sub { $keyframes++ },
    on_switch_file => sub { $switched_files++ },
    on_next_statement => sub { $next_statements++ },
    on_enter_sub => sub { $enter_subs++ },
    on_die => sub { $die++ },
    on_keyframe_timestamp => sub { $keyframe_timestamps++; },
);

my $reader = Runops::Recorder::Reader->new("test-recording", { handlers => \%handlers, skip_keyframes => 0 });
$reader->read_all;

is($keyframes, 1);
is($keyframe_timestamps, 2);
is($switched_files, 5);
is($enter_subs, 3);
is($next_statements, 14);
is($die, 1);
