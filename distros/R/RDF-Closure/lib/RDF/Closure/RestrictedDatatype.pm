package RDF::Closure::RestrictedDatatype;

BEGIN {
	$RDF::Closure::RestrictedDatatype::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Closure::RestrictedDatatype::VERSION   = '0.001';
}

use 5.008;
use strict;
use utf8;

use Error qw':try';
use RDF::Closure::DatatypeHandling;
use RDF::Trine qw[iri];
use RDF::Trine::Namespace qw[XSD RDF RDFS OWL];
use Scalar::Util qw[blessed];

#: Constant for datatypes using min, max (inclusive and exclusive):
use constant MIN_MAX               => 'MIN_MAX';
#: Constant for datatypes using length, minLength, and maxLength (and nothing else)
use constant LENGTH                => 'LENGTH';
#: Constant for datatypes using length, minLength, maxLength, and pattern
use constant LENGTH_AND_PATTERN    => 'LENGTH_AND_PATTERN';
#: Constat for datatypes using length, minLength, maxLength, pattern, and lang range
use constant LENGTH_PATTERN_LRANGE => 'LENGTH_PATTERN_LRANGE';

#: Dictionary of all the datatypes, keyed by category
our %Datatypes_per_facets = (
	MIN_MAX => [
		$OWL->rational, $XSD->decimal, $XSD->integer,
		$XSD->nonNegativeInteger, $XSD->nonPositiveInteger,
		$XSD->positiveInteger, $XSD->negativeInteger,
		$XSD->long, $XSD->short, $XSD->byte,
		$XSD->unsignedLong, $XSD->unsignedInt, $XSD->unsignedShort, $XSD->unsignedByte,
		$XSD->double, $XSD->float,
		$XSD->dateTime, $XSD->dateTimeStamp, $XSD->time, $XSD->date,
		],
	LENGTH => [ $XSD->hexBinary, $XSD->base64Binary ],
	LENGTH_AND_PATTERN => [
		$XSD->anyURI, $XSD->string, $XSD->NMTOKEN, $XSD->Name, $XSD->NCName,
		$XSD->language, $XSD->normalizedString,
		],
	LENGTH_PATTERN_LRANGE => [ $RDF->PlainLiteral ],
	);

our %facet_to_method = (
	MIN_MAX               => [qw(_check_max_exclusive _check_min_exclusive _check_max_inclusive _check_min_inclusive)],
	LENGTH                => [qw(_check_min_length _check_max_length _check_length)],
	LENGTH_AND_PATTERN    => [qw(_check_min_length _check_max_length _check_length _check_pattern)],
	LENGTH_PATTERN_LRANGE => [qw(_check_min_length _check_max_length _check_length _check_lang_range)],
	);

our @facetable_datatypes = map { @$_ } values %Datatypes_per_facets;

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	$self->__init__(@args);
	return $self;
}

sub extract_from_graph
{
	my ($class, $graph, $dth) = @_;
	my @retval;
	
	$graph->subjects($RDF->type, $RDFS->Datatype)->each(sub{
		my $dtype = shift;
		my $base_type;
		my @facets;
		eval
		{
			my @base_types = $graph->objects($dtype, $OWL->onDatatype);
			if (@base_types)
			{
				if (exists $base_types[1])
				{
					die(sprintf("Several base datatype for the same restriction %s", $dtype));
				}
				else
				{
					$base_type = $base_types[0];
					if (grep { $base_type->equal($_) } @facetable_datatypes)
					{
						my @rlists = $graph->objects($dtype, $OWL->withRestrictions);
						if (exists $rlists[1])
						{
							die(sprintf("More than one facet lists for the same restriction %s", $dtype));
						}
						elsif (@rlists)
						{
							my @final_facets;
							foreach my $r ($graph->get_list(@rlists))
							{
								$graph->get_statements($r, undef, undef)->each(sub{
									my (undef, $facet, $lit) = (shift)->nodes;
									push @final_facets, [$facet, $lit];
								});
							}
							# We do have everything we need:
							my $new_datatype = $class->new($dtype, $base_type, \@final_facets, $dth);
							push @retval, $new_datatype;
						}
					}
				}
			}
		};
	});
	
	return @retval;
}

