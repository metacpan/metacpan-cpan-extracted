#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use TV::ARIB::ProgramGenre qw/get_genre_name get_genre_id
                              get_parent_genre_name get_parent_genre_id/;

my $genre = get_genre_name(0, 1);
my $id    = get_genre_id('国内アニメ');

my $parent_genre    = get_parent_genre_name(1);
my $parent_genre_id = get_parent_genre_id('ドラマ');
