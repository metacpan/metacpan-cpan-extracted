package bug16789;
use strict;
use warnings;
use Test::More;
plan skip_all => 'developer tests' unless $ENV{USER} eq 'perigrin';

use Regexp::Common qw(IRC);
my @targets =
  ( 'jto@poco.server.irc', '#channel', 'moo', 'eek!~eek@wanker.co.uk' );

plan tests => scalar @targets;

foreach my $target (@targets) {
    ok( $target =~ /$RE{IRC}{msgto}/ );
}
