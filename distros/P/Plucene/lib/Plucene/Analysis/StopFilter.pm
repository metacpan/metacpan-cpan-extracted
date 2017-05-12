package Plucene::Analysis::StopFilter;

=head1 NAME 

Plucene::Analysis::StopFilter - the stop filter

=head1 SYNOPSIS

	# isa Plucene::Analysis::TokenFilter

	my $next = $stop_filter->next;

=head1 DESCRIPTION

This removes stop words from a token stream.

Instances of the StopFilter class are tokens filters that removes from the 
indexed text words of your choice. Typically this is used to filter out common 
words ('the', 'a' 'if' etc) that increase the overhead but add no value during 
searches.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::TokenFilter';

=head2 next

	my $next = $stop_filter->next;

This returns the next input token whose term is not a stop word.

=cut

sub next {
	my $self = shift;
	$self->{stophash} ||= { map { $_ => 1 } @{ $self->{stoplist} } };
	while (my $t = $self->input->next) {
		next if exists $self->{stophash}->{ $t->text() };
		return $t;
	}
	return;
}

1;
