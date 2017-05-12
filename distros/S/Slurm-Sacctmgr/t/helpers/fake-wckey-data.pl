
use strict;

#Set up expected results
our @fake_wckey_data =
(	
	{ wckey=>'aaa', cluster=>'yottascale', user=>'payerle' },
	{ wckey=>'aaa', cluster=>'yottascale', user=>'root' },
	{ wckey=>'bbb', cluster=>'yottascale', user=>'root' },
	{ wckey=>'ccc', cluster=>'test1', user=>'payerle' },
	{ wckey=>'ddd', cluster=>'yottascale' , user=>'payerle' },
);

sub generate_fake_data()
{	
	my @fakedata = ();
	foreach my $record (@fake_wckey_data)
	{	my $obj = Slurm::Sacctmgr::WCKey->new(%$record);
		push @fakedata, $obj;
	}
	return [ @fakedata ];
}
