#!/usr/bin/perl

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

my $reader = Runops::Recorder::Reader->new("test-recording", { skip_keyframes => 0 });

my ($cmd, $data) = $reader->read_next();
is($cmd, 0);
is($data, "\0\0\0\0");
is_deeply ([$reader->decode($cmd, $data)], []);

($cmd, $data) = $reader->read_next();
is($cmd, 5);
is(length $data, 4);

($cmd, $data) = $reader->read_next();
is($cmd, 8);
is(length $data, 4);

($cmd, $data) = $reader->read_next();
is($cmd, 1);
is($data, "\2\0\0\0");
is($reader->get_identifier(2), "t/data/example.pl");

($cmd, $data) = $reader->read_next();
is($cmd, 2);
is($data, "\3\0\0\0");

# Skip until next enter file
$reader->skip_until(1);

($cmd, $data) = $reader->read_next();
is($cmd, 1);
is($data, "\4\0\0\0");
like ($reader->get_identifier(4), qr/strict\.pm$/);

# Skip until next entersub
$reader->skip_until(4);
($cmd, $data) = $reader->read_next();
is($cmd, 4);
is($data, "\6\0\0\0");
is($reader->get_identifier(3), "strict::import");
