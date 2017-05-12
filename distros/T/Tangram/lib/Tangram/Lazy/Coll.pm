
package Tangram::Lazy::Coll;

use strict;

use Carp qw(confess);

sub TIESCALAR
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;	# [ $type, $storage, $id, $member, $class ]
}

sub FETCH
{
	my $self = shift;
	my ($type, $def, $storage, $id, $member, $class) = @$self;
	my $obj = $storage->{objects}{$id}
	    or confess "FETCH failed to get object $id!";
	my $coll = $type->demand($def, $storage, $obj, $member, $class);
	untie $obj->{$member};
	$obj->{$member} = $coll;
	my ($pkg,$fn,$l) = caller;
	return $coll;
}

sub STORE
{
	my ($self, $coll) = @_;
	my ($type, $def, $storage, $id, $member, $class) = @$self;
	my $obj = $storage->{objects}{$id}
	    or confess "FETCH failed to get object $id!";
	$type->demand($def, $storage, $obj, $member, $class);

	untie $obj->{$member};

	$obj->{$member} = $coll;
}

sub storage {
    my ($self) = (@_);
    return $self->[2];
}

1;
