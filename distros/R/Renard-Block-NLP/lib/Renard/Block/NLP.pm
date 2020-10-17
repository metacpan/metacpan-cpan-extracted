use Renard::Incunabula::Common::Setup;
package Renard::Block::NLP;
# ABSTRACT: Natural language processing for English
$Renard::Block::NLP::VERSION = '0.001';
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Function::Parameters;
use Text::Unidecode;

fun apply_sentence_offsets_to_blocks( (InstanceOf['String::Tagged']) $text ) {
	$text->iter_extents_nooverlap(
		sub {
			my ( $extent, %tags ) = @_;
			my $offsets = _get_offsets( $extent->substr->str );
			# NOTE Offsets need to be sorted because it appears that they might not
			# be in order.  Not sure what that means or if that is a bug.
			$offsets = [ sort { $a->[0] <=> $b->[0] } @$offsets ];
			my $id = 0;
			for my $o (@$offsets) {
				$text->apply_tag(
					$extent->start + $o->[0],
					$o->[1]-$o->[0],
					sentence => $id++ );
			}
		},
		only => [ 'block' ],
	);
}

fun _get_offsets( $text ) {
	# loading here so that utf8::all does not effect everything
	require Lingua::EN::Sentence;
	Lingua::EN::Sentence->import(qw/get_sentences/);

	my $sentences = get_sentences($text);

	my $offsets = [];
	my $str = $text;
	for my $s (@$sentences) {
		# Make the search insensitive to internal
		# spaces.  This is due to Lingua::EN::Sentence
		# having the `clean_sentences()` step.
		my $s_re = quotemeta($s) =~ s/(\\\s)+/\\s+/gr;

		# We use the 'g' option here because it keeps
		# track of the previous regex position.
		#
		# This makes sure that repeated sentences have
		# different offsets.
		$str =~ m/\G(?:.*?)($s_re)/g;
		push @$offsets, [ $-[1], $+[1] ];
	}

	$offsets;
}

fun preprocess_for_tts( $text ) {
	$_ = $text;
	$_ = unidecode($_); # FIXME this is a sledgehammer approach

	s/\[(\d+(,\s*\d+)*)\]/citation $1/gi; # [12,28] -> citations 12, 28
	s/\bFig[. ]*(\d+)/Figure $1/gi; # Fig. 4 -> Figure 4
	s/\bSec[. ]*(\d+)/Section $1/gi; # Sec. 2 -> Section 2
	s/\bEq[. ]*(\d+)/Equation $1/gi; # Eq. 3 -> Equation 3
	s/\be\.?g\.?,/for example,/gi; # (e.g., text) -> (for example, text)
	s/\bi\.?e\.?,/that is,/gi; # (i.e., text) -> (that is, text)
	s/\bet\s*al\.?/and others/gi; # et al -> and others
	$_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::NLP - Natural language processing for English

=head1 VERSION

version 0.001

=head1 FUNCTIONS

=head2 apply_sentence_offsets_to_blocks

  fun apply_sentence_offsets_to_blocks( (InstanceOf['String::Tagged']) $text )

Retrieves the sentence offsets for each part of the C<$text> string that has
been tagged as a C<block> and apply a C<sentence> tag to each sentence.

=head2 _get_offsets

  fun _get_offsets( $text )

This uses L<Lingua::EN::Sentence> internally to determine the location
of each sentence.

Returns an ArrayRef of ArrayRefs where the first item is the starting index and
the second is the ending index of each sentence in C<$text>.

=head2 preprocess_for_tts

  fun preprocess_for_tts( $text )

Preprocess C<$text> by using a number of substitutions for common abbreviations
so that a speech synthesis engine can read the expanded versions.

Returns a C<Str> with the preprocessed text.

=head1 SEE ALSO

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Renard-Block-NLP/>

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
