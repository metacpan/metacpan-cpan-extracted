package MooseX::ArrayRef::Meta::Class;

BEGIN {
	$MooseX::ArrayRef::Meta::Class::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ArrayRef::Meta::Class::VERSION   = '0.005';
}

use Moose::Role;

has next_index => (
	is         => 'rw',
	isa        => 'Num',
	default    => 0,
);

has slot_count => (
	is         => 'rw',
	isa        => 'Num',
	lazy_build => 1,
);

# This was originally a builder for a lazy attribute, but it was built
# too early (before all attributes existed), so I just do it on the fly
# now. It would be nice if some of this could be memoized though.
sub slot_to_index_map
{
	my $meta = shift;
	
	my @supers =
		reverse
		grep { not /^Moose::Object$/ }
		grep { not ref }
		$meta->superclasses;
	my %parent = map { $supers[$_] => $_ } 0 .. $#supers;
	$parent{ $meta->name } = scalar @supers;
	
	my @slots =
		map { $_->slots }
		sort {
			$parent{ $a->associated_class->name } <=> $parent{ $b->associated_class->name }
			or $a->insertion_order <=> $b->insertion_order
			or $a->name cmp $b->name
		}
		$meta->get_all_attributes;
		
	+{ map { $slots[$_] => $_ } 0 .. $#slots }
}

sub slot_index
{
	my ($meta, $slot_name) = @_;
	
	my $map = $meta->slot_to_index_map;
	return $map->{$slot_name} if exists $map->{$slot_name};
	
	confess "Unknown slot: $slot_name";
}

sub _build_slot_count
{
	my $meta = shift;
	my $sum  = 0;
	foreach my $attr ($meta->get_all_attributes)
	{
		my @slots = $attr->slots;
		$sum += scalar @slots;
	}
	$sum;
}

before superclasses => sub
{
	my $meta = shift;
	if (@_)
	{
		my @supers = grep { not ref } @_;
		confess "MooseX::ArrayRef does not support multiple inheritance"
			if @supers > 1;
		confess "MooseX::ArrayRef cannot extend a non-MooseX::ArrayRef class"
			unless Class::MOP::class_of($supers[0])->can('slot_to_index_map');
	}
};

1;

