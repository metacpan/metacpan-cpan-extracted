use Test::More;

use Swim;
use Swim::Util;

my $t = -e 't' ? 't' : 'test';

my $swim = Swim::Util->slurp("$t/Doc.swim");
my $pod = Swim::Util->slurp("$t/Doc.pod");
my $yaml = Swim::Util->slurp("$t/Meta");
my $meta = Swim::Util->merge_meta({}, $yaml);

my $got = Swim->new(
    text => $swim,
    meta => $meta,
    option => {
        complete => 1,
        wrap => 1,
        'pod-upper-head' => 1,
    },
)->to_pod;
$got =~ s/\d+\.\d+\.\d+/X.X.X/;

# use Text::Diff;
# die diff \$pod, \$got;

is $got, $pod, 'Everything works';

done_testing;
