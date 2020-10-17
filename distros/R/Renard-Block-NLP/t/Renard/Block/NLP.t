#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use Renard::Incunabula::Common::Setup;

use Renard::Block::Format::PDF::Devel::TestHelper;
use Renard::Block::NLP;

use List::AllUtils qw(reduce);
use Test::Needs;

plan tests => 2;

subtest "Split sentences in PDF" => sub {
	test_needs 'Renard::Block::Format::PDF::Document';
	my $pdf_ref_path = try {
		Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_path;
	} catch {
		plan skip_all => "$_";
	};
	my $pdf_doc = Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_object;

	my $tagged = $pdf_doc->get_textual_page( 23 );

	Renard::Block::NLP::apply_sentence_offsets_to_blocks( $tagged );
	my @sentences = ();

	$tagged->iter_substr_nooverlap(
		sub {
			my ( $substring, %tags ) = @_;
			if( defined $tags{sentence} ) {
				#note "$substring\n=-=";
				push @sentences, $substring;
			}
		},
		only => [ 'sentence' ],
	);

	# even though there is a dot in this sentence, it does not get split
	my $sentence_with_dot = 'It includes the precise documentation of the underlying imaging model from Post-Script along with the PDF-specific features that are combined in version 1.7 of the PDF standard.';
	cmp_deeply
		\@sentences,
		superbagof(
			'Preface',  # heading
			'23',       # page number
			$sentence_with_dot,
		),
		'A block is considered its own sentence';
};

subtest "Get offsets" => sub {
	my $last_repeat = 3;
	my $repeat_s = qq|Help me with this repeat.|;
	my @sentences = (
		qq|This is a sentence.|,
		qq|(This is a another.|,
		qq|These are in parentheses.)|,
		$repeat_s,
		qq|Tell me, Mr. Anderson, what good is a phone call if you're unable to speak?|,
		qq|A sentence with too   many    spaces   that    should    be   cleaned.|,
		($repeat_s)x($last_repeat),
	);

	my $txt = join " ", @sentences;

	my $offsets = Renard::Block::NLP::_get_offsets($txt);

	is scalar @$offsets, scalar @sentences, 'Right number of sentences';
	ok ! eq_deeply( $offsets->[-$last_repeat], $offsets->[-$last_repeat+1] ),
		"Check that repeated sentences have different offsets";
	ok defined(reduce { defined $a && $a->[1] < $b->[0] ? $b : undef  } @$offsets),
		'All sorted offsets such that the end of the previous is before the start of the next';

	my @got_sentences = map { substr $txt, $_->[0], $_->[1] - $_->[0] } @$offsets;

	is_deeply \@got_sentences, \@sentences, 'Same sentences';
};
