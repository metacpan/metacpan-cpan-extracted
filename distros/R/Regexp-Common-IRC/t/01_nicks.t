#!/usr/bin/perl 
use strict;
use Regexp::Common qw(IRC);
use Test::More qw(no_plan);

for (qw(` ``)) { 
	like($_, qr($RE{IRC}{special}), "special: $_");
}

open(NICKS, 't/nicks') || die "could not open nicks file: $!";
while (<NICKS>) { 
	chomp;
	like($_, qr($RE{IRC}{nick}), "nick: $_");
}

1;
__END__
