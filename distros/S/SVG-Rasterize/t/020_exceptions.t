#!perl -T
use strict;
use warnings;

use Test::More tests => 91;
use Test::Warn;

use SVG;
use Test::Exception;
use SVG::Rasterize::Exception;

is(scalar(@SVG::Rasterize::Exception::EXPORT)
   + scalar(@SVG::Rasterize::Exception::EXPORT_OK),
   30, 'number of exceptions');
foreach(@SVG::Rasterize::Exception::EXPORT,
	@SVG::Rasterize::Exception::EXPORT_OK)
{
    warning_is { eval "&SVG::Rasterize::Exception::$_" } undef,
        "no warning in $_ without arguments";
    ok(defined($@), 'exception has been thrown');
    isa_ok($@, 'SVG::Rasterize::Exception::Base');
}

