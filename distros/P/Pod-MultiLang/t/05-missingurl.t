#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
#  t/05-missingurl.t
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2004 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/t/05-missingurl.t 578 2007-12-14T05:15:38.051888Z hio  $
# -----------------------------------------------------------------------------
use strict;
use Test::More tests => 2 + 2;
use lib "t";
require "textio.PL";

use Pod::MultiLang::Html;

test_basic(); # 2
test_url();   # 2

# -----------------------------------------------------------------------------
# test_basic.
#
sub test_basic
{
  my $parser = Pod::MultiLang::Html->new
  (
    langs => [qw(ja en)],
    missing_dir => '.'
  );
  
  my $ofh = TextWriter->new();
  local($Pod::MultiLang::Html::VERBOSE_DEFAULT) = Pod::MultiLang::Html::VERBOSE_ERROR;
  $parser->parse_from_filehandle(TextReader->new(<<EOF),$ofh);
=pod

L<MissingDocument>
EOF
  
  my $o = $ofh->get();
  ok($o, "[basic] parsed");

  my $link_exp = "./MissingDocument.html";
  my ($link_got) = $o =~ m{<a href="(.*?)">MissingDocument</a>}g;
  is($link_got, $link_exp, "[basic] link is $link_exp");
}

# -----------------------------------------------------------------------------
# test_url.
#
sub test_url
{
  my $parser = Pod::MultiLang::Html->new
  (
    langs => [qw(ja en)],
    missing_dir => 'http://localhost/',
  );
  
  my $ofh = TextWriter->new();
  local($Pod::MultiLang::Html::VERBOSE_DEFAULT) = Pod::MultiLang::Html::VERBOSE_ERROR;
  $parser->parse_from_filehandle(TextReader->new(<<EOF),$ofh);
=pod

L<MissingDocument>
EOF
  
  my $o = $ofh->get();
  ok($o, "[url] parsed");

  my $link_exp = "http://localhost/MissingDocument.html";
  my ($link_got) = $o =~ m{<a href="(.*?)">MissingDocument</a>}g;
  is($link_got, $link_exp, "[url] link is $link_exp");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
