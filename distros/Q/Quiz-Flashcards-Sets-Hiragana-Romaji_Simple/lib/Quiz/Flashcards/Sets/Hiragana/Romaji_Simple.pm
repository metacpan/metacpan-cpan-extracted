package Quiz::Flashcards::Sets::Hiragana::Romaji_Simple;

use warnings;
use strict;
use utf8;

use base 'Exporter';

our @EXPORT = (qw( get_set ));

=head1 NAME

Quiz::Flashcards::Sets::Hiragana::Romaji_Simple - Flashcard set with the basic 46 japanese hiragana

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

This module will provide L<Quiz::Flashcards> with the data needed to test and train the reading of the 46 basic katakana of the japanese alphabet.

The characters are presented in UTF8 text, so your system will need to have compatible fonts installed. The answer is expected as keyboard input. Upon confirmation of the answer the set will attempt to play a sound of the syllable if L<Quiz::Flashcards::Audiobanks::Japanese_Syllables> is installed.

=head1 SYNOPSIS

This module is used by L<Quiz::Flashcards> and not on its own. Refer to the source code of L<Quiz::Flashcards> for examples on how to access it.

=head1 FUNCTIONS

=head2 get_set

This function returns an array of all items in this set. The items are represented as hashes with the following members: C<question>, C<answer>, C<question_type>, C<answer_type>, C<audiobank>, C<audio_file>.

=cut

=head1 AUTHOR

Christian Walde, C<< <mithaldu at yahoo.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Quiz-flashcards-sets-hiragana-romaji_simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quiz-Flashcards-Sets-Hiragana-Romaji_Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

Please refer to L<Quiz::Flashcards> for further information.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christian Walde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

my $ab = "Quiz::Flashcards::Audiobanks::Japanese_Syllables";

my @set;
push @set, { question => "あ", complexity => 1, answer => "a", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "a.wav" };
push @set, { question => "い", complexity => 1, answer => "i", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "i.wav" };
push @set, { question => "う", complexity => 1, answer => "u", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "u.wav" };
push @set, { question => "え", complexity => 1, answer => "e", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "e.wav" };
push @set, { question => "お", complexity => 1, answer => "o", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "o.wav" };
push @set, { question => "か", complexity => 2, answer => "ka", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ka.wav" };
push @set, { question => "き", complexity => 2, answer => "ki", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ki.wav" };
push @set, { question => "く", complexity => 2, answer => "ku", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ku.wav" };
push @set, { question => "け", complexity => 2, answer => "ke", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ke.wav" };
push @set, { question => "こ", complexity => 2, answer => "ko", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ko.wav" };
push @set, { question => "さ", complexity => 3, answer => "sa", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "sa.wav" };
push @set, { question => "し", complexity => 3, answer => "shi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "shi.wav" };
push @set, { question => "す", complexity => 3, answer => "su", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "su.wav" };
push @set, { question => "せ", complexity => 3, answer => "se", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "se.wav" };
push @set, { question => "そ", complexity => 3, answer => "so", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "so.wav" };
push @set, { question => "た", complexity => 4, answer => "ta", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ta.wav" };
push @set, { question => "ち", complexity => 4, answer => "chi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "chi.wav" };
push @set, { question => "つ", complexity => 4, answer => "tsu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "tsu.wav" };
push @set, { question => "て", complexity => 4, answer => "te", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "te.wav" };
push @set, { question => "と", complexity => 4, answer => "to", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "to.wav" };
push @set, { question => "な", complexity => 5, answer => "na", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "na.wav" };
push @set, { question => "に", complexity => 5, answer => "ni", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ni.wav" };
push @set, { question => "ぬ", complexity => 5, answer => "nu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "nu.wav" };
push @set, { question => "ね", complexity => 5, answer => "ne", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ne.wav" };
push @set, { question => "の", complexity => 5, answer => "no", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "no.wav" };
push @set, { question => "は", complexity => 6, answer => "ha", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ha.wav" };
push @set, { question => "ひ", complexity => 6, answer => "hi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "hi.wav" };
push @set, { question => "ふ", complexity => 6, answer => "fu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "hu.wav" };
push @set, { question => "へ", complexity => 6, answer => "he", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "he.wav" };
push @set, { question => "ほ", complexity => 6, answer => "ho", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ho.wav" };
push @set, { question => "ま", complexity => 7, answer => "ma", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ma.wav" };
push @set, { question => "み", complexity => 7, answer => "mi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mi.wav" };
push @set, { question => "む", complexity => 7, answer => "mu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mu.wav" };
push @set, { question => "め", complexity => 7, answer => "me", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "me.wav" };
push @set, { question => "も", complexity => 7, answer => "mo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mo.wav" };
push @set, { question => "ら", complexity => 8, answer => "ra", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ra.wav" };
push @set, { question => "り", complexity => 8, answer => "ri", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ri.wav" };
push @set, { question => "る", complexity => 8, answer => "ru", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ru.wav" };
push @set, { question => "れ", complexity => 8, answer => "re", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "re.wav" };
push @set, { question => "ろ", complexity => 8, answer => "ro", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ro.wav" };
push @set, { question => "わ", complexity => 9, answer => "wa", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "wa.wav" };
push @set, { question => "を", complexity => 9, answer => "wo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "o.wav" };
push @set, { question => "や", complexity => 9, answer => "ya", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ya.wav" };
push @set, { question => "ゆ", complexity => 9, answer => "yu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "yu.wav" };
push @set, { question => "よ", complexity => 9, answer => "yo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "yo.wav" };
push @set, { question => "ん", complexity => 9, answer => "n", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "n.wav" };



sub get_set {
    return @set;
}

1; # End of Quiz::Flashcards::Sets::Hiragana::Romaji_Simple
