#!/usr/bin/perl
use strict;
use warnings;
use Plucene::Document::DateSerializer;
use Test::More tests => 2;
use Time::Piece;

my $tp = Time::Piece->new(746492400);
my $s  = freeze_date($tp);
is($s, "09ixmau80", "Date freezes OK");
my $tp2 = Plucene::Document::DateSerializer::thaw_date($s);
is($tp2->epoch, $tp->epoch, "Date thaws OK");
