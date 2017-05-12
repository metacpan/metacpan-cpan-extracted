#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/02-escape.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/t/02-escape.t 218 2006-11-15T10:22:38.949735Z hio  $
# -----------------------------------------------------------------------------
use strict;
use Test::More;
BEGIN { plan tests => 13 }
use lib "t";
BEGIN{ require "textio.PL" };

use Pod::MultiLang::Html;

&test01_escapes;

# -----------------------------------------------------------------------------
# test01_escapes.
#
sub test01_escapes
{
	# http://search.cpan.org/~nwclark/perl-5.8.8/pod/perlpod.pod#E<escape>_--_a_character_escape____
	is( to_html("text"),      "text",     "plain text");
	is( to_html("E<lt>"),     "&lt;",     "E<lt>");
	is( to_html("E<gt>"),     "&gt;",     "E<gt>");
	is( to_html("E<verbar>"), "|",        "E<verbar>");
	is( to_html("E<sol>"),    "/",        "E<sol>");
	is( to_html("E<eacute>"), "&eacute;", "E<eacute>");
	is( to_html("E<0x201E>"), "&#x201E;", "E<0x201E>");
	is( to_html("E<075>"),    "&#61;",    "E<075>");
	is( to_html("E<181>"),    "&#181;",   "E<181>");
	
	is( to_html("E<amp>"),  "&amp;",   "E<amp>");
	is( to_html("E<39>"),   "&#39;",   "E<39> (decimal)");
	is( to_html("E<040>"),  "&#32;",   "E<040> (octal)");
	is( to_html("E<0xf6>"), "&#xf6;",  "E<0xf6> (hex)");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
