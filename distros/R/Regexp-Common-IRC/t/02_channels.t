#!/usr/bin/perl 
use strict;
use Regexp::Common qw(IRC);
use Test::More qw(no_plan);

open(CHANNELS, 't/channels') || die "could not open channels file: $!";
while (<CHANNELS>) { 
	chomp;
	like($_, qr($RE{IRC}{channel}), "channel: $_");
}

1;
__END__
