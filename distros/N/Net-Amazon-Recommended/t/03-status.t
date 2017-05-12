use Test::More;
use Test::Exception;

plan skip_all => 'ENV is not set' if ! exists $ENV{AMAZON_EMAIL} || ! exists $ENV{AMAZON_PASSWORD};

plan tests => 46;

use_ok('Net::Amazon::Recommended');

my $obj;
lives_ok { $obj = Net::Amazon::Recommended->new(email => $ENV{AMAZON_EMAIL}, password => $ENV{AMAZON_PASSWORD}) };
my $dat;

lives_ok { $dat = $obj->get_status('4862671080') };
is($dat, undef, 'not found');

lives_ok { $dat = $obj->get_status('486267108X') };
TODO: {
	local $TODO = 'depending on purchase history';
	is($dat->{starRating}, 0, 'starRating');
	is($dat->{isOwned}, 1, 'isOwned');
}
my (%orig) = map { $_ => $dat->{$_} } qw(starRating isOwned);
$orig{isNotInterested} = 0;
$orig{isExcluded} = 0;
lives_ok { $obj->set_status('486267108X', { starRating => 5, isOwned => 0, isNotInterested => 0, isExcluded => 0 }) };
lives_ok { $dat = $obj->get_status('486267108X') };

is($dat->{starRating}, 5, 'starRating');
is($dat->{isOwned}, 0, 'isOwned');

lives_ok { $dat = $obj->get_last_status('NotInterested') };
isnt($dat->{itemId}, "'486267108X'", '! NotInterested by asin');

lives_ok { $dat = $obj->get_last_status('Rated') };
is($dat->{itemId}, "'486267108X'", 'Rated by asin');
is($dat->{starRating}, 5, 'starRating');
is($dat->{isExcluded}, 0, 'isExcluded');

lives_ok { $obj->set_status('486267108X', { starRating => 0, isOwned => 0, isNotInterested => 1, isExcluded => 0 }) };
lives_ok { $dat = $obj->get_status('486267108X') };

is($dat->{starRating}, 0, 'starRating');
is($dat->{isOwned}, 0, 'isOwned');

lives_ok { $dat = $obj->get_last_status('Owned') };
isnt($dat->{itemId}, "'486267108X'", 'asin');

lives_ok { $dat = $obj->get_last_status('NotInterested') };
is($dat->{itemId}, "'486267108X'", 'asin');
is($dat->{isNotInterested}, 1, 'isNotInterested');

# Can't check exclusion

lives_ok { $obj->set_status('486267108X', { starRating => 0, isOwned => 1, isNotInterested => 0, isExcluded => 1 }) };
lives_ok { $dat = $obj->get_status('486267108X') };

is($dat->{starRating}, 0, 'starRating');
is($dat->{isOwned}, 1, 'isOwned');

lives_ok { $dat = $obj->get_last_status('Owned') };
is($dat->{itemId}, "'486267108X'", 'asin');
is($dat->{isExcluded}, 1, 'isExcluded');

lives_ok { $dat = $obj->get_last_status('NotInterested') };
isnt($dat->{itemId}, "'486267108X'", 'asin');

lives_ok { $obj->set_status('486267108X', { starRating => 5, isOwned => 0, isNotInterested => 0, isExcluded => 1 }) };
lives_ok { $dat = $obj->get_status('486267108X') };

is($dat->{starRating}, 5, 'starRating');
is($dat->{isOwned}, 0, 'isOwned');

lives_ok { $dat = $obj->get_last_status('Owned') };
isnt($dat->{itemId}, "'486267108X'", 'asin');

lives_ok { $dat = $obj->get_last_status('Rated') };
is($dat->{itemId}, "'486267108X'", 'asin');
is($dat->{starRating}, 5, 'starRating');
is($dat->{isExcluded}, 1, 'isExcluded');

lives_ok { $obj->set_status('486267108X', \%orig) };
