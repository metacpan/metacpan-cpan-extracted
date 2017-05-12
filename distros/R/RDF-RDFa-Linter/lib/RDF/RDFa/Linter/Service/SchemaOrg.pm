package RDF::RDFa::Linter::Service::SchemaOrg;

use 5.008;
use base 'RDF::RDFa::Linter::Service';
use strict;
use constant SCHEMA_NS => 'http://schema.org/';
use RDF::TrineX::Functions -shortcuts, statement => { -as => 'rdf_statement' };
use File::ShareDir qw[];
use File::Spec qw[];
use Set::Scalar;
use JSON qw[decode_json encode_json];
use Scalar::Util qw[looks_like_number blessed];

our $VERSION = '0.053';

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
our $SCHEMA = RDF::Trine::Namespace->new(SCHEMA_NS);

our (%Classes, %Properties);

sub sgrep_filter
{
	my ($st) = @_;
	
	my ($p_ns, $p_term) = $st->predicate->qname;
	return 1 if $p_ns eq SCHEMA_NS;

	if ($st->predicate->equal($RDF->type))
	{
		my ($c_ns, $c_term) = $st->object->qname;
		return 1 if $c_ns eq SCHEMA_NS;
	}

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
		short        => 'Schema.org',
		title        => 'Schema.org Vocabulary',
		description  => 'A common schema developed by Google, Yahoo and Microsoft.',
		};
}

sub prefixes
{
	my ($proto) = @_;
	return { 'schema' => SCHEMA_NS , 'rdfs' => $RDFS->iri('')->uri };
}

sub find_errors
{
	my $self = shift;
	my @rv = $self->SUPER::find_errors(@_);
	
	$self->_load_schema;
	$self->_detect_types;
	
	push @rv, $self->_find_errors_domain;
	push @rv, $self->_find_errors_range;
	
	return @rv;
}

sub _detect_types
{
	my ($self) = @_;
	
	foreach my $subj ($self->{filtered}->subjects($RDF->type))
	{
		my $set = Set::Scalar->new(
			map { $_->uri }
			grep { $_->is_resource }
			$self->{filtered}->objects($subj, $RDF->type)
			);
		$self->{_types}{$subj} = [$set->members] if scalar $set->members;
	}
}

sub _find_errors_domain
{
	my ($self) = shift;
	my @rv;
	
	$self->{filtered}->get_statements(undef, undef, undef)->each(sub {
		my $st = shift;
		
		return if $st->predicate->equal($RDF->type);
		return unless ref $self->{_types}{$st->subject};
		
		my $explicit   = Set::Scalar->new(@{$self->{_types}{$st->subject} || []});
		my $domain     = Set::Scalar->new(@{$Properties{$st->predicate->uri}{domain} || []});
		my $ext_domain = do {
			my $set = Set::Scalar->new;
			$set->insert( @{$Classes{$_}{subclasses} || []} ) foreach $domain->members;
			$set;
			};

		unless ($explicit->intersection($ext_domain))
		{
			my ($first) = $domain->members;
			
			push @rv, RDF::RDFa::Linter::Error->new(
				'subject' => $st->subject,
				'text'    => sprintf("Property %s should be used with items of type %s.",
					$st->predicate->uri,
					(join ' or ', $domain->members),
					),
				'level'   => 4,
				'link'    => $first,
				);
		}
	});
	
	return @rv;
}

