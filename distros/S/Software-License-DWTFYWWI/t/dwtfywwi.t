#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Software::License::DWTFYWWI;

is(scalar(Software::License::DWTFYWWI->name), "DWTFYWWI", "DWTFYWWI is called DWTFYWWI");
like(scalar(Software::License::DWTFYWWI->url), qr/github\.com/, "DWTFYWWI is hosted on GitHub");
is(scalar(Software::License::DWTFYWWI->meta_name), "unrestricted", "DWTFYWWI is unrestricted");
like(scalar(Software::License::DWTFYWWI->license), qr/whatever the fuck that may be/, "FREEDOM!");
