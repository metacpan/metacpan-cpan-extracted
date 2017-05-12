

use strict;
use lib 't/springfield';
use Springfield;

sub compare_hash {
  my ($a,$b) = @_;
  foreach (keys %{$a}) {
    return undef unless ($a->{$_} eq $b->{$_});
  }
  foreach (keys %{$b}) {
    return undef unless ($a->{$_} eq $b->{$_});
  }
  1;
}

Springfield::begin_tests(17);

#$Tangram::TRACE = \*STDOUT;

{
	my $storage = Springfield::connect_empty();

	my $homer = NaturalPerson->new( firstName => 'Homer',
					name => 'Simpson',
					opinions => { work => 'bad',
						      food => 'good',
						      beer => 'better' } );

	$storage->insert($homer);

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	testcase(compare_hash($homer->{opinions},
			      { work => 'bad',
				food => 'good',
				beer => 'better' }));

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	$homer->{opinions}->{'sex'} = 'good';
	$storage->update($homer);

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	testcase(compare_hash($homer->{opinions},
			      { work => 'bad',
				food => 'good',
				beer => 'better',
				sex => 'good' }));

	delete $homer->{opinions}->{work};
	$storage->update($homer);

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	testcase(compare_hash($homer->{opinions},
			      { food => 'good',
				beer => 'better',
				sex => 'good' }));

	$homer->{opinions}->{'sex'} = 'fun';
	$storage->update($homer);

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	testcase(compare_hash($homer->{opinions},
			      { food => 'good',
				beer => 'better',
				sex => 'fun' }));

	delete $homer->{opinions};
	$storage->update($homer);

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	my ($homer) = $storage->select('NaturalPerson');

	testcase(compare_hash($homer->{opinions}, {}));

	$homer->{opinions} = { work => 'bad',
			       food => 'good',
			       beer => 'better' };
	$storage->update($homer);
	$storage->disconnect();
}

leaktest();

# prefetch

{
	my $storage = Springfield::connect();

	my ($remote) = $storage->remote('NaturalPerson');
	$storage->prefetch($remote, 'opinions');
	my ($homer) = $storage->select($remote, $remote->{firstName} eq 'Homer');

	{
		local ($storage->{db});
		testcase(compare_hash($homer->{opinions},
				      { work => 'bad',
					food => 'good',
					beer => 'better' }));
	}

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();

	my ($remote) = $storage->remote('NaturalPerson');
	$storage->prefetch($remote, 'opinions', $remote->{firstName} eq 'Homer');

	my ($homer) = $storage->select($remote, $remote->{firstName} eq 'Homer');

	{
		local ($storage->{db});
		testcase(compare_hash($homer->{opinions},
				      { work => 'bad',
					food => 'good',
					beer => 'better' }));
	}

	$storage->disconnect();
}

leaktest();

{
	my $storage = Springfield::connect();
	$storage->erase( $storage->select('NaturalPerson'));
	Springfield::test( 0 == $storage->connection()->selectall_arrayref("SELECT COUNT(*) FROM NaturalPerson_opinions")->[0][0] );
	$storage->disconnect();
}
