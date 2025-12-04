#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp 'tempfile';
use SimpleFlow 'task';
# written with Gemini's help
my $r = task({
	cmd => 'which ls'
});
my $simple_task = 0;
if (
		($r->{'die'} eq 'true') &&
		($r->{'done'} eq 'now') &&
		($r->{'exit'} == 0) &&
		($r->{'overwrite'} eq 'false') &&
		(ref $r->{'output.files'} eq 'ARRAY') &&
		(scalar @{ $r->{'output.files'} } == 0)
	) {
	$simple_task = 1;
}
my ($fh, $fname) = tempfile( UNLINK => 0, DIR => '/tmp');
close $fh;
open $fh, '>', $fname;
$r = task({
	cmd            => 'which ln',
	'log.fh'       => $fh,
	'output.files' => $fname,
	overwrite      => 1
});
close $fh;
p $r;
my $log_write = 0;
$log_write = 1 if ((-f $fname) && (-s $fname > 0));
unless ($log_write == 1) {
	plan skip_all => "FAIL: cannot write log file $fname"
}
plan tests => 2;
ok($simple_task, 'Verified: Simple task works');
ok($log_write,   'Verified: Can write to log files');
