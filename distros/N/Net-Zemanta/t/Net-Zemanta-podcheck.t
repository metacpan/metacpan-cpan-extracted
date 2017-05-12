use Pod::Checker;
use Test::More tests => 2;

my $c;

$c = new Pod::Checker '-warnings' => 0;
ok($c);

$c->parse_from_file('lib/Net/Zemanta/Suggest.pm', \*STDERR);
$c->parse_from_file('lib/Net/Zemanta/Preferences.pm', \*STDERR);

ok($c->num_errors() == 0 && $c->num_warnings() == 0);
