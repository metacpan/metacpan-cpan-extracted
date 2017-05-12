#!/usr/bin/perl

use Plucene::SearchEngine::Index;
use Test::More tests => 4;
my $hash = Plucene::SearchEngine::Index::File->examine("t/generic.png");
is($hash->{type}{data}[0], "image", "Correct type");
is($hash->{size}{data}[0], "16x16", "Stored size");
isa_ok($hash->{created}{data}[0], "Time::Piece");
is($hash->{subtype}{data}[0], "png", "Stored subtype");
