package Plucene::Plugin::Analyzer::MetaphoneFilter;

=head1 NAME

Plucene::Plugin::Analyzer::MetaphoneFilter - Metaphone filter on the token stream

=head1 SYNOPSIS

	# isa Plucene::Analysis:::TokenFilter
	
	my $token = $metaphone_filter->next;

=head1 DESCRIPTION

This class transforms the token stream as per the Metaphone algorithm.

You can find more information on the Metaphone algorithm at 
Text::Metaphone

=head1 METHODS

=cut

use strict;
use warnings;

use Text::Metaphone;

use base 'Plucene::Analysis::TokenFilter';

=head2 next

	my $token = $metaphone_filter->next;

Returns the next input token, after being metaphoned.

=cut

sub next {
	my $self = shift;
	my $t = $self->input->next or return;
	my @r;
	push @r, Metaphone($t->text);
	$t->text(@r);
	return $t;
}

1;
