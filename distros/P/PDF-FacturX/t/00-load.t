use strict;
use warnings;
use Test::More tests => 3;

use_ok('PDF::FacturX')         or BAIL_OUT("cannot load PDF::FacturX");
use_ok('PDF::FacturX::XML')    or BAIL_OUT("cannot load PDF::FacturX::XML");
use_ok('PDF::FacturX::Embed')  or BAIL_OUT("cannot load PDF::FacturX::Embed");
