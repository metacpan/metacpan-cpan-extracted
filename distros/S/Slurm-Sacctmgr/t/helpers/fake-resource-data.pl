use strict;

our @fake_resource_data = 
(	{ 	name => 'foo',
		server => 'rlmserver.umd.edu',
		count => 100,
		servertype => 'rlm',
		percentallowed => 100,
		cluster => 'yottascale',
	},

	{	name => 'matlab',
		server => 'flexlm.umd.edu',
		count => 500,
		servertype => 'flexlm',
		percentallowed => 90,
		cluster => 'yottascale',
	},

	{	name => 'matlab',
		server => 'flexlm.umd.edu',
		count => 500,
		servertype => 'flexlm',
		percentallowed => 10,
		cluster => 'testcluster',
	},
);

foreach my $tmpdata (@fake_resource_data)
{	unless ( exists $tmpdata->{allocated} )
	{	$tmpdata->{allocated} = 100;
	}
	unless ( exists $tmpdata->{type} )
	{	$tmpdata->{type} = 'License';
	}
}

sub generate_fake_data()
{	my @fakedata = ();

	foreach my $record (@fake_resource_data)
	{	my $rec = { %$record };
		$rec->{type} = 'License' unless exists $rec->{type};
		$rec->{allocated} = 100 unless exists $rec->{allocated};
		my $obj = Slurm::Sacctmgr::Resource->new(%$rec);
		push @fakedata, $obj;
	}

	return [ @fakedata ];
}
		
1;
