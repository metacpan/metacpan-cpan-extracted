# $Id: 00-load.t,v 1.2 2008/01/27 19:14:37 asc Exp $
# -*-perl-*-

use strict;
use Test::More;

plan tests => 4;

use_ok("Net::Flickr::Geo");
use_ok("Net::Flickr::Geo::YahooMaps");
use_ok("Net::Flickr::Geo::ModestMaps");
use_ok("Net::Flickr::Geo::Pinwin");