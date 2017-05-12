use Test::More tests => 7;
use Number::Phone::Normalize;

%par = (CountryCode=>'49', AreaCode=>'89', IntlPrefixOut=>'+');

is(phone_intl('+1 555 123 4567', %par), '+1 555 123 4567');
is(phone_intl('001 555 123 4567', %par), '+1 555 123 4567');

is(phone_intl('+49 999 12345678', %par), '+49 999 12345678');
is(phone_intl('0999 12345678', %par), '+49 999 12345678');

is(phone_intl('+49 89 32168', %par), '+49 89 32168');
is(phone_intl('089 32168', %par), '+49 89 32168');
is(phone_intl('32168', %par), '+49 89 32168');
