package RDF::RDFa::Linter::Service::Google;

use 5.008;
use base 'RDF::RDFa::Linter::Service';
use strict;
use constant V_NS => 'http://rdf.data-vocabulary.org/#';
use RDF::TrineX::Functions -shortcuts, statement => { -as => 'rdf_statement' };

our $VERSION = '0.053';

my @properties = qw(name author cholesterol servingSize region
	tag max instruction prepTime contact tel category sugar friend count
	rating description fiber brand yield published itemreviewed title
	totalTime min saturatedFat best address fat street-address amount
	reviewer unsaturatedFat cookTime summary colleague postal-code role
	protein url value price acquaintance locality dtreviewed photo
	calories affiliation pricerange average carbohydrates duration
	country-name recipeType nickname worst);

my @classes = qw(instructions Rating Address Review-aggregate
	Recipe nutrition timeRange Person Product ingredient
	Organization Review);

sub sgrep_filter
{
	my ($st) = @_;
	
	foreach my $term (@properties)
		{ return 1 if $st->predicate->uri eq V_NS.$term; }

	foreach my $term (@classes)
		{ return 1 if $st->predicate->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' 
				&& $st->object->is_resource
				&& $st->object->uri eq V_NS.$term; }

	return 0;
};

sub new
{
	my $self = RDF::RDFa::Linter::Service::new(@_);
	
	return $self;
}

sub info
{
	return {
		short        => 'Google',
		title        => 'Google Data Vocabulary',
		description  => 'The Google Data Vocabulary supports the RDFa version of Rich Snippets.',
		};
}

sub prefixes
{
	my ($proto) = @_;
	return { 'v' => V_NS };
}

# VERY minimal checking so far.
sub find_errors
{
	my $self = shift;
	my @rv = $self->SUPER::find_errors(@_);
	
	return @rv;
}

1;
