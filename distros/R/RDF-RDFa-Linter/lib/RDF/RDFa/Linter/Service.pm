package RDF::RDFa::Linter::Service;

use 5.008;
use strict;
use RDF::RDFa::Linter::Error;
use RDF::Trine;
use RDF::Trine::Iterator qw'sgrep';

our $VERSION = '0.053';

sub sgrep_filter
{
	my ($st) = @_;
	return 0;
};

sub info
{
	return {
		short        => 'Base',
		title        => 'Base Service Class',
		description  => 'This is the base class for all services. It should not be used directly.',
		};
}

sub new
{
	my ($class, $model, $uri) = @_;
	my $self = bless {}, $class;
	
	$self->{'original'} = $model;
	$self->{'filtered'} = RDF::Trine::Model->temporary_model;
	$self->{'uri'}      = $uri;
	
	my $filt     = "${class}::sgrep_filter";
	my $filtered = sgrep(\&$filt, $model->as_stream);
	while (my $st = $filtered->next)
		{ $self->{'filtered'}->add_statement($st); }
	
	return $self;
}

sub filtered_graph
{
	my ($self) = @_;
	return $self->{'filtered'};
}

sub prefixes
{
	my ($proto) = @_;
	return {};
}

sub find_errors
{
	my ($self) = @_;
	return qw();
}

1;
