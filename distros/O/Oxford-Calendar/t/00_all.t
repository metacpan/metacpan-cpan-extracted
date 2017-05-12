use strict;
use warnings;

use Test::More;
use Test::Exception;
use Date::Calc;
use Oxford::Calendar;

plan tests => 27;

# Date in full term
my $testdate1 = 'Sunday, 7th week, Hilary 2002';
is( Oxford::Calendar::ToOx(24, 2, 2002, { mode => 'nearest' } ), $testdate1 );
is( Oxford::Calendar::ToOx(24, 2, 2002, { mode => 'ext_term' } ), $testdate1 );
is( Oxford::Calendar::ToOx(24, 2, 2002, { mode => 'full_term' } ), $testdate1 );
is( Oxford::Calendar::FromOx( Oxford::Calendar::Parse($testdate1)), "24/2/2002" );
# Check the array mode
my @ary = Oxford::Calendar::ToOx(24,2,2002);
is( $ary[0], 'Sunday' );
# and with a date out of time (to test the nearest branch)
my $testdate4 = 'Tuesday, -1st week, Hilary 2008';
@ary = Oxford::Calendar::ToOx(1,1,2008, { mode => 'nearest' });
is( $ary[0], 'Tuesday' );

# Date in extended term
my $testdate2 = 'Friday, 9th week, Hilary 2009';
is( Oxford::Calendar::ToOx(20, 3, 2009, { mode => 'nearest' } ), $testdate2 );
is( Oxford::Calendar::ToOx(20, 3, 2009, { mode => 'ext_term' } ), $testdate2 );
is( Oxford::Calendar::ToOx(20, 3, 2009, { mode => 'full_term' } ), undef );
is( Oxford::Calendar::FromOx( Oxford::Calendar::Parse($testdate2)), "20/3/2009");

# Date not in term
my $testdate3 = 'Thursday, 11th week, Michaelmas 2007';
is( Oxford::Calendar::ToOx(20, 12, 2007, { mode => 'nearest' } ), $testdate3 );
is( Oxford::Calendar::ToOx(20, 12, 2007, { mode => 'ext_term' } ), undef );
is( Oxford::Calendar::ToOx(20, 12, 2007, { mode => 'full_term' } ), undef );
is( Oxford::Calendar::FromOx( Oxford::Calendar::Parse($testdate3)), "20/12/2007");

# Some more dates
is( Oxford::Calendar::ToOx(12, 1, 2008, { mode => 'ext_term' } ),
    'Saturday, 0th week, Hilary 2008' );
is( Oxford::Calendar::ToOx(1, 1, 2008, { mode => 'ext_term' } ), undef );

# NextTerm
my @next_term = Oxford::Calendar::NextTerm( 2008, 1, 1 );
is( $next_term[0], 2008 );
is( $next_term[1], 'Hilary' );
@next_term = Oxford::Calendar::NextTerm( 2008, 1, 14 );
is( $next_term[0], 2008 );
is( $next_term[1], 'Trinity' );

# Dies
my @today = Date::Calc::Today;
# Future proof the module by testing against a data in the future that we
# never expect to have data for
my $future_year = $today[0] + 50;

throws_ok { Oxford::Calendar::ToOx( 1, 11, $future_year, { mode => 'full_term' } ) } qr/Date out of range/, 'ToOx out of range (in term)';
throws_ok { Oxford::Calendar::ToOx( 1, 11, $future_year, { mode => 'nearest' } ) } qr/Date out of range/, 'ToOx out of range (out of term)';
throws_ok { Oxford::Calendar::FromOx( $future_year, 'Hilary', 1, 'Sunday' ) } qr/No data for Hilary $future_year/, 'FromOx out of range';

# Provisional
my $testdate5 = 'Thursday, -2nd week, Hilary 2022';
is( Oxford::Calendar::ToOx(30, 12, 2021, { mode => 'nearest', confirmed => 0 } ), $testdate5, 'Provisional date' );
is( Oxford::Calendar::ToOx(30, 12, 2021, { mode => 'nearest', confirmed => 1 } ), undef, 'Provisional date with confirmed => 1' );
my $testdate6 = 'Tuesday, 3rd week, Hilary 2022';
is( Oxford::Calendar::ToOx(1, 2, 2022, { mode => 'full_term', confirmed => 0 } ), $testdate6, 'Provisional date' );
is( Oxford::Calendar::ToOx(1, 2, 2022, { mode => 'full_term', confirmed => 1 } ), undef, 'Provisional date with confirmed => 1' );
