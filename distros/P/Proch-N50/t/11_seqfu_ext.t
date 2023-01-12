use strict;
use warnings;
use Proch::Seqfu;
use Test::More;
use FindBin qw($RealBin);
my $iVersion = "";
eval {
    my $version = seqfu_version();
    $iVersion .= $version;
};


my $has_seqfu = has_seqfu();
ok($@ eq '', "seqfu_version() executed and returned $iVersion: $@");

ok(($has_seqfu == 1 or $has_seqfu == 0), "has_seqfu() returned $has_seqfu");
done_testing();


