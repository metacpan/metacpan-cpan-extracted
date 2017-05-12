
use strict;

our @fake_user_data =
(	
	{ user=>'aaa', defaultaccount=>'test' },
	{ user=>'bbb', defaultaccount=>'test', adminlevel=>'Administrator' },
	{ user=>'ccc', defaultaccount=>'abc114', adminlevel=>'Administrator' },
	{ user=>'ddd', defaultaccount=>'test' },
);


sub generate_fake_data()
#Generates a list ref of objects from fake data above
{	my $fake_data = [];

	foreach my $record (@fake_user_data)
	{	my $user = $record->{user};
		my $defacct = $record->{defaultaccount};
		my $adminlevel = $record->{adminlevel} || 'None';
		my $coords = $record->{coordinators};
		my $obj = Slurm::Sacctmgr::User->new(
			user => $user,
			defaultaccount => $defacct,
			adminlevel => $adminlevel,
			coordinators => $coords,
			);
		push @$fake_data, $obj;
	}

	return $fake_data;
}

1;
