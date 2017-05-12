use Test::More tests => 7;
use Number::Phone::Normalize;

my $obj = Number::Phone::Normalize->new(
  CountryCode=>'49',
  AreaCode=>'89',
  IntlPrefixOut=>'+');

is($obj->intl('+1 555 123 4567'), '+1 555 123 4567');
is($obj->intl('001 555 123 4567'), '+1 555 123 4567');

is($obj->intl('+49 999 12345678'), '+49 999 12345678');
is($obj->intl('0999 12345678'), '+49 999 12345678');

is($obj->intl('+49 89 32168'), '+49 89 32168');
is($obj->intl('089 32168'), '+49 89 32168');
is($obj->intl('32168'), '+49 89 32168');
