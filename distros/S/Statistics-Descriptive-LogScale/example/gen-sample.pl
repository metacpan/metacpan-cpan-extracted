#!/usr/bin/env perl

# This is NOT an example.
# It is a script for generating random samples of needed shape
# See $0 --help

use strict;
use warnings;

# math functions and known distributions
my @func    = qw(exp log sin cos sqrt abs pi atan),
my @distr   = qw(Normal Exp Bernoulli Uniform Dice);
my $re_num  = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;
my $white   = join "|", @func, @distr, $re_num, '[-+/*%(),]', '\s+';
$white   = qr/(?:$white)/;

# Usage
if (!@ARGV or grep { $_ eq '--help' } @ARGV) {
	print STDERR <<"USAGE";
Usage: $0 [n1 formula1] [n2 formula2] ...
Output n1 random numbers distributed as formula1, etc
Formula may include: numbers, arightmetic operations and parens;
    standard functions: @func;
    and known random distributions (here =nnn denotes default value):
	Normal([mean=0,]deviation=1),
	Exp(mean=1),
	Bernoulli(probability=0.5),
	Uniform([lower=0,]upper=1),
	Dice(n=6),
USAGE
	exit 1;
};

# some useful functions absent in perl
sub pi() { 4*atan2 1,1};
sub atan($;$) {$_[1] = 1 unless defined $_[1]; return atan2 $_[0],$_[1]};

my @todo;
while (@ARGV) {
	my $n = shift;
	if ($n !~ /^\d+$/) {
		die "Random var count must be a positive integer. See $0 --help";
	};

	my $expr = shift;
	if (!defined $expr) {
		die "Odd number of arguments, see $0 --help";
	};
	if ($expr !~ /\S/) {
		die "Random var formula must be nonempty, see $0 --help";
	};
	$expr =~ /^$white+$/
		or die "Random var formula contains non-whitelisted characters. See $0 --help";

	my $code = eval "sub { $expr; };";
	if ($@) {
		die "Random var formula didn't compile: $@";
	};

	push @todo, [$code, $n];
};

# do the job
foreach (@todo) {
	while ($_->[1] --> 0) {
		print $_->[0]->(), "\n";
	};
};

#########

# TODO could cache one more point, see Box-Muller transform
sub Normal {
	my $disp = pop || 1;
	my $mean = shift || 0;
	return $mean + $disp * sin(2*pi()*rand()) * sqrt(-2*log(rand));
};

# toss coin
sub Bernoulli {
	my $prob = shift;
	$prob = 0.5 unless defined $prob;
	return rand() < $prob ? 1 : 0;
};

sub Uniform {
	my ($x, $y) = @_;
	$y ||= 0;
	$x = 1 unless defined $x;
	return $x + rand() * ($y - $x);
};

sub Exp {
	my $mean = shift || 1;
	return -$mean * log rand();
};

sub Dice {
	my $n = int (shift||0) || 6;
	return int ($n * rand()) + 1;
};
