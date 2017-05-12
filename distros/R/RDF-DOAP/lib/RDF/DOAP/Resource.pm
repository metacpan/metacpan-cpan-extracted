package RDF::DOAP::Resource;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;

use Carp;
use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;
use Scalar::Util qw( weaken refaddr );

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);

has rdf_about => (
	is         => 'ro',
	isa        => Identifier,
	coerce     => 1,
	predicate  => 'has_rdf_about',
);

has rdf_model => (
	is         => 'ro',
	isa        => Model,
	predicate  => 'has_rdf_model',
);

has rdf_type => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Identifier],
	coerce     => 1,
	uri        => $rdf->type,
	multi      => 1,
	default    => sub { [] },
);

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => $rdfs->$_,
) for qw( label comment );

has see_also => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Identifier],
	coerce     => 1,
	uri        => $rdfs->seeAlso,
	multi      => 1,
	lazy       => 1,
	default    => sub {
		my $self = shift;
		if ($self->has_rdf_about && $self->rdf_about =~ /^tdb:[^:]*:(.*)$/)
		{
			return [ Identifier->coerce($1) ];
		}
		return [];
	},
);

our $MODEL;
my %objects;
sub rdf_load
{
	my $class = shift;
	my $identifier = Identifier->assert_coerce( $_[0] );
	
	my $model      = $_[1] ? Model->assert_return( $_[1] ) : $MODEL or die;

	return $objects{ refaddr($model) }{ $identifier }
		if $objects{ refaddr($model) }{ $identifier };
	
	my (%attr, %multi);
	for my $a ($class->meta->get_all_attributes)
	{
		$a->does(WithURI) or next;
		$attr{ $a->uri }  = $a->init_arg || $a->name;
		$multi{ $a->uri } = $a->multi;
	}
	
	my %args = (
		rdf_about => $identifier,
		rdf_model => $model,
	);
	my $iter = $model->get_statements($identifier, undef, undef);
	while (my $st = $iter->next)
	{
		my $name = $attr{ $st->predicate } or next;
		
		if ($multi{ $st->predicate })
		{
			push @{ $args{$name} ||= [] }, $st->object;
		}
		else
		{
			$args{$name} ||= $st->object;
		}
	}
	
	local $MODEL = $model;
	my $self = $objects{ refaddr($model) }{ $identifier } = $class->new(%args);
	weaken($objects{ refaddr($model) }{ $identifier });
	return $self;
}

sub rdf_get
{
	my $self = shift;
	croak "This object cannot rdf_get; stopped"
		unless $self->has_rdf_model && $self->has_rdf_about;
	
	my @values = $self->rdf_model->objects_for_predicate_list($self->rdf_about, @_);
	wantarray ? @values : $values[0];
}

sub rdf_get_literal
{
	my $self = shift;
	my @values = grep $_->is_literal, $self->rdf_get(@_);
	wantarray ? @values : $values[0];
}

sub rdf_get_uri
{
	my $self = shift;
	my @values = grep $_->is_resource, $self->rdf_get(@_);
	wantarray ? @values : $values[0];
}

sub TO_JSON
{
	my $self = shift;
	$self->fixes if $self->can('fixes');
	my $hash = +{ %$self };
	delete $hash->{$_} for qw( rdf_about rdf_model );
	for my $k (keys %$hash) {
		if (blessed $hash->{$k} and $hash->{$k}->isa('RDF::Trine::Node')) {
			$hash->{$k} = $hash->{$k}->as_ntriples;
		}
		if (ref $hash->{$k} eq 'ARRAY') {
			$hash->{$k} = [ map {
				(blessed $_ and $_->isa('RDF::Trine::Node')) ? $_->as_ntriples : $_
			} @{ $hash->{$k} } ];
		}
	}
	$hash->{'@'} = $self->rdf_about->as_ntriples if $self->has_rdf_about;
#	$hash->{__ISA__} = [ $self->meta->linearized_isa ];
#	$hash->{__DOES__}  = [ map $_->name, $self->meta->calculate_all_roles_with_inheritance ];
	return $hash;
}

sub dump_json
{
	require JSON;
	JSON::to_json(
		shift(),
		{ pretty => 1, canonical => 1, convert_blessed => 1 },
	);
}

sub isa
{
	my $self = shift;
	
	return grep($_[0]->equal($_), @{$self->rdf_type})
		if Identifier->check(@_);
	
	$self->SUPER::isa(@_);
}

1;