sub _find_errors_range
{
	my ($self) = shift;
	my @rv;
	
	$self->{filtered}->get_statements(undef, undef, undef)->each(sub {
		my $st = shift;
		
		return if $st->predicate->equal($RDF->type);
		
		if ($Properties{$st->predicate->uri}{is_dt})
		{
			my %results;
			
			foreach my $range (@{$Properties{$st->predicate->uri}{range}})
			{
				$results{$range}{RANGE} = $range;
				
				if ($range eq $SCHEMA->Text->uri)
				{
					if ($st->object->is_literal)
					{
						$results{$range}{PASS} = 1;
					}
					else
					{
						$results{$range}{ERROR} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value for property %s is expected to be text.', $st->predicate->uri),
							'level'   => 2,
							'link'    => 'http://schema.org/Text',
							);
					}
				}
				if ($range eq $SCHEMA->Number->uri or $range eq $SCHEMA->Float->uri or $range eq $SCHEMA->Integer->uri)
				{
					if ($st->object->is_literal and looks_like_number($st->object->literal_value))
					{
						$results{$range}{PASS} = 1;
						$results{$range}{HINT} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s should probably have a numeric datatype set.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 5,
							'link'    => 'http://www.w3.org/TR/xmlschema-2/#built-in-primitive-datatypes',
							) unless $st->object->has_datatype;
					}
					else
					{
						$results{$range}{ERROR} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s does not seem to be a number.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 2,
							'link'    => 'http://schema.org/Number',
							);
					}
				}
				if ($range eq $SCHEMA->Boolean->uri)
				{
					if ($st->object->is_literal and $st->object->literal_value =~ /^(true|false|0|1)$/i)
					{
						$results{$range}{PASS} = 1;
						$results{$range}{HINT} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s should probably have its datatype set to xsd:boolean.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 5,
							'link'    => 'http://www.w3.org/TR/xmlschema-2/#built-in-primitive-datatypes',
							) unless $st->object->has_datatype && $st->object->literal_datatype eq $XSD->boolean->uri;
					}
					else
					{
						$results{$range}{ERROR} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s does not seem to be a boolean.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 2,
							'link'    => 'http://schema.org/Boolean',
							);
					}
				}
				if ($range eq $SCHEMA->Date->uri)
				{
					if ($st->object->is_literal and $st->object->literal_value =~ /^\d{4}-\d{2}-\d{2}$/)
					{
						$results{$range}{PASS} = 1;
						$results{$range}{HINT} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s should probably have its datatype set to xsd:date.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 5,
							'link'    => 'http://www.w3.org/TR/xmlschema-2/#built-in-primitive-datatypes',
							) unless $st->object->has_datatype && $st->object->literal_datatype eq $XSD->boolean->uri;
					}
					else
					{
						$results{$range}{ERROR} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s does not seem to be a date.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 2,
							'link'    => 'http://schema.org/Date',
							);
						return;
					}
				}
				if ($range eq $SCHEMA->URL->uri)
				{
					if (($st->object->is_literal and $st->object->literal_value =~ /^(http|https|ftp|mailto):\S+$/i)
					or $st->object->is_resource)
					{
						$results{$range}{PASS} = 1;
					}
					else
					{
						$results{$range}{ERROR} = RDF::RDFa::Linter::Error->new(
							'subject' => $st->subject,
							'text'    => sprintf('Value "%s" for property %s does not seem to be a URL.', $st->object->literal_value, $st->predicate->uri),
							'level'   => 2,
							'link'    => 'http://schema.org/URL',
							);
					}
				}
			}
			
			my $passed = 0;
			my ($hint, $error);
			foreach my $k (sort keys %results)
			{
				my $r = $results{$k};
				
				if (defined $r->{PASS} and defined $r->{HINT})
				{
					if (!$passed)
					{
						$passed = $r->{RANGE};
						$hint   = $r->{HINT};
					}
				}
				elsif (defined $r->{PASS} and !defined $r->{HINT})
				{
					$passed = $r->{RANGE};
					$hint   = undef;
				}
				elsif (defined $r->{ERROR})
				{
					$error  = $r->{ERROR};
				}
			}
			
			if ($passed)
			{
				push @rv, $hint if defined $hint;
			}
			else
			{
				push @rv, $error if defined $error;
			}
		}
		
		return @rv unless @rv;
		return unless ref $self->{_types}{$st->object};
		
		my $explicit   = Set::Scalar->new(@{$self->{_types}{$st->object} || []});
		my $range      = Set::Scalar->new(@{$Properties{$st->predicate->uri}{range} || []});
		my $ext_range  = do {
			my $set = Set::Scalar->new;
			$set->insert( @{$Classes{$_}{subclasses} || []} ) foreach $range->members;
			$set;
			};

		unless ($explicit->intersection($ext_range))
		{
			my ($first) = $range->members;
			
			push @rv, RDF::RDFa::Linter::Error->new(
				'subject' => $st->object,
				'text'    => sprintf("Values of property %s should be of type %s.",
					$st->predicate->uri,
					(join ' or ', $range->members),
					),
				'level'   => 4,
				'link'    => $first,
				);
		}
	});
	
	return @rv;
}

