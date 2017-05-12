use strict;
use warnings;
package Religion::Bible::Reference::Standard;
# ABSTRACT: standard bible books and abbreviations
$Religion::Bible::Reference::Standard::VERSION = '0.016';
#pod =head1 DESCRIPTION
#pod
#pod This module is a package of book descriptions and abbreviations for use with
#pod Religion::Bible::Reference.  It is loaded by that module by default.
#pod
#pod =cut

my @books = (
  'Genesis' => {
    short => 'Gen',
    abbreviations => [ qw(ge gen) ],
    verses  => [ qw( 
    31 25 24 26 32 22 24 22 29 32 32 20 18 24 21 16 27 33 38 18 34 24 20 67 34
    35 46 22 35 43 55 32 20 31 29 43 36 30 23 23 57 38 34 34 28 34 31 22 33 26
    )],
  },
  'Exodus' => {
    short => 'Ex',
    abbreviations => [ qw(ex exo exod) ],
    verses  => [ qw( 
    22 25 22 31 23 30 25 32 35 29 10 51 22 31 27 36 16 27 25 26
    36 31 33 18 40 37 21 43 46 38 18 35 23 35 35 38 29 31 43 38
    )],
  },
  'Leviticus' => {
    short => 'Lev',
    abbreviations => [ qw(le lev) ],
    verses  => [ qw( 
    17 16 17 35 19 30 38 36 24 20 47 08 59 57
    33 34 16 30 37 27 24 33 44 23 55 46 34
    )],
  },
  'Numbers' => {
    short => 'Num',
    abbreviations => [ qw(nu num) ],
    verses  => [ qw( 
    54 34 51 49 31 27 89 26 23 36 35 16 33 45 41 50 13 32
    22 29 35 41 30 25 18 65 23 31 40 16 54 42 56 29 34 13
    )],
  },
  'Deuteronomy' => {
    short => 'Deut',
    abbreviations => [ qw(de dt deu deut) ],
    verses  => [ qw( 
    46 37 29 49 33 25 26 20 29 22 32 32 18 29 23 22 20
    22 21 20 23 30 25 22 19 19 26 68 29 20 30 52 29 12
    )],
  },
  'Joshua' => {
    short => 'Josh',
    abbreviations => [ qw(jos josh) ],
    verses  => [ qw( 
    18 24 17 24 15 27 26 35 27 43 23 24 33 15 63 10 18 28 51 09 45 34 16 33
    )],
  },
  'Judges' => {
    short => 'Judg',
    abbreviations => [ qw(judg jdg) ],
    verses  => [ qw( 
    36 23 31 24 31 40 25 35 57 18 40 15 25 20 20 31 13 31 30 48 25
    )],
  },
  'Ruth' => {
    short => 'Ruth',
    abbreviations => [ qw(ru rut) ],
    verses  => [ qw( 22 23 18 22 )],
  },
  '1 Samuel' => {
    short => '1 Sam',
    abbreviations => [ qr/\A1 ?Sam?\Z/i ],
    verses  => [ qw(
    28 36 21 22 12 21 17 22 27 27 15 25 23 52 35 23
    58 30 24 42 15 23 29 22 44 25 12 25 11 31 13
    )],
  },
  '2 Samuel' => {
    short => '2 Sam',
    abbreviations => [ qr/\A2 ?Sam?\Z/i ],
    verses  => [ qw(
    27 32 39 12 25 23 29 18 13 19 27 31 39 33 37 23 29 33 43 26 22 51 39 25 
    )],
  },
  '1 Kings' => {
    short => '1 Ki',
    abbreviations => [ qr/\A1 ?K(?:i|gs)\Z/i ],
    verses  => [ qw(
    53 46 28 34 18 38 51 66 28 29 43 33 34 31 34 34 24 46 21 43 29 53
    )],
  },
  '2 Kings' => {
    short => '2 Ki',
    abbreviations => [ qr/\A2 ?K(?:i|gs)\Z/i ],
    verses  => [ qw(
    18 25 27 44 27 33 20 29 37 36 21 21 25 29 38 20 41 37 37 21 26 20 37 20 30
    )],
  },
  '1 Chronicles' => {
    short => '1 Chr',
    abbreviations => [ qr/\A1 ?Ch(?:r(?:on)?)?\Z/i ],
    verses  => [ qw(
    54 55 24 43 26 81 40 40 44 14 47 40 14 17 29
    43 27 17 19 08 30 19 32 31 31 32 34 21 30
    )],
  },
  '2 Chronicles' => {
    short => '2 Chr',
    abbreviations => [ qr/\A2 ?Ch(?:r(?:on)?)?\Z/i ],
    verses  => [ qw(
    17 18 17 22 14 42 22 18 31 19 23 16 22 15 19 14 19 34
    11 37 20 12 21 27 28 23 09 27 36 27 21 33 25 33 27 23
    )],
  },
  'Ezra' => {
    short => 'Ezra',
    abbreviations => [ qw(ezr) ],
    verses  => [ qw( 11 70 13 24 17 22 28 36 15 44 )],
  },
  'Nehemiah' => {
    short => 'Neh',
    abbreviations => [ qw(ne neh) ],
    verses  => [ qw( 11 20 32 23 19 19 73 18 38 39 36 47 31 )],
  },
  'Esther' => {
    short => 'Esth',
    abbreviations => [ qw(est esth) ],
    verses  => [ qw( 22 23 15 17 14 14 10 17 32 03 )],
  },
  'Job' => {
    short => 'Job',
    abbreviations => [ ],
    verses  => [ qw( 
    22 13 26 21 27 30 21 22 35 22 20 25 28 22 35 22 16 21 29 29 34
    30 17 25 06 14 23 28 25 31 40 22 33 37 16 33 24 41 30 24 34 17
    )],
  },
  'Psalms' => {
    short => 'Ps',
    abbreviations => [ qw(ps psalm psa pss) ],
    verses  => [ qw( 
    06 12 08 08 12 10 17 09 20 18 07 08 06 07 05 11 15 50 14 09 13 31 06 10 22
    12 14 09 11 12 24 11 22 22 28 12 40 22 13 17 13 11 05 26 17 11 09 14 20 23
    19 09 06 07 23 13 11 11 17 12 08 12 11 10 13 20 07 35 36 05 24 20 28 23 10
    12 20 72 13 19 16 08 18 12 13 17 07 18 52 17 16 15 05 23 11 13 12 09 09 05
    08 28 22 35 45 48 43 31 31 07 10 10 09 08 18 19 02 29   176 07 08 09 04 08
    05 06 05 06 08 08 03 18 03 03 21 26 09 08 24 13 10 07 12 15 21 10 20 14 09
    06
    )],
  },
  'Proverbs' => {
    short => 'Prov',
    abbreviations => [ qw(pro prov) ],
    verses  => [ qw( 
    33 22 35 27 23 35 27 36 18 32 31 28 25 35 33 33
    28 24 29 30 31 29 35 34 28 28 27 28 27 33 31
    )],
  },
  'Ecclesiastes' => {
    short => 'Ecc',
    abbreviations => [ qw(ecc eccl qoh) ],
    verses  => [ qw( 18 26 22 16 20 12 29 17 18 20 10 14 )],
  },
  'Song of Solomon' => {
    short => 'Song',
    abbreviations => [ qr(ss so song sos cant canticles), "song of songs" ],
    verses  => [ qw( 17 17 11 16 16 13 13 14 )],
  },
  'Isaiah' => {
    short => 'Is',
    abbreviations => [ qw(is isa) ],
    verses  => [ qw(
    31 22 26 06 30 13 25 22 21 34 16 06 22 32 09 14 14 07 25 06 21 25
    18 23 12 21 13 29 24 33 09 20 24 17 10 22 38 22 08 31 29 25 28 28
    25 13 15 22 26 11 23 15 12 17 13 12 21 14 21 22 11 12 19 12 25 24
    )],
  },
  'Jeremiah' => {
    short => 'Jer',
    abbreviations => [ 'jer' ],
    verses  => [ qw( 
    19 37 25 31 31 30 34 22 26 25 23 17 27 22 21 21 27
    23 15 18 14 30 40 10 38 24 22 17 32 24 40 44 26 22
    19 32 21 28 18 16 18 22 13 30 05 28 07 47 39 46 64 34
    )],
  },
  'Lamentations' => {
    short => 'Lam',
    abbreviations => [ qw(la lam) ],
    verses  => [ qw( 22 22 66 22 22 )],
  },
  'Ezekiel' => {
    short => 'Ezek',
    abbreviations => [ qw(eze ezek) ],
    verses  => [ qw( 
    28 10 27 17 17 14 27 18 11 22 25 28 23 23 08 63 24 32 14 49 32 31 49 27
    17 21 36 26 21 26 18 32 33 31 15 38 28 23 29 49 26 20 27 31 25 24 23 35 
    )],
  },
  'Daniel' => {
    short => 'Dan',
    abbreviations => [ qw(da dan) ],
    verses  => [ qw( 21 49 30 37 31 28 28 27 27 21 45 13 )],
  },
  'Hosea' => {
    short => 'Hos',
    abbreviations => [ qw(ho hos) ],
    verses  => [ qw( 11 23 05 19 15 11 16 14 17 15 12 14 16 09 )],
  },
  'Joel' => {
    short => 'Joel',
    abbreviations => [ ],
    verses  => [ qw( 20 32 21 )],
  },
  'Amos' => {
    short => 'Amos',
    abbreviations => [ qw(am amo) ],
    verses  => [ qw( 15 16 15 13 27 14 17 14 15 )],
  },
  'Obadiah' => {
    short => 'Obad',
    abbreviations => [ qw(ob obad oba) ],
    verses  => [ qw( 21 )],
  },
  'Jonah' => {
    short => 'Jon',
    abbreviations => [ 'jon' ],
    verses  => [ qw( 17 10 10 11 )],
  },
  'Micah' => {
    short => 'Micah',
    abbreviations => [ 'mic' ],
    verses  => [ qw( 16 13 12 13 15 16 20 )],
  },
  'Nahum' => {
    short => 'Nahum',
    abbreviations => [ qw(na nah) ],
    verses  => [ qw( 15 13 19 )],
  },
  'Habakkuk' => {
    short => 'Hab',
    abbreviations => [ 'hab' ],
    verses  => [ qw( 17 20 19 )],
  },
  'Zephaniah' => {
    short => 'Zeph',
    abbreviations => [ qw(zep zeph) ],
    verses  => [ qw( 18 15 20 )],
  },
  'Haggai' => {
    short => 'Hag',
    abbreviations => [ 'hag' ],
    verses  => [ qw( 15 23 )],
  },
  'Zechariah' => {
    short => 'Zec',
    abbreviations => [ qw(zec zech) ],
    verses  => [ qw( 21 13 10 14 11 15 14 23 17 12 17 14 09 21 )],
  },
  'Malachi' => {
    short => 'Mal',
    abbreviations => [ 'mal' ],
    verses  => [ qw( 14 17 18 06 )],
  },
  # New Testament
  'Matthew' => {
    short => 'Mt',
    abbreviations => [ qr/\A(?:st\.\s*)?m(?:at)?t?\Z/i ],
    verses  => [ qw(
    25 23 17 25 48 34 29 34 38 42 30 50 58 36
    39 28 27 35 30 34 46 46 39 51 46 75 66 20
    )],
  },
  'Mark' => {
    short => 'Mk',
    abbreviations => [ qr/\A(?:st\.\s*)?m(?:ar)?k?\Z/i ],
    verses  => [ qw( 45 28 35 41 43 56 37 38 50 52 33 44 37 72 47 20)],
  },
  'Luke' => {
    short => 'Lk',
    abbreviations => [ qr/\A(?:st\.\s*)?lu?ke?\Z/i     ],
    verses  => [ qw(
    80 52 38 44 39 49 50 56 62 42 54 59
    35 35 32 31 37 43 48 47 38 71 56 53
    )],
  },
  'John' => {
    short => 'Jn',
    abbreviations => [ qr/\A(?:st\.\s*)?j(?:oh)?n?\Z/i ],
    verses  => [ qw(
    51 25 36 54 47 71 53 59 41 42 57 50 38 31 27 33 26 40 42 31 25
    )],
  },
  'Acts' => {
    short => 'Acts',
    abbreviations => [ qw(ac act) ],
    verses  => [ qw(
    26 47 26 37 42 15 60 40 43 48 30 25 52 28
    41 40 34 28 41 38 40 30 35 27 27 32 44 31
    )],
  },
  'Romans' => {
    short => 'Rom',
    abbreviations => [ qw(ro rom) ],
    verses  => [ qw(32 29 31 25 21 23 25 39 33 21 36 21 14 23 33 27)],
  },
  '1 Corinthians' => {
    short => '1 Cor',
    abbreviations => [ qr/\A1 ?Co(?:r|rinth)?\Z/i ],
    verses  => [ qw(31 16 23 21 13 20 40 13 27 33 34 31 13 40 58 24) ],
  },
  '2 Corinthians' => {
    short => '2 Cor',
    abbreviations => [ qr/\A2 ?Co(?:r|rinth)?\Z/i ],
    verses  => [ qw(24 17 18 18 21 18 16 24 15 18 33 21 14) ],
  },
  'Galatians' => {
    short => 'Gal',
    abbreviations => [ qw(ga gal) ],
    verses  => [ qw(24 21 29 31 26 18) ],
  },
  'Ephesians' => {
    short => 'Eph',
    abbreviations => [ qw(ep eph) ],
    verses  => [ qw(23 22 21 32 33 24) ],
  },
  'Philippians' => {
    short => 'Phi',
    abbreviations => [ qw(php phil) ],
    verses  => [ qw(30 30 21 23) ],
  },
  'Colossians' => {
    short => 'Col',
    abbreviations => [ qw(co col) ],
    verses  => [ qw(29 23 25 18) ],
  },
  '1 Thessalonians' => {
    short => '1 Th',
    abbreviations => [ qr/\A1 ?Th(?:ess(?:allonians)?)?\Z/i ],
    verses  => [ qw(10 20 13 18 28) ],
  },
  '2 Thessalonians' => {
    short => '2 Th',
    abbreviations => [ qr/\A2 ?Th(?:ess(?:allonians)?)?\Z/i ],
    verses  => [ qw(12 17 18) ],
  },
  '1 Timothy' => {
    short => '1 Tim',
    abbreviations => [ qr/\A1 ?Ti(?:m|mothy)?\Z/i ],
    verses  => [ qw(20 15 16 16 25 21) ],
  },
  '2 Timothy' => {
    short => '2 Tim',
    abbreviations => [ qr/\A2 ?Ti(?:m|mothy)?\Z/i ],
    verses  => [ qw(18 26 17 22) ],
  },
  'Titus' => {
    short => 'Tit',
    abbreviations => [ 'tit' ],
    verses  => [ qw(16 15 15) ],
  },
  'Philemon' => {
    short => 'Phm',
    abbreviations => [ qw(phm philem) ],
    verses  => [ 25 ],
  },
  'Hebrews' => {
    short => 'Heb',
    abbreviations => [ 'heb' ],
    verses  => [ qw(14 18 19 16 14 20 28 13 28 39 40 29 25) ],
  },
  'James' => {
    short => 'Jas',
    abbreviations => [ 'jas' ],
    verses  => [ qw(27 26 18 17 20) ],
  },
  '1 Peter' => {
    short => '1 Pe',
    abbreviations => [ qr/\A1 ?Pe(?:t(?:er)?)?\Z/i ],
    verses  => [ qw(25 25 22 19 14) ],
  },
  '2 Peter' => {
    short => '2 Pe',
    abbreviations => [ qr/\A2 ?Pe(?:t(?:er)?)?\Z/i ],
    verses  => [ qw(21 22 18) ],
  },
  '1 John' => {
    short => '1 Jn',
    abbreviations => [ qr/\A1 ?J(?:oh)?n\Z/i ],
    verses  => [ qw(10 29 24 21 21)],
  },
  '2 John' => {
    short => '2 Jn',
    abbreviations => [ qr/\A2 ?J(?:oh)?n\Z/i ],
    verses  => [ 13 ],
  },
  '3 John' => {
    short => '3 Jn',
    abbreviations => [ qr/\A3 ?J(?:oh)?n\Z/i ],
    verses  => [ 15 ],
  },
  'Jude' => {
    short => 'Jude',
    abbreviations => [ 'jud' ],
    verses  => [ 25 ],
  },
  'Revelation' => {
    short => 'Rev',
    abbreviations => [ qw(re rev apoc apocalypse) ],
    verses  => [ qw(
    20 29 22 11 14 17 17 13 21 11 19 17 18 20 08 21 18 24 21 15 27 21
    )],
  },
);

sub _books {
  my @_books;
  for (my $i = 0; $i < @books; $i++) {
    next unless $i % 2;
    my $book = { %{ $books[ $i ] } };
    $book->{full} = $books[ $i - 1 ];
    push @_books, $book;
  }

  return @_books;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Religion::Bible::Reference::Standard - standard bible books and abbreviations

=head1 VERSION

version 0.016

=head1 DESCRIPTION

This module is a package of book descriptions and abbreviations for use with
Religion::Bible::Reference.  It is loaded by that module by default.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
