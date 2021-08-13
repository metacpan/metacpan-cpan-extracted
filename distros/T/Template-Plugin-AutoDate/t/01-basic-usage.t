use Test2::V0;
use Template;

my @tests= (
	[ '[% USE AutoDate %][% x = "2020-01-01 01:01:01" %][% x.strftime("%Y") %]', '2020' ],
	[ '[% USE AutoDate %][% x = "2020-01-01 00:00:00" %][% AutoDate.coerce(x).add("minutes",10).hms %]', '00:10:00' ],
	[ '[% USE y2k= AutoDate(year => 2000, month => 1, day => 1) %][% y2k.add("months",1).month %]', '2' ],
);

my $tt= Template->new;

for (@tests) {
   my ($tpl, $expected)= @$_;
   $tt->process(\$tpl, {}, \my $out)
      or diag $tt->error;
   is( $out, $expected, "Template: $tpl" );
}

done_testing;
