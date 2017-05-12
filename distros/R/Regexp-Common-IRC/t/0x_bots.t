#!/usr/bin/perl 
use strict;
use Regexp::Common qw(IRC);
use Test::More qw(no_plan);
 
like($_, qr($RE{IRC}{nick}), "nick: $_") for qw(
	perigrin
);

no warnings;
like($_, qr($RE{IRC}{channel}), "channel: $_") for qw(
	#axkit-dahut
);

'Flexo: summon perigrin to #axkit' =~ /$RE{IRC}{nick}{-keep}: summon $RE{IRC}{nick}{-keep} (?:to $RE{IRC}{channel}{-keep})?/;
is($1, 'Flexo');
is($2, 'perigrin');
is($3, '#axkit');
1;
__DATA__
perigrin
