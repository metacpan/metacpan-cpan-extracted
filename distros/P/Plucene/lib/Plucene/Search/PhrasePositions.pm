package Plucene::Search::PhrasePositions;

=head1 NAME 

Plucene::Search::PhrasePositions - The position of a phrase

=head1 SYNOPSIS

	my $phpos = Plucene::Search::PhrasePositions->new;

	my      $next = $phpos->next;
	my $first_pos = $phpos->first_position;
	my  $next_pos = $phpos->next_position;
	
=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ doc position count offset tp next_in_list /);

=head2 new

	my $phpos = Plucene::Search::PhrasePositions->new;

Make a new Plucene::Search::PhrasePositions object.
	
=head2 doc / position / count / offset / tp / next

Get / set these attibutes.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{offset}   ||= 0;
	$self->{position} ||= 0;
	$self->{count}    ||= 0;
	$self->next;
	$self;
}

=head2 next

	my $next = $phpos->next;

=cut

sub next {
	my $self = shift;
	if (!$self->{tp}->next) {
		$self->doc(~0);
		return;
	}
	$self->doc($self->tp->doc);
	$self->position(0);
}

=head2 first_position

	my $first = $phpos->first_position;

=cut

sub first_position {
	my $self = shift;
	$self->count($self->tp->freq);
	$self->next_position;
}

=head2 next_position

	my $next_pos = $phpos->next_position;

=cut

sub next_position {
	my $self = shift;
	return unless $self->{count}-- > 0;
	$self->position($self->tp->next_position - $self->offset);
}

1;
