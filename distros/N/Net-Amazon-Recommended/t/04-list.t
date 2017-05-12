use Test::More;
use Test::Exception;

plan skip_all => 'ENV is not set' if ! exists $ENV{AMAZON_EMAIL} || ! exists $ENV{AMAZON_PASSWORD};

plan tests => 24;

use_ok('Net::Amazon::Recommended');

my $obj;
lives_ok { $obj = Net::Amazon::Recommended->new(email => $ENV{AMAZON_EMAIL}, password => $ENV{AMAZON_PASSWORD}) };
my $dat;
foreach my $type (qw(rated notinterested owned purchased)) {
	lives_ok { $dat = $obj->get_list($type) };
	TODO: {
		local $TODO = 'depending on purchase history';
		is(@$dat, 15, '1 page for '.$type);
	}
	lives_ok { $dat = $obj->get_list($type, 2) };
	TODO: {
		local $TODO = 'depending on purchase history';
		is(@$dat, 30, '2 pages for '.$type);
	}
	like($dat->[0]{url}, qr|https?://www.amazon.[^/]*/dp/[^/]+$|);
}
lives_ok { $dat = $obj->get_list('notinterested', undef) };
TODO: {
	local $TODO = 'depending on purchase history';
	cmp_ok(@$dat, '>', 30, 'unlimited pages');
}
