#!/usr/bin/env perl

use Data::Dumper;
use Term::ANSIColor;
our $command = 'find /var -name "m*"';

$data = run($command);

print color('green');
print Dumper $data;
print color('reset'), "\n";
sub run {
	my $command = shift @_;

	my $output;
	my $SO;
	my $SE;
	local *STDOUT;
	open STDOUT, '>', \$SO;
	local *STDERR;
	open STDERR, '>', \$SE;
	print 'Hello';
	print STDERR 'Message';
	$output->{captured} = `$command`;
	$output->{err} = $SE;
	$output->{out} = $SO;
	return $output;
}
