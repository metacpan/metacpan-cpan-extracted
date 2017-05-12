package ip4addr;
use strict;
use warnings;
use Regexp::Common qw(IRC);
use Test::More qw(no_plan);

foreach my $target ( qw( 1:2:3:4:5:6:7:A ) ) {
	ok($target =~ /$RE{IRC}{ip4addr}/ );
}