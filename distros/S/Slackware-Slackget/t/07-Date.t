use Test::More tests => 23;

BEGIN {
	use_ok( 'Slackware::Slackget::Date' );
}

my $date = Slackware::Slackget::Date->new(
		'day-name' => Mon, 
		'day-number' => 5, 
		'year' => 2005,
		'month-number' => 2,
		'hour' => '12:02:35',
		'use-approximation' => undef
);

ok( $date );
ok( $date->year == 2005 );
ok( $date->monthname eq 'Feb');
ok( $date->dayname eq 'Mon');
ok( $date->daynumber == 5);
ok( $date->monthnumber == 2);
ok( $date->hour eq '12:02:35');

my $date2 = Slackware::Slackget::Date->new(
		'day-name' => Mon, 
		'day-number' => 5, 
		'year' => 2005,
		'month-number' => 2,
		'hour' => '12:02:35',
		'use-approximation' => undef
);

my $date3 = Slackware::Slackget::Date->new(
		'day-name' => Mon, 
		'day-number' => 5, 
		'year' => 2005,
		'month-number' => 3,
		'hour' => '12:02:35',
		'use-approximation' => undef
);

ok(($date cmp $date2) == 0 );
ok( $date eq $date2 );
ok( $date lt $date3);
ok( $date le $date3);
ok($date3 gt $date);
ok($date3 ge $date);

ok(($date <=> $date2) == 0 );
ok( $date == $date2 );
ok( $date < $date3);
ok( $date <= $date3);
ok($date3 > $date);
ok($date3 >= $date);

ok($date->to_string);
ok($date->to_xml);
ok($date->to_html);
