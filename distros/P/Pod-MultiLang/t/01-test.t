#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/01-test.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2004 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: 01-test.t,v 1.1 2004/08/01 04:02:51 hio Exp $
# -----------------------------------------------------------------------------
use strict;
use Test;
BEGIN { plan tests => 1 }
use lib "t";
require "textio.PL";

use Pod::MultiLang::Html;

# -----------------------------------------------------------------------------
# main.
#
&do_work;

sub do_work
{
  my $parser = Pod::MultiLang::Html->new
  (
    langs => [qw(ja en)],
  );
  
  my $ofh = TextWriter->new();
  $parser->parse_from_filehandle(TextReader->new(<<EOF),$ofh);
=head1 NAME

test - convert test 
J<< ja;test - 変換テスト >>
EOF
  
  my $o = $ofh->get();
  (my $x = $o)=~s/^/#/mg;
  #print $x;
  ok($o);
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
