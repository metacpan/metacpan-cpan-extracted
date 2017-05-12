use Olson::Abbreviations;
use strict;
use warnings;

use Test::More tests => 4;

require_ok ('Olson::Abbreviations');

{
	my $oa = Olson::Abbreviations->new({tz_abbreviation => 'EST'});
	ok ( ! $oa->is_unambigious, 'EST is ambigious' );
}

{
	my $oa = Olson::Abbreviations->new({tz_abbreviation => 'EST'});
	ok ( $oa->is_known, 'EST is known' );
}

{
	my $oa = Olson::Abbreviations->new({tz_abbreviation => 'WUT'});
	is ( $oa->get_offset, '+0100', 'WUT returned correct offset' );
}



