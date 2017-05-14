package String::Compare;

use base qw(Exporter);
@EXPORT = qw(compare);
use strict;

=head1 NAME

String::Compare - Compare two strings and return how much they are alike

=head1 SYNOPSIS

  use String::Compare;
  my $str1 = "J R Company";
  my $str2 = "J. R. Company";
  my $str3 = "J R Associates";
  my $points12 = compare($str1,$str2);
  my $points13 = compare($str1,$str3);
  if ($points12 > $points13) {
     print $str1." refers to ".$str2;
  } else {
     print $str1." refers to ".$str3;
  }

=head1 DESCRIPTION

This module was created when I needed to merge the information
between two databases, and I had to find who were who in each database,
but the names weren't always equals, sometimes there were differences.

The problem was that I need to choose the right person, so I must see how
much the different names are alike. I've tried testing char by char, but situations
like the described in the synopsis showed me that wasn't enough. So I created a
set of tests to give a more accurate pontuation of how much the  names are alike.

The result is in percentage. If the strings are exactly equal, it would return 1,
if they have nothing in common, it would return 0.

=head1 METHODS

=over

=item compare($str1,$str2,%tests)

This method receives the two strings and optionally the names and weights
of each test. The default behavior is to use all the tests with the weigth 1.
This method lowercases both strings, since case doesn't change the meaning
of the content. But each test is case sensitive, so if you like you must lc the strings.

The current tests are (you can use the tests individually if you like:

P.S.: You can use custom tests, because the tests are executed using eval,
so if you want a custom test, just use the full name of a method.

P.S.2: If you created a test, please share it, sending me by email and I will be
glad to include it into the default set.

=back

=cut

my %default_options =
  (
   char_by_char => 1,
   consonants => 1,
   vowels => 1,
   word_by_word => 1,
   chars_only => 1
  );

sub compare {
	my $str1 = shift;
	my $str2 = shift;

	$str1 = lc($str1);
	$str2 = lc($str2);
	# skip any tests if they are the same
	return 1 if $str1 eq $str2;

	my %user_opt = @_;
	my %opt = (%default_options, %user_opt);
	my %results;
	my $totalPoints = 0;
	my $score = 0;
	foreach my $test (keys %opt) {
		$totalPoints += $opt{$test};
	}
	foreach my $test (keys %opt) {
		next if $opt{$test} == 0;
		my $result = __PACKAGE__->can($test)->($str1,$str2) || 0;
		$score += $result * $opt{$test}/$totalPoints;
	}
	return $score;
}

=over

=item char_by_char($str1,$str2)

Tests character by character

=back

=cut

sub char_by_char {
	my $str1 = shift;
	my $str2 = shift;
	my $size1 = length $str1;
	my $size2 = length $str2;
	my $score = 0;
	my $size = $size1>$size2?$size1:$size2;
	for (my $i = 0;$i < $size; $i++) {
		if (length $str1 < $i) {
			last;
		}
		if (length $str2 < $i) {
			last;
		}
		my $c1 = substr $str1, $i, 1;
		my $c2 = substr $str2, $i, 1;
		if ($c1 eq $c2) {
			$score += 1/$size;
		}
	}
	return $score;
}

=over

=item consonants($str1,$str2)

Test char_by_char only in the consonants.

=back

=cut

*consoants = *consonants;
sub consonants {
	my $str1 = shift;
	my $str2 = shift;
	$str1 =~ s/[^bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]//g;
	$str2 =~ s/[^bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]//g;
	return char_by_char($str1,$str2);
}

=over

=item vowels($str1,$str2)

Test char_by_char only in the vowels.

=back

=cut

sub  vowels {
	my $str1 = shift;
	my $str2 = shift;
	$str1 =~ s/[^aeiouyAEIOUY]//g;
	$str2 =~ s/[^aeiouyAEIOUY]//g;
	return char_by_char($str1,$str2);
}

=over

=item word_by_word($str1, $str2)

Test char_by_char each word, giving points according to the
size of the word.

=back

=cut

sub word_by_word {
	my $str1 = shift;
	my $str2 = shift;
	my @words1 = split(/\s+/,$str1);
	my @words2 = split(/\s+/,$str2);
	my $size1 = scalar @words1;
	my $size2 = scalar @words2;
	my $size = $size1>$size2?$size1:$size2;
	my $score;
	my $totalChars;
	my @totalCharsPerWord;
	for (my $i = 0; $i < $size; $i++) {
		my $subsize1 = $i < $size1 ? length($words1[$i]) : 0;
		my $subsize2 = $i < $size2 ? length($words2[$i]) : 0;
		my $subsize = $subsize1 > $subsize2?$subsize1:$subsize2;
		$totalChars += $subsize;
		push @totalCharsPerWord, $subsize;
	}
	for (my $i = 0; $i < $size; $i++) {
        last if $i >= $size1;
		my $bestScore = 0;
		for (my $j = 0; $j < $size; $j++) {
            last if $j >= $size2;
			my $result = char_by_char($words1[$i],$words2[$j]);
			$bestScore = $result if $result > $bestScore;
		}
		$score += $bestScore * $totalCharsPerWord[$i]/$totalChars;
	}
	return $score;
}

=over

=item chars_only($str1,$str2)

Test char_by_char only with the characters matched by \w.

=back

=cut

sub chars_only {
	my $str1 = shift;
	my $str2 = shift;
	$str1 =~ s/\W//g;
	$str2 =~ s/\W//g;
	return char_by_char($str1,$str2);
}


=head1 COPYRIGHT

This module was created by "Daniel Ruoso" <daniel@ruoso.com>. It is licensed under both
the GNU GPL and the Artistic License.

=cut

