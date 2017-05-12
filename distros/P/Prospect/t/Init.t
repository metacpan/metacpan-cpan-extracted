#-------------------------------------------------------------------------------
# NAME: Init.t
# PURPOSE: test script for the parameters defined in the Prospect::Init class
#          used in conjunction with Makefile.PL to test installation
#
# $Id: Init.t,v 1.2 2003/11/07 18:41:58 cavs Exp $
#-------------------------------------------------------------------------------

use Prospect::Init;
use Test::More;
use warnings;
use strict;

plan tests => 4;

ok( -d $Prospect::Init::PROSPECT_PATH,      "PROSPECT_PATH ($Prospect::Init::PROSPECT_PATH) valid" );
ok( -d $Prospect::Init::PDB_PATH,           "PDB_PATH ($Prospect::Init::PDB_PATH) valid" );
ok( -d $Prospect::Init::PROCESSED_PDB_PATH, "PROCESSED_PDB_PATH ($Prospect::Init::PROCESSED_PDB_PATH) valid" );
ok( -x $Prospect::Init::MVIEW_APP,          "MVIEW_APP ($Prospect::Init::MVIEW_APP) executable" );
