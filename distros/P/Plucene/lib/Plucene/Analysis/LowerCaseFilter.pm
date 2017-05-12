package Plucene::Analysis::LowerCaseFilter;

=head1 NAME 

Plucene::Analysis::LowerCaseFilter - normalises token text to lower case

=head1 SYNOPSIS

	# usa Plucene::Analysis::TokenFilter

	my $next = $l_case_filter->next;

=head1 DESCRIPTION

This normalises token text to lower case.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::TokenFilter';

=head2 next

	my $next = $l_case_filter->next;

This will return the next token in the stream, or undef at the end of string.
	
=cut

sub next {
	my $self = shift;
	my $t = $self->input->next() or return;
	$t->text(lc $t->text);
	return $t;
}

1;
