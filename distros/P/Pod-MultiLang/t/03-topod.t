#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/03-topod.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/t/03-topod.t 218 2006-11-15T10:22:38.949735Z hio  $
# -----------------------------------------------------------------------------
use strict;
use Test::More;
BEGIN { plan tests => 9 }
use lib "t";
require "textio.PL";

use Pod::MultiLang::Pod;

&test01_basic;
&test02_command;

# -----------------------------------------------------------------------------
# test01_basic.
#
sub test01_basic
{
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[basic] extract default");
	X english.
	X J<< ja; japanese. >>
INPUT
	X english.
EXPECTED
	
	is( to_pod({langs=>'ja'}, <<INPUT), text(<<EXPECTED), "[basic] extract ja");
	X english.
	X J<< ja; japanese. >>
INPUT
	X japanese.
EXPECTED
}

# -----------------------------------------------------------------------------
# test02_command.
#
sub test02_command
{
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =encoding");
	X =pod
	X
	X pod.
	X 
INPUT
	X =pod
	X
	X pod.
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =encoding");
	X =encoding utf8
INPUT
	X =encoding utf8
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] some commands");
	X =encoding utf8
	X
	X =head1 aaa
	X
	X =head2 bbb
INPUT
	X =encoding utf8
	X
	X =head1 aaa
	X
	X =head2 bbb
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =for format");
	X =for stopwords a b c
INPUT
	X =for stopwords a b c
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =for :format");
	X =for :stopwords
	X virtE<ugrave>
INPUT
	X =for :stopwords
	X virtE<ugrave>
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =begin format/=end format");
	X =begin stopwords
	X
	X x
	X
	X y z
	X
	X =end stopwords
INPUT
	X =begin stopwords
	X
	X x
	X
	X y z
	X
	X =end stopwords
EXPECTED
	
	is( to_pod({}, <<INPUT), text(<<EXPECTED), "[command] keep =begin :format/=end :format");
	X =begin :stopwords
	X
	X X
	X
	X Y Z
	X
	X virtE<ugrave>
	X
	X =end :stopwords
INPUT
	X =begin :stopwords
	X
	X X
	X
	X Y Z
	X
	X virtE<ugrave>
	X
	X =end :stopwords
EXPECTED
	
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

