#!perl

use strict;
use warnings;
use Test::More tests => 22;
use Test::Differences;
use Pod::Advent;

is( $Pod::Advent::VERSION, '0.24', 'got VERSION' );
is( $Pod::Advent::section, '', 'got section' );
is_deeply( \@Pod::Advent::mode, [], 'got mode' );
is_deeply( \%Pod::Advent::M_values_seen, {}, 'got M_values_seen' );
is( $Pod::Advent::BODY_ONLY, '0', 'got BODY_ONLY' );

SKIP: {
  skip "Text::Aspell is not installed", 1 unless eval { $INC{'Text/Aspell.pm'} && Text::Aspell->can('new') };
  isa_ok( $Pod::Advent::speller, 'Text::Aspell', "got speller" );
}

is_deeply( \@Pod::Advent::misspelled, [], 'got misspelled' );

my $h;

$h = \%Pod::Advent::data;
eq_or_diff( [sort keys %$h], [qw/author body css_url day file isAdvent title year/], 'got data keys' );
is( $h->{title}, undef, 'got data.title' );
is( $h->{author}, undef, 'got data.author' );
is( $h->{year}, (localtime)[5]+1900, 'got data.year' );
is( $h->{day}, 0, 'got data.day' );
is( $h->{body}, '', 'got data.body' );
is( $h->{file}, undef, 'got data.file' );
is( $h->{css_url}, '../style.css', 'got data.css_url' );
is( $h->{isAdvent}, 1, 'got data.isAdvent' );

$h = \%Pod::Advent::blocks;
is_deeply( [sort keys %$h], [qw/code codeNNN pre sourced_desc sourced_file/], 'got blocks keys' );
is( $h->{code}, '', 'got blocks.code' );
is( $h->{codeNNN}, '', 'got blocks.codeNNN' );
is( $h->{pre}, '', 'got blocks.pre' );
is( $h->{sourced_file}, '', 'got blocks.sourced_file' );
is( $h->{sourced_desc}, '', 'got blocks.sourced_desc' );

