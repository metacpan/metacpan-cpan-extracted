#!/usr/local/bin/perl
# $Id: /mirror/monster/Template-Plugin-Shuffle/trunk/t/01_shuffle.t 874 2003-04-18T07:38:40.000000Z miyagawa  $
#
# Tatsuhiko Miyagawa <miyagawa@edge.jp>
# EDGE, Co.,Ltd.
#

use strict;
use Test::More tests => 1;
use Template;

my $tt = Template->new;
my @list = qw(a b c);

$tt->process(\<<EOF, { list => \@list }, \my $out) or die $tt->error;
[% USE Shuffle %]
[% FOREACH item = list.shuffle -%]
[% item %]
[%- END %]
EOF

like $out, qr/(a|b|c){3}/, $out;





