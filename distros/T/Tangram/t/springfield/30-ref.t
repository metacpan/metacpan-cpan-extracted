

use lib "t/springfield";
use Springfield;

my %id;

Springfield::begin_tests(11);

{
	$storage = Springfield::connect_empty;

	my $homer = NaturalPerson->new( firstName => 'Homer' );
	my $marge = NaturalPerson->new( firstName => 'Marge' );

	$homer->{partner} = $marge;

	$id{Marge} = $storage->insert($marge);
	$id{Homer} = $storage->insert($homer);

	$storage->disconnect();
}

Springfield::leaktest;

{
	$storage = Springfield::connect();

	my ($p1, $p2) = $storage->remote(qw( NaturalPerson NaturalPerson ));

	my ($homer, $other) = $storage->select( $p1,
											($p1->{partner} == $p2) & ($p2->{firstName} eq 'Marge') );

	Springfield::test( $homer && !$other );

	$storage->disconnect();
}

Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $marge = $storage->load( $id{Marge} );

	my ($p1) = $storage->remote(qw( NaturalPerson ));

	my ($marge2, $other) = $storage->select( $p1, $p1 == $marge );

	Springfield::test( $marge2 && !$other );

	$storage->disconnect();
}

Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $marge = $storage->load( $id{Marge} );

	my ($p1, $p2) = $storage->remote(qw( NaturalPerson NaturalPerson ));

	my $ff = $p1 == $p1;

	my ($homer, $other) = $storage->select( $p1, $p1->{partner} == $marge );

	Springfield::test( $homer && !$other );

	$storage->disconnect();
}

Springfield::leaktest;

{

	$storage = Springfield::connect_empty();

	$ids{Homer} = $storage->insert( NaturalPerson->new(
        name => 'Homer',
		credit => Credit->new( limit => 1000 ) ) );

	my @credits = $storage->select('Credit');
	Springfield::test( @credits == 1 );

	$storage->disconnect();
}

Springfield::leaktest;

{
	$storage = Springfield::connect();

	my $homer = $storage->load( $ids{Homer} );
	print $homer->{credit}, "\n";
	$storage->erase( $homer );

	my @credits = $storage->select('Credit');
	Springfield::test( @credits == 0 );

	$storage->disconnect();
}

Springfield::leaktest;
