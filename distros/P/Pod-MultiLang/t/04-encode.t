#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/04-encode.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/t/04-encode.t 218 2006-11-15T10:22:38.949735Z hio  $
# -----------------------------------------------------------------------------
use strict;
use Test::More;
BEGIN { plan tests => 50 }
use lib "t";
BEGIN{ require "textio.PL" };

use Pod::MultiLang::Pod;
use Pod::MultiLang::Html;

&test01_basic;

# -----------------------------------------------------------------------------
# test01_basic.
#
sub test01_basic
{
	my %text = (
		utf8  => pack("H*",join('',qw(e3 81 a6 e3 81 99 e3 81 a8))),
		eucjp => pack("H*",join('',qw(a4 c6 a4 b9 a4 c8))),
		cp932 => pack("H*",join('',qw(82 c4 82 b7 82 c6))),
		jis   => pack("H*",join('',qw(1b 24 42 24 46 24 39 24 48 1b 28 42))),
	);
	$text{''} = $text{utf8};
	
	foreach my $ix (keys %text)
	{
		foreach my $ox (keys %text)
		{
			my $opts = {};
			$ix and $opts->{in_charset}  = $ix;
			$ox and $opts->{out_charset} = $ox;
			my $in  = $text{$ix||'utf8'};
			my $out = $text{$ox||'utf8'};
			my $iname = $ix || '(default)';
			my $oname = $ox || '(default)';
			is( to_pod($opts, $in), $out."\n", "[basic] $iname to $oname (pod)");
			is( to_html($opts, $in), $out, "[basic] $iname to $oname (html)");
		}
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

