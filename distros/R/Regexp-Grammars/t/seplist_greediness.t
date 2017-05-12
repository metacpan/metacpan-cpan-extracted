use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $list_greedy = qr{
    <List>

    <rule: List>
        <[item=Value]>+ % [,]
        <after=(.+)>

    <token: Value>
        \d+
}xms;

my $list_parsimonious = qr{
    <List>

    <rule: List>
        <[item=Value]>+? % [,]
        <after=(.+)>

    <token: Value>
        \d+
}xms;

my $list_parsimonious_anchored = qr{
    <List>

    <rule: List>
        <[item=Value]>+? % [,]
        <after=(, \d+ etc)>

    <token: Value>
        \d+
}xms;

my $list_gluttonous = qr{
    <List>

    <rule: List>
        <[item=Value]>++ % [,]
        <after=(.+)>

    <token: Value>
        \d+
}xms;

no Regexp::Grammars;

my $data     = '1,2,3,4,5';
my $data_etc = '1,2,3,4,5etc';

ok +($data =~ $list_greedy)         => 'Matched greedy';
is_deeply $/{List}{item}, [1,2,3,4] => '...with correct items';
is        $/{List}{after}, ',5'     => '...with correct remainder';

ok +($data =~ $list_parsimonious)     => 'Matched parsimonious';
is_deeply $/{List}{item}, [1]         => '...with correct items';
is        $/{List}{after}, ',2,3,4,5' => '...with correct remainder';

ok +($data_etc =~ $list_parsimonious_anchored) => 'Matched parsimonious anchored';
is_deeply $/{List}{item}, [1,2,3,4]            => '...with correct items';
is        $/{List}{after}, ',5etc'             => '...with correct remainder';

ok !($data =~ $list_gluttonous)      => 'Did not match gluttonous';

ok +($data_etc =~ $list_gluttonous) => 'Matched gluttonous';
#is_deeply $/{List}{item}, [1,2,3,4,5] => '...with correct items';
is        $/{List}{after}, 'etc'      => '...with correct remainder';
