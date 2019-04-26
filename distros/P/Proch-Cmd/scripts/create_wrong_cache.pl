#!/usr/bin/env perl

use 5.016;
use Storable qw(retrieve store);

my $file = shift @ARGV;
my $data;

$data->{class} = 'Wrong class';
$data->{script} = $0;
my $date = `date`;
chomp($date);
$data->{date} = $date;

if ($file) {
	store $data, $file;
} else {
	die "Please specify a filename as output (it's the only argument)";
}
