package RDF::RDFa::Linter::Service::CreativeCommons;

use 5.008;
use base 'RDF::RDFa::Linter::Service';
use strict;
use constant {
	DC_NS       => 'http://purl.org/dc/elements/1.1/',
	DCMITYPE_NS => 'http://purl.org/dc/dcmitype/',
	CC_NS       => 'http://creativecommons.org/ns#',
	XHV_NS      => 'http://www.w3.org/1999/xhtml/vocab#',
	};
use RDF::TrineX::Functions -shortcuts, statement => { -as => 'rdf_statement' };

our $VERSION = '0.053';

sub sgrep_filter
{
	my ($st) = @_;
	
	return 1 if $st->predicate->uri eq XHV_NS.'license';
	
	return 1
		if grep {$_ eq $st->predicate->uri}
			map {CC_NS.$_}
			qw(permits requires prohibits jurisdiction legalcode deprecatedOn
				license morePermissions attributionName attributionURL);

	return 1
		if grep {$_ eq $st->predicate->uri}
			map {DC_NS.$_}
			qw(title type source rights rights.license);

	return 1 if $st->predicate->uri eq 'http://purl.org/dc/terms/license';

	return 1 if $st->predicate->uri eq 'http://web.resource.org/cc/license';

	return 1
		if $st->predicate->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
		&& $st->object->is_resource
		&& $st->object->uri eq CC_NS.'Work';
	
	return 1
		if $st->predicate->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
		&& $st->object->is_resource
		&& $st->object->uri eq CC_NS.'License';

	return 0;
};

sub info
{
	return {
		short        => 'ccREL',
		title        => 'Creative Commons Rights Expression Language',
		description  => 'Creative Commons Rights Expression Language is used to indicate licensing terms for works.',
		};
}

sub prefixes
{
	my ($proto) = @_;
	return { 'cc'=>CC_NS,'dc'=>DC_NS,'dcmitype'=>DCMITYPE_NS };
}

sub find_errors
{
	my $self = shift;
	my @rv = $self->SUPER::find_errors(@_);
	
	push @rv, $self->_check_unknown_types;
	push @rv, $self->_check_license_sane;
	push @rv, $self->_check_license_lies;
	
	return @rv;
}

sub _check_license_sane
{
	my ($self) = @_;
	my @errs;

	foreach my $ns ((CC_NS, XHV_NS, 'http://web.resource.org/cc/', 'http://purl.org/dc/terms/', 'http://purl.org/dc/elements/1.1/rights.'))
	{
		my $sparql = sprintf('SELECT * WHERE { ?subject <%s%s> ?license . }', $ns, 'license');
		my $iter   = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
		
		while (my $row = $iter->next)
		{
			if ($row->{'license'}->is_literal)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $row->{'subject'},
						'text'    => 'Literal license '.$row->{'type'}->as_ntriples.' - license should be a URI',
						'level'   => 4,
						'link'    => undef,
					);
				next;
			}
			elsif ($row->{'license'}->is_blank)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $row->{'subject'},
						'text'    => 'Blank node license '.$row->{'type'}->as_ntriples.' - license should probably be a URI',
						'level'   => 2,
						'link'    => undef,
					);
				next;
			}
		}
	}
	
	return @errs;
}

sub _check_unknown_types
{
	my ($self) = @_;
	my @errs;
	
	my @dcmitypes = qw'Collection Dataset Event Image InteractiveResource
		MovingImage PhysicalObject Service Software Sound StillImage Text';
	
	my $sparql = sprintf('SELECT * WHERE { ?subject <%s%s> ?type . }', DC_NS, 'type');
	my $iter   = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
	
	while (my $row = $iter->next)
	{
		unless ($row->{'type'}->is_resource)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->{'subject'},
					'text'    => 'Non-URI value for dc:type: '.$row->{'type'}->as_ntriples,
					'level'   => 3,
					'link'    => 'http://dublincore.org/documents/dces/#type',
				);
			next;
		}
		my $uri = $row->{'type'}->uri;
		if (DCMITYPE_NS eq substr $uri, 0, length DCMITYPE_NS)
		{
			my $type = substr $uri, length DCMITYPE_NS;
			
			unless (grep {$type eq $_} @dcmitypes)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $row->{'subject'},
						'text'    => "Type $type is not defined in the DCMI Types Vocabulary",
						'level'   => 3,
						'link'    => 'http://dublincore.org/documents/dcmi-type-vocabulary/',
					);
			}
		}
		else
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->{'subject'},
					'text'    => 'Non-DCMITYPE value for dc:type: '.$row->{'type'}->as_ntriples,
					'level'   => 1,
					'link'    => 'http://dublincore.org/documents/dces/#type',
				);
			next;
		}		
	}
	
	return @errs;
}

## TODO - check for lies like { <CC-BY> cc:requires cc:SourceCode }
sub _check_license_lies
{
	my ($self) = @_;
	my @errs;

	my $truth = {
		'by' => {
			'requires'  => [qw(Attribution Notice)],
			'permits'   => [qw(Reproduction Distribution DerivativeWorks)],
			'prohibits' => [],
			},
		'by-nd' => {
			'requires'  => [qw(Attribution Notice)],
			'permits'   => [qw(Reproduction Distribution)],
			'prohibits' => [],
			},
		'by-nc-nd' => {
			'requires'  => [qw(Attribution Notice)],
			'permits'   => [qw(Reproduction Distribution)],
			'prohibits' => [qw(CommercialUse)],
			},
		'by-nc' => {
			'requires'  => [qw(Attribution Notice)],
			'permits'   => [qw(Reproduction Distribution DerivativeWorks)],
			'prohibits' => [qw(CommercialUse)],
			},
		'by-nc-sa' => {
			'requires'  => [qw(Attribution ShareAlike Notice)],
			'permits'   => [qw(Reproduction Distribution DerivativeWorks)],
			'prohibits' => [qw(CommercialUse)],
			},
		'by-sa' => {
			'requires'  => [qw(Attribution ShareAlike Notice)],
			'permits'   => [qw(Reproduction Distribution DerivativeWorks)],
			'prohibits' => [],
			},
		};

	my $data   = $self->filtered_graph->as_hashref;
	
	SUBJECT: foreach my $subject (keys %$data)
	{
		my $code;
		if ($subject =~ m'^http://(www\.)?creativecommons\.org/licenses/(by[a-z-]*)')
		{
			$code = $2;
		}
		else
		{
			next SUBJECT;
		}
		
		PROP: foreach my $prop (qw(requires permits prohibits))
		{
			next PROP unless defined $data->{$subject}->{CC_NS.$prop};
			
			VALUE: foreach my $value (@{ $data->{$subject}->{CC_NS.$prop} })
			{
				if (CC_NS eq substr $value->{'value'}, 0, length CC_NS)
				{
					$value = substr $value->{'value'}, length CC_NS;
				}
				else
				{
					next VALUE;
				}
				
				unless (grep {$_ eq $value} @{ $truth->{$code}->{$prop} })
				{
					push @errs,
						RDF::RDFa::Linter::Error->new(
							'subject' => RDF::Trine::Node::Resource->new($subject),
							'text'    => sprintf('Document claims that Creative Commons %s license %s %s - this is not true!', uc $code, $prop, $value),
							'level'   => 4,
							'link'    => $subject,
						);					
				}
			}
		}
	}
	
	return @errs;
}

1;
