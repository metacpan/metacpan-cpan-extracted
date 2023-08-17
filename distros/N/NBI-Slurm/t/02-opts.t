use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use_ok 'NBI::Opts';

# Test OK
my $opts = NBI::Opts->new(-queue => "nbi-short");

# Test bad params
eval {
  my $opts = NBI::Opts->new(-queue => "nbi-short", -foo => "bar");
};
ok($@ ne '', "Unknown flag -foo raises errors: " . $@);
$opts->add_option('--mail-user=sam.fireman@nbi.ac.uk');
ok($opts->opts_count == 1, "Added one option");
print $opts->view();
done_testing();