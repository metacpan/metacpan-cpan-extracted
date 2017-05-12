
use strict;

#Set up expected results
our @fake_tres_data =
(	
	{ id => 1, type => 'cpu' },
	{ id => 2, type => 'mem', },
	{ id => 3, type => 'energy', },
	{ id => 4, type => 'node', },
	{ id => 5, type => 'gres', name => 'gpu', },
	{ id => 6, type => 'gres', name => 'phi', },
);

sub generate_fake_data()
{	
	my @fakedata = ();
	foreach my $record (@fake_tres_data)
	{	my $obj = Slurm::Sacctmgr::Tres->new(%$record);
		push @fakedata, $obj;
	}
	return [ @fakedata ];
}
