package Quiz::Flashcards::Sets::Katakana::Romaji_Simple;

use warnings;
use strict;
use utf8;

use base 'Exporter';

our @EXPORT = (qw( get_set ));

=head1 NAME

Quiz::Flashcards::Sets::Katakana::Romaji_Simple - Flashcard set with the basic 46 japanese katakana

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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

Please report any bugs or feature requests to C<bug-Quiz-flashcards-sets-Katakana-romaji_simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quiz-Flashcards-Sets-Katakana-Romaji_Simple>.  I will be notified, and then you'll
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
push @set, { question => "ア", complexity => 1, answer => "a", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "a.wav" };
push @set, { question => "イ", complexity => 1, answer => "i", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "i.wav" };
push @set, { question => "ウ", complexity => 1, answer => "u", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "u.wav" };
push @set, { question => "エ", complexity => 1, answer => "e", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "e.wav" };
push @set, { question => "オ", complexity => 1, answer => "o", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "o.wav" };
push @set, { question => "カ", complexity => 2, answer => "ka", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ka.wav" };
push @set, { question => "キ", complexity => 2, answer => "ki", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ki.wav" };
push @set, { question => "ク", complexity => 2, answer => "ku", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ku.wav" };
push @set, { question => "ケ", complexity => 2, answer => "ke", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ke.wav" };
push @set, { question => "コ", complexity => 2, answer => "ko", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ko.wav" };
push @set, { question => "サ", complexity => 3, answer => "sa", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "sa.wav" };
push @set, { question => "シ", complexity => 3, answer => "shi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "shi.wav" };
push @set, { question => "ス", complexity => 3, answer => "su", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "su.wav" };
push @set, { question => "セ", complexity => 3, answer => "se", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "se.wav" };
push @set, { question => "ソ", complexity => 3, answer => "so", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "so.wav" };
push @set, { question => "タ", complexity => 4, answer => "ta", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ta.wav" };
push @set, { question => "チ", complexity => 4, answer => "chi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "chi.wav" };
push @set, { question => "ツ", complexity => 4, answer => "tsu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "tsu.wav" };
push @set, { question => "テ", complexity => 4, answer => "te", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "te.wav" };
push @set, { question => "ト", complexity => 4, answer => "to", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "to.wav" };
push @set, { question => "ナ", complexity => 5, answer => "na", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "na.wav" };
push @set, { question => "ニ", complexity => 5, answer => "ni", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ni.wav" };
push @set, { question => "ヌ", complexity => 5, answer => "nu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "nu.wav" };
push @set, { question => "ネ", complexity => 5, answer => "ne", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ne.wav" };
push @set, { question => "ノ", complexity => 5, answer => "no", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "no.wav" };
push @set, { question => "ハ", complexity => 6, answer => "ha", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ha.wav" };
push @set, { question => "ヒ", complexity => 6, answer => "hi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "hi.wav" };
push @set, { question => "フ", complexity => 6, answer => "fu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "hu.wav" };
push @set, { question => "ヘ", complexity => 6, answer => "he", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "he.wav" };
push @set, { question => "ホ", complexity => 6, answer => "ho", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ho.wav" };
push @set, { question => "マ", complexity => 7, answer => "ma", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ma.wav" };
push @set, { question => "ミ", complexity => 7, answer => "mi", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mi.wav" };
push @set, { question => "ム", complexity => 7, answer => "mu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mu.wav" };
push @set, { question => "メ", complexity => 7, answer => "me", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "me.wav" };
push @set, { question => "モ", complexity => 7, answer => "mo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "mo.wav" };
push @set, { question => "ラ", complexity => 8, answer => "ra", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ra.wav" };
push @set, { question => "リ", complexity => 8, answer => "ri", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ri.wav" };
push @set, { question => "ル", complexity => 8, answer => "ru", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ru.wav" };
push @set, { question => "レ", complexity => 8, answer => "re", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "re.wav" };
push @set, { question => "ロ", complexity => 8, answer => "ro", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ro.wav" };
push @set, { question => "ワ", complexity => 9, answer => "wa", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "wa.wav" };
push @set, { question => "ヲ", complexity => 9, answer => "wo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "o.wav" };
push @set, { question => "ヤ", complexity => 9, answer => "ya", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "ya.wav" };
push @set, { question => "ユ", complexity => 9, answer => "yu", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "yu.wav" };
push @set, { question => "ヨ", complexity => 9, answer => "yo", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "yo.wav" };
push @set, { question => "ン", complexity => 9, answer => "n", question_type => "text", answer_type => "text", audiobank => $ab, audio_file => "n.wav" };






sub get_set {
    return @set;
}

1; # End of Quiz::Flashcards::Sets::Katakana::Romaji_Simple
