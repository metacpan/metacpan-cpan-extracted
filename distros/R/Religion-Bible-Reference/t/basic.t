use Test::More tests => 11;
use strict;
use warnings;

BEGIN { use_ok("Religion::Bible::Reference"); }

{ # the truth will set you free
	my $bibref = bibref("jn8:32");

	isa_ok($bibref, "Religion::Bible::Reference");

	is($bibref->{book}, "John", "jn8:32 book");

	is(
		$bibref->stringify,
		"John 8:32",
		"jn8:32 stringification"
	);

  is(
    $bibref->stringify_short,
    'Jn 8:32',
    'short stringification works',
  );
}

{
	my $bibref = bibref("jn10:11-12");
	is(
		$bibref->stringify,
		"John 10:11-12",
		"jn10:11-12 stringification"
	);
}

{
	my $bibref = bibref("Lk 1:12-51");
	is(
		$bibref->stringify,
		"Luke 1:12-51",
		"Lk 1:12-51 stringification"
	);
}

{
	my $bibref = bibref("1Kgs 1:2-3,5");

	is(
		$bibref->stringify,
		"1 Kings 1:2-3, 5",
		"1Kgs 1:2-3, 5 stringification"
	);
}

{
	my $bibref = bibref("Jn 1:10-11,20-21,23");
	is(
		$bibref->stringify,
		"John 1:10-11, 20-21, 23",
		"Jn 1:10-11,20-21,23 stringification"
	);
}

{
	is(bibref("1Tim 99:1"),    undef, "invalid beginning");
	is(bibref("1Kgs 1:2-300"), undef, "invalid ending");
}

