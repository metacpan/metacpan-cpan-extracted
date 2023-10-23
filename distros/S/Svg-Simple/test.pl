#!/usr/bin/perl -I/home/phil/perl/cpan/SvgSimple/lib/
#-------------------------------------------------------------------------------
# Test Svg::Simple
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Svg::Simple;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Test::More tests => 2;

my $s = Svg::Simple::new();
$s->text(x=>10, y=>10, font_size=>4,
  cdata             =>"Hello World",
  text_anchor       =>"middle",
  alignment_baseline=>"middle",
  font_size         =>"20",
  font_family       =>"Arial",
  fill              =>"black");
$s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent");
ok $s->print =~ m(text);
ok $s->print =~ m(circle);
