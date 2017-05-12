package Plucene::Plugin::Analyzer::SnowballFilter;

=head1 NAME

Plucene::Plugin::Analyzer::SnowballFilter - Snowball stemming on the token stream

=head1 SYNOPSIS

	# isa Plucene::Analysis:::TokenFilter
	
	my $token = $porter_stem_filter->next;

=head1 DESCRIPTION

This class transforms the token stream as per the Snowball stemming algorithm.

You can find more information on the Snowball algorithm at 
http://snwoball.tartarus.org/. 

=head1 METHODS

=cut

use strict;
use warnings;

use Lingua::Stem::Snowball;

use base 'Plucene::Analysis::TokenFilter';

=head2 next

	my $token = $porter_stem_filter->next;

Returns the next input token, after being stemmed.

=cut

sub next {
	my $self = shift;
	my $t = $self->input->next or return;
	my @r;
	push @r, Lingua::Stem::Snowball::stem($Plucene::Plugin::Analyzer::SnowballAnalyzer::LANG, $t->text);
	$t->text(@r);
	return $t;
}

1;
