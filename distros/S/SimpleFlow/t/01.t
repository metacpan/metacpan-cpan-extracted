#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception; # die_ok
use File::Temp 'tempfile';
use SimpleFlow qw(task say2);
# written with Gemini's help
my $r = task({
	cmd => 'which ls'
});
my ($simple_task, $log_write, $stopping, $dry_run, $overwrite) = (0,0,0,0,0);
if (
		($r->{'die'}) &&
		($r->{done} eq 'now') &&
		(!$r->{'exit'}) &&
		($r->{overwrite} == 0) &&
		(ref $r->{'output.files'} eq 'ARRAY') &&
		(scalar @{ $r->{'output.files'} } == 0)
	) {
	$simple_task = 1;
} else {
	p $r;
	die 'test failed';
}
my ($fh, $fname) = tempfile( UNLINK => 0, DIR => '/tmp', SUFFIX => '.log');
$r = task({
	cmd            => 'which ln',
	'log.fh'       => $fh,
	'output.files' => $fname,
	overwrite      => 1
});
say2('Testing say2', $fh);
close $fh;
$log_write = 1 if ((-f $fname) && (-s $fname > 0));
# now re-run to make sure that the task realizes that it's already been done
$r = task({
	cmd            => 'which ln',
	'output.files' => $fname,
	overwrite      => 0
});
p $r;
if (
		($r->{done} eq 'before')
		&&
		($r->{duration} == 0)
		&&
		($r->{'will.do'} eq 'no')
	) {
	$stopping = 1;
} else {
	p $r;
	die 'Could not stop because output files were already done';
}
# test a dry run
$r = task({
	cmd       => 'which ln',
	'dry.run' => 1
});
if (
	($r->{'dry.run'})	        &&
	($r->{duration} == 0)	  &&
	((defined $r->{'will.do'}) && ($r->{'will.do'} eq 'no'))
	) {
	$dry_run = 1;
} else {
	p $r;
	die 'dry run failed';
}
# make a non-existent file
$fh = File::Temp->new(DIR => '/tmp');
close $fh;
unlink $fh->filename;
dies_ok { # Gemini helped
	task({
		cmd => 'ls ' . $fh->filename, # ls on a non-existent file
	});
} '"task" dies when it should';
sleep 1;
my $mod0 = -M $fname;
say "\$mod0 = $mod0";
$r = task({
	cmd            => "which ln > $fname",
	overwrite      => 'true',
	'output.files' => $fname
});
printf("$mod0 vs %lf\n", -M $fname);
if (
		($mod0 > -M $fname) # the file has been modified
		&&
		(-s $fname > 0)
	) {
	$overwrite = 1;
} else {
	p $r;
	die 'output files are not overwritten when "overwrite" is true"';
}
ok($simple_task, 'Verified: Simple task works');
ok($log_write,   'Verified: Can write to log files with subroutine "say2"');
ok($stopping,    'Verified: tasks do not run when output files exist');
ok($dry_run,     'Verified: dry run works');
ok($overwrite,   'Verified: "overwrite" option overwrites files in "output.files"');
done_testing();
