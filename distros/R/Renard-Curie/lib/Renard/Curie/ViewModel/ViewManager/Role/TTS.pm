use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager::Role::TTS;
$Renard::Curie::ViewModel::ViewManager::Role::TTS::VERSION = '0.005';
use Moo::Role;

use Renard::Block::NLP;
use Scalar::Util qw(refaddr);

use Renard::Incunabula::Common::Types qw(Bool PositiveOrZeroInt);

has tts_playing => (
	is => 'rw',
	isa => Bool,
	default => sub { 0 },
);

has current_sentence_number => (
	is => 'rw',
	isa => PositiveOrZeroInt,
	trigger => 1, # _trigger_current_sentence_number
	default => 0,
);

method _trigger_current_sentence_number($new_current_sentence_number) {
	$self->signal_emit( 'update-view' => $self->current_view );
}

method current_text_page() {
	return [] unless $self->current_document->can('get_textual_page');

	my $page_number = $self->current_view->page_number;
	my $txt = $self->current_document->get_textual_page($page_number);

	Renard::Block::NLP::apply_sentence_offsets_to_blocks($txt);

	my @sentence_spans = ();
	$txt->iter_extents(sub {
		my ($extent, $tag_name, $tag_value) = @_;
		my $data = {
			sentence => $extent->substr,
			extent => $extent,
		};

		my $start = $extent->start;
		my $end = $extent->end;
		my $last_span = {};
		for my $pos ($start..$end-1) {
			my $value = $txt->get_tag_at($pos,'font');
			if( defined $value && refaddr $last_span != refaddr $value ) {
				$last_span = $value;
				push @{ $data->{spans} }, $value;
			}
		}

		push @sentence_spans, $data;
	}, only => ['sentence'] );

	for my $sentence (@sentence_spans) {
		my $extent = $sentence->{extent};
		$sentence->{first_char} = $txt->get_tag_at( $extent->start, 'char' );
		$sentence->{last_char} = $txt->get_tag_at( $extent->end-1, 'char' );
		my @spans = @{ $sentence->{spans} };
		my @bb = ();
		my $in_range = 0;
		for my $first_span ( @spans ) {
			for my $c (@{ $first_span->{char} }) {
				if( refaddr $c == refaddr $sentence->{first_char} ) {
					$in_range = 1;
				}

				push @bb, $c->{bbox} if $in_range;

				if( refaddr $c == refaddr $sentence->{last_char} ) {
					$in_range = 0;
					last;
				}
			}
		}

		$sentence->{bbox} = \@bb;
	}

	\@sentence_spans;
}

method num_of_sentences_on_page() {
	my $text = $self->current_text_page;
	return @{ $text };
}

method choose_previous_sentence() {
	my $v = $self->current_view;
	my $vm = $self;
	if( $vm->current_sentence_number > 0 ) {
		$vm->current_sentence_number( $vm->current_sentence_number - 1 );
	} elsif( $v->can_move_to_previous_page ) {
		$v->set_current_page_back;
		$vm->current_sentence_number(
			$self->num_of_sentences_on_page - 1
		);
	}
}

method choose_next_sentence() {
	my $v = $self->current_view;
	my $vm = $self;
	if( $vm->current_sentence_number < $self->num_of_sentences_on_page - 1 ) {
		$vm->current_sentence_number( $vm->current_sentence_number + 1 );
	} elsif( $v->can_move_to_next_page ) {
		$v->set_current_page_forward;
		$vm->current_sentence_number(0);
	} else {
		$self->tts_playing(0);
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager::Role::TTS

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 tts_playing

A C<Bool> that indicates if the TTS is playing or not.

=head2 current_sentence_number

Stores the current sentence number index (0-based): C<PositiveOrZeroInt>.

=head1 METHODS

=head2 current_text_page

  method current_text_page()

Returns a C<HashRef> of sentences on the page.

Keys:

=over 4

=item *

C<sentence>: C<String::Tagged> of the sentence substring

=item *

C<bbox>: C<ArrayRef> of bounding boxes

=item *

C<extent>: extent

=item *

C<spans>: C<ArrayRef> of font spans

=item *

C<first_char>: first character information

=item *

C<last_char>: last character information

=back

=head2 num_of_sentences_on_page

  method num_of_sentences_on_page()

Retrieves the number of sentences on the page.

=head2 choose_previous_sentence

  method choose_previous_sentence()

Move to the previous sentence or the last sentence on the previous page.

=head2 choose_next_sentence

  method choose_next_sentence()

Move to the next sentence on this page or to the first sentence on the next
page.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
