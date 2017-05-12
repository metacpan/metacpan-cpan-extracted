package RDF::DOAP::Utils;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use strict;
use warnings;

use RDF::DOAP::Types -types;
use match::simple 'match';
use List::MoreUtils 'uniq';

use MooseX::AttributeTags (
	WithURI   => [
		uri       => [ is => 'ro', isa => Identifier, coerce => 1, required => 1 ],
		multi     => [ is => 'ro', isa => Bool, default  => 0 ],
	],
	Gathering => [
		gather_as => [ is => 'ro', isa => ArrayRef[Str], default  => sub { [] } ],
	],
);

use Exporter::Tiny ();
our @ISA         = qw( Exporter::Tiny );
our @EXPORT_OK   = qw( WithURI Gathering );
our %EXPORT_TAGS = (
	traits => [qw( WithURI Gathering )]
);

our %seen;

sub _gather_objects
{
	my ($self, $relation) = @_;
	return if $seen{$self}++;
	
	if (ArrayRef->check($self))
	{
		return uniq(
			grep defined, map _gather_objects($_, $relation), grep defined, @$self
		);
	}
	
	if (Object->check($self))
	{
		return unless $self->isa('Moose::Object');
		
		my @local =
			grep defined,
			map ArrayRef->check($_) ? @$_ : $_,
			map $_->get_value($self),
			grep $_->does(Gathering) && match($relation, $_->gather_as),
			$self->meta->get_all_attributes;
		
		my @recursive =
			grep defined,
			map _gather_objects($_, $relation),
			grep defined,
			map $_->get_value($self),
			grep !($_->does(Gathering) && match($relation, $_->gather_as)),
			$self->meta->get_all_attributes;
		
		return uniq(@local, @recursive);
	}
}

sub gather_objects
{
	local %seen;
	grep ref, _gather_objects(@_);
}

1;
