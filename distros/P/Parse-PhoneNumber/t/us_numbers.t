use Test::More qw[no_plan];
use strict;
use FindBin;

use lib qw[lib ../lib];

BEGIN {
	use_ok 'Parse::PhoneNumber';
}

my $p = Parse::PhoneNumber->new;

isa_ok $p, 'Parse::PhoneNumber';

my @good = qw(	
	810-555-9841
	1-517-842-0924
	8927908123
	12480982374
	+1.342.4234.1501
	1+823.342.1525
);

my @bad = qw(
	1
	1-------------
	324-2399
	234.2381
	23
	14876
	82-231.4198
);
	
	
	
for (@good) {
	my $number = $p->parse( number => $_, assume_us => 1 );
	if ( $number ) {
		isa_ok $number,          'Parse::PhoneNumber::Number';
		is     $number->cc,      1, "Proper CC code: ".$number->cc;
		is     $number->orig,    $_, "Original number: ".$number->orig;
		like   $number->num,     qr/^\d+$/, "Original matches: $_";
		like   $number->opensrs, qr/\+\d+\.\d+(?:x\d+)?/, "Opensrs syntax correct: ".$number->opensrs;
		like   $number->human,   qr/\+\d+\s+\d+(?:x\d+)?/, "Human readable format: ".$number->human;
		if ( $number->ext ) {
			like $number->ext, qr/\d+/, "Extension: ".$number->ext;
		} else {
			is $number->ext, undef, "No extension is undef";
		}
	} else {
		fail("$_ is good");
		diag("$_ did not parse, should");
	}
}

for (@bad) {
	my $number = $p->parse( number => $_, assume_us => 1 );

	if ($number) {
		fail("$_ is bad");
		diag("$_ parsed, should not");
	} else {
		ok("$_ is bad");
	}
}


__DATA__


