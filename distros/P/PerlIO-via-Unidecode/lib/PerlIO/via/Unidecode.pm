
require 5.008;
package PerlIO::via::Unidecode;
#  Last-Modified Time-stamp: "2014-07-27 02:49:16 MDT sburke@cpan.org"
$VERSION = "1.02";
use strict;
use utf8 ('decode');
use Text::Unidecode ('unidecode');
# A little sanity-checking can't hurt:
die "Can't find &Text::Unidecode::unidecode" unless defined &unidecode;
die "Can't find &utf8::decode" unless defined &utf8::decode;

# Coded based on the example of PerlIO::via::QuotedPrint.

sub PUSHED { bless \*PUSHED,$_[0] }

sub FILL {
    my $line = readline( $_[1] );
    (defined $line) ? unidecode( $line ) : undef;
}

sub WRITE {
    my $x = $_[1];
    utf8::decode($x); # need to promote things back to UTF8
    unidecode($x);
    # utf8::downgrade($x);
    ( print {$_[2]} $x ) ? length($_[1]) : -1;
}

1;
__END__

=encoding utf8

=head1 NAME

PerlIO::via::Unidecode - a perlio layer for Unidecode

=head1 SYNOPSIS

  # An example program using the perlio layer:

  % cat utf8translit
  #!/usr/bin/perl
  use strict;
  use PerlIO::via::Unidecode;
  foreach my $fs (@ARGV) {
    open( my $IN,
      '<:encoding(utf8):via(Unidecode)', # the layers
      $fs
     ) or die "$f -> $!\n";
    print while <$IN>;
    close($IN);
  }
  __END__

  # We're feeding it this file, which is the Chinese
  # characters for Beijing (in UTF8)

  % od -x home_city.txt
  000000:  E5 8C 97 E4 BA B0 0D 0A

  So:

  % utf8translit home_city.txt
  Bei Jing

=head1 DESCRIPTION

PerlIO::via::Unidecode implements a L<PerlIO::via> layer that applies Unidecode
(L<Text::Unidecode>) to data passed through it.

You can use PerlIO::via::Unidecode on already-Unicode data, as in the
example in the SYNOPSIS; or you can combine it with other layers, as in
this little program that converts KOI8R text into Unicode and then
feeds it to Unidecode, which then outputs an ASCII transliteration:

  % cat transkoi8r
  #!/usr/bin/perl
  use strict;
  use PerlIO::via::Unidecode;
  foreach my $filespec (@ARGV) {
    open(          # Three-argument open is always great
      my $IN,
      '<:encoding(koi8-r):via(Unidecode)',  # the layers
      $filespec ) or die $!;

    print while <$IN>;
    close($IN);
  }
  __END__

  % cat fet_koi8r.txt
  
  ëÏÇÄÁ ÞÉÔÁÌÁ ÔÙ ÍÕÞÉÔÅÌØÎÙÅ ÓÔÒÏËÉ,
  çÄÅ ÓÅÒÄÃÁ Ú×ÕÞÎÙÊ ÐÙÌ ÓÉÑÎØÅ ÌØÅÔ ËÒÕÇÏÍ
  é ÓÔÒÁÓÔÉ ÒÏËÏ×ÏÊ ×ÚÄÙÍÁÀÔÓÑ ÐÏÔÏËÉ,-
        îÅ ×ÓÐÏÍÎÉÌÁ ÌØ Ï ÞÅÍ?

  % transkoi8r fet_koi8r.txt

  Koghda chitala ty muchitiel'nyie stroki,
  Gdie sierdtsa zvuchnyi pyl siian'ie l'iet krughom
  I strasti rokovoi vzdymaiutsia potoki,-
      Nie vspomnila l' o chiem?

Of course, you could do this all by manually calling Text::Unidecode's
C<unidecode(...)> function on every line you fetch, but that's just what
C<:via(...)> layers do automatically do for you.

Note that you can also use C<:via(Unidecode)> as an output layer too.
In that case, add a dummy ":utf8" after it, as below, just to silence
some "wide character in print" warnings that you might otherwise
see.

  % cat writebei.pl
  use PerlIO::via::Unidecode;
  open(
    my $OUT,
    ">:via(Unidecode):utf8",  # the layers
    "roman_bei.txt"
   ) or die $!;
  print $OUT "\x{5317}\x{4EB0}\n";
    # those are the Chinese characters for Beijing
  close($OUT);

  % perl writebei.pl
  
  % cat roman_bei.txt
  Bei Jing 

=head1 FUNCTIONS AND METHODS

This module provides no public functions or methods —
everything is done thru the C<via> interface.  If you want a function,
see L<Text::Unidecode>.

=head1 TIPS

Don't forget the "use PerlIO::via::Unidecode;" line, and be sure to
get the case right.

Don't type "Unicode" when you mean "Unidecode", nor vice versa.

Handy layer-modes to remember:

  <:encoding(utf8):via(Unidecode)
  <:encoding(some-other-encoding):via(Unidecode)
  >:via(Unidecode):utf8

=head1 SEE ALSO

L<Text::Unidecode>

L<PerlIO::via>

L<Encode> and L<Encode::Supported> (even though the modes they
implement are called as "C<:encodI<ing>(...)>").

L<PerlIO::via::PinyinConvert>

L<perlunitut> and L<perlunicode>

L<https://en.wikipedia.org/wiki/Afanasy_Fet>

=head1 NOTES

Note that if Unidecode's transliteration of something changes, so will
its effect on C<:via(Unidecode)>.  So the first word of the
above text is "Koghda" from one particular version of Unidecode, and
"Kogda" from another.

Thanks for Jarkko Hietaniemi for help with this module and many
other things besides.

=head1 THE POEM

In the first release of this module, I forgot to give the source
of the above Russian text!  So here it is:

The Russian text is the first stanza of a poem by Afanasy Afanasevich
Fet (1822-1892).
Above I have shown only its first stanza ("Koghda chitala..."), first
in raw KOI8R, then passed through Unidecode.  But here it is, in its
entirety:

  Когда читала ты мучительные строки,
  Где сердца звучный пыл сиянье льёт кругом
  И страсти роковой вздымаются потоки,—
    Не вспомнила ль о чём?

  Я верить не хочу! Когда в степи, как диво,
  В полночной темноте безвременно горя,
  Вдали перед тобой прозрачно и красиво
    Вставала вдруг заря.

  И в эту красоту невольно взор тянуло,
  В тот величавый блеск за тёмный весь предел,—
  Ужель ничто тебе в то время не шепнуло:
    «Там человек сгорел!»


     —Афанасий Афанасьевич Фет, 15 февраля 1887


Its conventional English title is a translation of the first line,
"When you were reading those tormented lines"— which I found
rather apt for a poem about mangled encodings.

=head1 COPYRIGHT AND DISCLAIMER

With the exception of the text of the poem, this is copyright 2003,
2014, Sean M. Burke sburke@cpan.org, all rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The programs and documentation in this dist are distributed in the hope
that they will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke  sburkeE<64>cpan.org

=cut

