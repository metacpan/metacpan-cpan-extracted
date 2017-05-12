
use Test::More  tests=>3;
use Telephone::Mnemonic::US::Number qw/ partial_codes /;

note 'partial codes';
my $h1 = { area_code=>734, station_code=>534, house_code=>1212 };
is_deeply partial_codes( '(734) 534 1212'), $h1  ;
my $h2 = { area_code=>'', station_code=>534, house_code=>1212 };

note 'area code should default to null string';
is_deeply partial_codes( '5341212'), $h2; 
my $h3 = { area_code=>'', station_code=>534, house_code=>1212 };
ok ! partial_codes( '1212');
