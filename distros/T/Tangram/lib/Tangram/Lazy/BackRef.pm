
package Tangram::Lazy::BackRef;

use vars qw(@ISA);
 @ISA = qw( Tangram::Lazy::Ref );

sub FETCH
{
	my $self = shift;
	my ($storage, $id, $member, $refid, $class, $field) = @$self;
	my $obj = $storage->{objects}{$id};

	my $owner = $storage->remote($class);
	my ($refobj) = $storage->select($owner, $owner->{$field}->includes($obj));
#	my $refobj = $storage->load($refid);

	untie $obj->{$member};
	$obj->{$member} = $refobj;	# weak
	return $refobj;
}

1;
