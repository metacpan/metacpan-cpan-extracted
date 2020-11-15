use strict;
use warnings;
#-----------------------------------------------------------------------
use Test::More				qw( no_plan );
use PESEL::Generator		qw( pesel   );
use Identifier::PL::PESEL;
#=======================================================================
ok( Identifier::PL::PESEL->new->validate( pesel() ));