sub __init__
{
	my ($self, $type_uri, $base_type, $facets, $dt_handler) = @_;
	
	$dt_handler ||= RDF::Closure::DatatypeHandling->new;
	
	$self->{datatype}   = $type_uri;
	$self->{base_type}  = $base_type;
	$self->{dt_handler} = $dt_handler;
	
	my $converter = $dt_handler->mapping("$base_type");
	unless (defined $converter)
	{
		throw Error::Simple("No facet is implemented for datatype %s", $base_type);
	}
	$self->{converter}  = $converter;
	
	$self->{minExclusive} = undef;
	$self->{maxExclusive} = undef;
	$self->{minInclusive} = undef;
	$self->{maxInclusive} = undef;
	$self->{length}       = undef;
	$self->{maxLength}    = undef;
	$self->{minLength}    = undef;
	$self->{pattern}      = [];
	$self->{langRange}    = [];
	
	foreach my $pair (@$facets)
	{
		my ($facet, $value) = @$pair;
		$value = $self->{dt_handler}->literal_to_perl($value) if ref $value;
		
		if ($facet->equal($XSD->minInclusive) and (!defined $self->{minInclusive} or $self->{minInclusive} < $value))
		{
			$self->{minInclusive} = $value;
		}
		elsif ($facet->equal($XSD->maxInclusive) and (!defined $self->{maxInclusive} or $self->{maxInclusive} > $value))
		{
			$self->{maxInclusive} = $value;
		}
		elsif ($facet->equal($XSD->minExclusive) and (!defined $self->{minExclusive} or $self->{minExclusive} < $value))
		{
			$self->{minExclusive} = $value;
		}
		elsif ($facet->equal($XSD->maxExclusive) and (!defined $self->{maxExclusive} or $self->{maxExclusive} > $value))
		{
			$self->{maxExclusive} = $value;
		}
		elsif ($facet->equal($XSD->minLength) and (!defined $self->{minLength} or $self->{minLength} < $value))
		{
			$self->{minLength} = $value;
		}
		elsif ($facet->equal($XSD->maxLength) and (!defined $self->{maxLength} or $self->{maxLength} > $value))
		{
			$self->{maxLength} = $value;
		}
		elsif ($facet->equal($XSD->length))
		{
			$self->{length} = $value;
		}
		elsif ($facet->equal($XSD->pattern))
		{
			push @{$self->{pattern}}, qr($value)so;
		}
		elsif ($facet->equal($RDF->langRange))
		{
			push @{$self->{langRange}}, $value;
		}
	}
	
	$self->{check_methods} = [];
	
	LOOP: foreach my $cat (keys %Datatypes_per_facets)
	{
		if (grep {$_->equal($base_type)} @{$Datatypes_per_facets{$cat}})
		{
			$self->{category}      = $cat;
			$self->{check_methods} = $facet_to_method{$cat};
			last LOOP;
		}
	}
}

sub datatype  { return $_[0]->{datatype}; }
sub base_type { return $_[0]->{base_type}; }

sub check
{
	my ($self, $value, $dt) = @_;
	
	if (blessed($value) and $value->isa('RDF::Trine::Node'))
	{
		$dt  ||= $value->literal_datatype;
		$value = $self->{dt_handler}->literal_to_perl($value);
	}
	
	foreach my $method (@{$self->{check_methods}})
	{
		return unless $self->$method($value, $dt);
	}
	
	return $self;
}

sub _check_min_exclusive
{
	my ($self, $value) = @_;
	return $self unless defined $self->{minExclusive};
	return ($self->{minExclusive} < $value);
}

sub _check_max_exclusive
{
	my ($self, $value) = @_;
	return $self unless defined $self->{maxExclusive};
	return ($self->{maxExclusive} > $value);
}

sub _check_min_inclusive
{
	my ($self, $value) = @_;
	return $self unless defined $self->{minInclusive};
	return ($self->{minInclusive} <= $value);
}

sub _check_max_inclusive
{
	my ($self, $value) = @_;
	return $self unless defined $self->{maxInclusive};
	return ($self->{maxInclusive} >= $value);
}

sub _check_min_length
{
	my ($self, $value) = @_;
	return $self unless defined $self->{minLength};
	return ($self->{minLength} <= length($value));
}

sub _check_max_length
{
	my ($self, $value) = @_;
	return $self unless defined $self->{maxLength};
	return ($self->{maxLength} >= length($value));
}

sub _check_length
{
	my ($self, $value) = @_;
	return $self unless defined $self->{length};
	return ($self->{length} == length($value));
}

sub _check_pattern
{
	my ($self, $value) = @_;
	
	foreach my $pattern (@{$self->{pattern}})
	{
		return unless $value =~ $pattern;
	}
	
	return $self;
}

sub _check_lang_range
{
	my ($self, $value) = @_;
	
	return unless blessed($value) && $value->can('lang_range_check');
	
	foreach my $r (@{$self->{langRange}})
	{
		return unless $value->lang_range_check($r);
	}
	
	return $self;
}

1;
