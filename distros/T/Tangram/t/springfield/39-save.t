

# the functionality this test tests can probably be moved into type
# specific tests

use lib 't/springfield';
use Springfield;

my %id;

Springfield::begin_tests(4);

{
	$storage = Springfield::connect_empty;

	my $bart = NaturalPerson->new( firstName => 'Bart' );

	$bart->{belongings} = [
	  Item->new( name => 'Skateboard', owner => $bart ),
	  Item->new( name => 'Bike', owner => $bart )
	];

	$id{Bart} = $storage->insert($bart);
	$storage->disconnect();
}

#Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $bart = $storage->load($id{Bart});

	Springfield::test( $bart && 
			   $bart->{belongings}->[0]->{name} eq 'Skateboard' &&
			   $bart->{belongings}->[1]->{name} eq 'Bike');

	$storage->disconnect();
}

#Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $bart = $storage->load($id{Bart});
	
	push @{$bart->{belongings}}, Item->new( name => 'Sneakers', owner => $bart);

	$storage->update($bart);
	$storage->disconnect();
}

#Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $bart = $storage->load($id{Bart});

	Springfield::test( $bart && 
			   $bart->{belongings}->[0]->{name} eq 'Skateboard' &&
			   $bart->{belongings}->[1]->{name} eq 'Bike' &&
			   $bart->{belongings}->[2]->{name} eq 'Sneakers');

	$storage->disconnect();
}

#Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $bart = $storage->load($id{Bart});
	
	$bart->{belongings}->[0]->{name} = 'T-shirt';

	$storage->update($bart);
	$storage->disconnect();
}

#Springfield::leaktest;

my $export_id;
{
	$storage = Springfield::connect();

	my $bart = $storage->load($id{Bart});
	$export_id = $storage->export_object($bart);

	Springfield::test( $bart && 
			   $bart->{belongings}->[0]->{name} eq 'T-shirt' &&
			   $bart->{belongings}->[1]->{name} eq 'Bike' &&
			   $bart->{belongings}->[2]->{name} eq 'Sneakers');

	$storage->disconnect();
}

{
	$storage = Springfield::connect();

	my $bart = $storage->import_object("NaturalPerson", $export_id);

	Springfield::test( $bart && 
			   $bart->{belongings}->[0]->{name} eq 'T-shirt' &&
			   $bart->{belongings}->[1]->{name} eq 'Bike' &&
			   $bart->{belongings}->[2]->{name} eq 'Sneakers');

	$storage->disconnect();
}

#{
#	$storage = Springfield::connect_empty;

#	my $bart = NaturalPerson->new( firstName => 'Bart' );

#	$id{Bart} = $storage->insert($bart);
#	Springfield::empty($storage);
#	eval { $storage->update($bart) };
#	Springfield::test($@);

#	$storage->disconnect();
#}

#Springfield::leaktest;
