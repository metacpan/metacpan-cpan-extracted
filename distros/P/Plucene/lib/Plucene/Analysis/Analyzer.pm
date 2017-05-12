package Plucene::Analysis::Analyzer;

=head1 NAME 

Plucene::Analysis::Analyzer - base class for Analyzers

=head1 SYNOPSIS

	my $analyzer = Plucene::Analysis::Analyzer::Subclass->new;

=head1 DESCRIPTION

This is an abstract base class of Analyzers.

An Analyzer builds TokenStreams, which analyze text. It thus represents 
a policy for extracting index terms from text.

Typical implementations first build a Tokenizer, which breaks the stream 
of characters from the Reader into raw Tokens. One or more TokenFilters 
may then be applied to the output of the Tokenizer.

=head1 METHODS

=cut

use strict;
use warnings;

=head2 new

	my $analyzer = Plucene::Analysis::Analyzer::Subclass->new;

=cut

sub new { bless {}, shift }

=head2 tokenstream

This must be defined in a subclass

=cut

sub tokenstream { die "tokenstream must be defined in a subclass" }

1;
