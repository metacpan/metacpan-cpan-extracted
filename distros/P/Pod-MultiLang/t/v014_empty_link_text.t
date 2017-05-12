#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/v014.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2008 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/t/v014_empty_link_text.t 624 2008-02-06T09:15:55.362158Z hio  $
# -----------------------------------------------------------------------------
use strict;
use Test::More;
BEGIN { plan tests => 1 }
use lib "t";
require "textio.PL";

use Pod::MultiLang::Pod;

&test01;

# -----------------------------------------------------------------------------
# test01.
#
sub test01
{
	is( to_pod({langs=>'ja'}, <<INPUT), text(<<EXPECTED), "[basic] extract ja");
	X J<< ja; L</"ENGLISH TERM J<< ja; JAPANESE TERM >> "> >>
INPUT
	X L</JAPANESE TERM>
EXPECTED
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

