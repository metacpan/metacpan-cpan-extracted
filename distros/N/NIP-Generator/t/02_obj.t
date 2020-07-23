use strict;
use warnings;
#-----------------------------------------------------------------------
use FindBin					qw( $Bin		 );
use lib $Bin;
#-----------------------------------------------------------------------
use Test::More				qw( no_plan		 );
use NIP::Generator			qw( nip			 );
use Business::PL::NIP		qw( is_valid_nip );
#=======================================================================
ok( is_valid_nip( NIP::Generator->new->nip() ) );