sub _load_schema
{
	my ($self) = @_;

	if (%Properties)
	{
		return;
	}
	
	my $jpdir = File::Spec->catfile(
        File::Spec->tmpdir,
        'RDF-RDFa-Linter'
        );
	mkdir $jpdir unless -d $jpdir;
	my $json_path = File::Spec->catfile(
        File::Spec->tmpdir,
        'RDF-RDFa-Linter',
        'schemaorg.json',
        );
	my $owl_path = File::ShareDir::dist_file(
		'RDF-RDFa-Linter',
		'schemaorg.owl',
		);
	
	if (-f $json_path)
	{
		my @json_stat = stat $json_path;
		my @owl_stat  = stat $owl_path;
		if ($json_stat[9] >= $owl_stat[9]) # if JSON as uptodate as OWL
		{
			open my $fh, '<', $json_path;
			my $data = decode_json(do {local $/ = <$fh>});
			%Properties = %{$data->{Properties}};
			%Classes    = %{$data->{Classes}};
			return;
		}
	}

	my $model = RDF::Trine::Model->new;
	RDF::Trine::Parser->parse_file_into_model(SCHEMA_NS, $owl_path, $model);

	$model->subjects($RDF->type, $OWL->Class)->each(sub {
		return unless $_[0]->is_resource;
		my ($c_ns, undef) = $_[0]->qname;
		return unless $c_ns eq SCHEMA_NS;
		
		$self->_load_schema_class($model, $_[0]);
	});
	
	$self->_load_schema_superclasses($model);

	$model->subjects($RDF->type, $OWL->ObjectProperty)->each(sub {
		return unless $_[0]->is_resource;
		my ($p_ns, undef) = $_[0]->qname;
		return unless $p_ns eq SCHEMA_NS;
		
		$self->_load_schema_property($model, $_[0], 0);
	});

	$model->subjects($RDF->type, $OWL->DatatypeProperty)->each(sub {
		return unless $_[0]->is_resource;
		my ($p_ns, undef) = $_[0]->qname;
		return unless $p_ns eq SCHEMA_NS;
		
		$self->_load_schema_property($model, $_[0], 1);
	});
	
	open my $fh, '>', $json_path;
	print $fh encode_json({Classes=>\%Classes,Properties=>\%Properties});
	return;
}

sub _load_schema_class
{
	my ($self, $model, $class) = @_;
	
	my @isa = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($class, $RDFS->subClassOf);
	
	$Classes{$class->uri} = { isa => \@isa };
}

sub _load_schema_superclasses
{
	my ($self, $model) = @_;
		
	my $activity = 1;
	while ($activity)
	{
		$activity = 0;
		
		foreach my $class (keys %Classes)
		{
			my $grandkids = Set::Scalar->new;
			foreach my $kid (@{ $Classes{$class}{isa} })
			{
				$grandkids->insert(@{ $Classes{$kid}{isa} });
			}
			$grandkids->delete(@{ $Classes{$class}{isa} });
			
			my @grandkids = $grandkids->members;
			$activity += scalar @grandkids;
			push @{ $Classes{$class}{isa} }, @grandkids;
		}
	}
	
	foreach my $class (keys %Classes)
	{
		foreach my $kid (@{ $Classes{$class}{isa} })
		{
			$Classes{$kid}{subclasses} ||= Set::Scalar->new;
			$Classes{$kid}{subclasses}->insert($class);
		}
	}
	
	foreach my $class (keys %Classes)
	{
		$Classes{$class}{subclasses} = defined $Classes{$class}{subclasses}
			? [ $Classes{$class}{subclasses}->members ]
			: [] ;
	}
}

sub _load_schema_property
{
	my ($self, $model, $prop, $is_dt) = @_;

	foreach my $X (qw{domain range})
	{
		my $set = Set::Scalar->new;
		
		$model->objects($prop, $RDFS->$X)->each(sub {
			if ($_[0]->is_resource)
			{
				$set->insert($_[0]->uri);
			}
			else
			{
				my ($unionOf) = $model->objects($_[0], $OWL->unionOf);
				my  @unionOf  = $model->get_list($unionOf);
				foreach my $c (@unionOf)
				{
					next unless $c->is_resource;
					$set->insert($c->uri);
				}
			}
		});
		
		$Properties{$prop->uri}{$X} = [ $set->members ];
	}
	
	unless ($is_dt)
	{
		my @dtclasses = (
			@{  $Classes{SCHEMA_NS.'DataType'}{subclasses}  },
			$SCHEMA->DataType->uri,
			$RDFS->Literal->uri,
			);
		RANGE: foreach my $range (@{ $Properties{$prop->uri}{range} })
		{
			foreach my $dtclass (@dtclasses)
			{
				if ($range eq $dtclass)
				{
					$is_dt++;
					last RANGE;
				}
			}
		}
	}
	
	$Properties{$prop->uri}{is_dt} = $is_dt;
}

1;
