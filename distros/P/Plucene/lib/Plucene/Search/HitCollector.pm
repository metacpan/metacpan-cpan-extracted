package Plucene::Search::HitCollector;

=head1 NAME 

Plucene::Search::HitCollector

=head1 SYNOPSIS

	# used in conjunction with the IndexSearcher

	my $searcher = Plucene::Search::IndexSearcher->new($DIRECTORY);

	my $hc = Plucene::Search::HitCollector->new( collect =>
		sub { 
			my ($self, $doc, $score) = @_; 
			... 
	});

	$searcher->search_hc($QUERY, $hc);
	
=head1 DESCRIPTION

This is used in conjunction with the IndexSearcher, in that whenever a 
non-zero scoring document is found, the subref with with the HitCollector
was made will get called.

=head1 METHODS

=cut

=head2 new

	my $hc = Plucene::Search::HitCollector->new( collect =>
		sub { 
			my ($self, $doc, $score) = @_; 
			... 
	});

This will create a new Plucene::Search::HitCollector with the passed subref.
		
=cut

use strict;
use warnings;

use Carp qw/confess/;

# We're having to fake up singleton methods here.

sub new {
	my ($self, %stuff) = @_;
	if (!exists $stuff{collect}) {
		confess("Need to supply definition of collect method");
	}
	bless \%stuff, $self;
}

=head2 collect

This is called once for every non-zero scoring document, with the document 
number and its score.

=cut

sub collect { shift->{collect}->(@_) }

1;
