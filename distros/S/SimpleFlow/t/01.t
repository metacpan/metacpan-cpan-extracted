#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp 'tempfile';
use SimpleFlow qw(task say2);
# written with Gemini's help
my $r = task({
	cmd => 'which ls'
});
my $simple_task = 0;
if (
		($r->{'die'} eq 'true') &&
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
my $log_write = 0;
$log_write = 1 if ((-f $fname) && (-s $fname > 0));
# now re-run to make sure that the task realizes that it's already been done
$r = task({
	cmd            => 'which ln',
	'output.files' => $fname,
	overwrite      => 0
});
p $r;
my $stopping = 0;
if (
		($r->{done} eq 'before')
		&&
		($r->{duration} == 0)
	) {
	$stopping = 1;
} else {
	p $r;
	die 'Could not stop because output files were already done';
}
ok($simple_task, 'Verified: Simple task works');
ok($log_write,   'Verified: Can write to log files with subroutine "say2"');
ok($stopping,    'Verified: tasks do not run when output files exist');
done_testing();
