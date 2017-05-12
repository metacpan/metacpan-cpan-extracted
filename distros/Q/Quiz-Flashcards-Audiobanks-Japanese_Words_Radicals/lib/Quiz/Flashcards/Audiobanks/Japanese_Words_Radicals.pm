package Quiz::Flashcards::Audiobanks::Japanese_Words_Radicals;

use warnings;
use strict;

=head1 NAME

Quiz::Flashcards::Audiobanks::Japanese_Words_Radicals - Sound files of japanese words for use with L<Quiz::Flashcards>, includes only radicals

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module will install wav files containing words spoken by japanese people into your system's distribution share directory. Flashcard sets can then play these files when required.

=head1 SYNOPSIS

This module is used by L<Quiz::Flashcards> and not on its own. Refer to the source code of L<Quiz::Flashcards> for examples on how to access it.

=head1 FUNCTIONS

=head2 get_content_list

Exports an array with the names of the contained files. The filenames can be used with L<File::Spec>'s C<catfile> and L<File::ShareDir>'s C<distdir> to locate the exact path to the files.

=cut

sub get_content_list {
    return qw(
      akubi.wav    gen.wav    kan.wav      kyou.wav   samurai.wav  tani.wav
      ama.wav      hachi.wav  kane.wav     kyuu.wav   san.wav      tatsu.wav
      ame.wav      hairi.wav  kara.wav     mame.wav   sara.wav     tei.wav
      amime.wav    han.wav    kata.wav     mata.wav   sato.wav     teki.wav
      ana.wav      hatsu.wav  katana.wav   men.wav    sei.wav      ten.wav
      ao.wav       hiki.wav   kawa.wav     mimi.wav   seki.wav     tetsu.wav
      ashi.wav     hito.wav   kawara.wav   moku.wav   sen.wav      tou.wav
      bai.wav      hoko.wav   kei.wav      mon.wav    setsu.wav    tsuchi.wav
      baku.wav     hou.wav    ketsu.wav    mushi.wav  shika.wav    tsuki.wav
      beki.wav     hyou.wav   kibi.wav     nichi.wav  shimesu.wav  tsume.wav
      ben.wav      ichi.wav   kigamae.wav  niku.wav   shin.wav     uri.wav
      boku.wav     ii.wav     kin.wav      nishi.wav  shiro.wav    ushi.wav
      bou.wav      inu.wav    kokoro.wav   oiru.wav   shita.wav    usu.wav
      bun.wav      iro.wav    koku.wav     ono.wav    shoku.wav    yaku.wav
      chaku.wav    ishi.wav   kome.wav     oo.wav     shou.wav     yoku.wav
      chichi.wav   itaru.wav  kon.wav      oto.wav    shuu.wav     you.wav
      chikara.wav  ito.wav    kotsu.wav    otsu.wav   somuku.wav   yumi.wav
      daku.wav     jin.wav    kou.wav      ou.wav     sou.wav      yuu.wav
      fude.wav     kado.wav   kuchi.wav    rai.wav    sui.wav
      fuu.wav      kagu.wav   kuro.wav     roku.wav   sun.wav
      fuyu.wav     kaku.wav   kuruma.wav   ryuu.wav   tai.wav
      gatsu.wav    kame.wav   kusa.wav     sai.wav    take.wav
    );
}

=head1 AUTHOR

Christian Walde, C<< <mithaldu at yahoo.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Quiz-flashcards-audiobanks-japanese_words_radicals at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quiz-Flashcards-Audiobanks-Japanese_Words_Radicals>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

Please refer to L<Quiz::Flashcards> for further information.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christian Walde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Quiz::Flashcards::Audiobanks::Japanese_Words_Radicals
