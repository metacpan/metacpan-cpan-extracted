
use strict;

our @fake_assoc_data =
(	
	{ testname=>'root assoc',
		account=>'root', parentid=>0, parentname=>undef,
	},
	{ testname=>'root assoc (root)',
		account=>'root', user=>'root',
	},
		
	#Use TRES only for this one
	{ testname=>'abc124 main',
		account=>'abc124', 
		maxjobs=>1000, maxsubmitjobs=>2000, maxwall=>4000,
		grpjobs=>1500, grpsubmitjobs=>3000, grpwall=>6000, qos=>'high,normal',
		maxtresmins=>{ cpu => 60000} , 
		maxtres => { cpu=>100, node=>5 },  
		grptresmins=>{ cpu => 90000 }, 
		grptres => { cpu=>150, node => 7, 'gres/gpu' => 5 }, 
	},

	#Use preTRES only for this one
	{ testname=>'abc124 payerle',
		account=>'abc124', 
		parentid => 3, parentname=>'abc124',
		user=>'payerle',
		maxcpumins=>40000,
	},
);

sub generate_fake_data()
#Generates a list ref of Slurm::Sacctmgr::Association instances from @fakedata
#We need a new list each time as strip changes things.
{	
	my $fake_data = [];
	my $tmpid = 0;
	foreach my $fakedatum (@fake_assoc_data)
	{	my $tstname = delete $fakedatum->{testname};
		$tmpid++;
		my $tmplft = 100000 + 1000 * $tmpid;
		my $tmprgt = 100999 + 1000 * $tmpid;
		#Some defaults
		$fakedatum->{cluster} = 'yottascale' unless exists $fakedatum->{cluster};
		$fakedatum->{fairshare} = 1 unless exists $fakedatum->{fairshare};
		$fakedatum->{id} = $tmpid unless exists $fakedatum->{id};
		$fakedatum->{lft} = $tmplft unless exists $fakedatum->{lft};
		$fakedatum->{rgt} = $tmprgt unless exists $fakedatum->{rgt};
		$fakedatum->{parentid} = 1 unless exists $fakedatum->{parentid};
		$fakedatum->{parentname} = 'root' unless exists $fakedatum->{parentname};
		$fakedatum->{defaultqos} = 'normal' unless exists $fakedatum->{defaultqos};
		$fakedatum->{partition} = 'gpus' unless exists $fakedatum->{partition};
		
		my $obj = Slurm::Sacctmgr::Association->new(%$fakedatum);

		push @$fake_data, $obj;
	}

	return $fake_data;
}

#------	Routine to strip TRES data cannot fake in non-TRES versions

sub strip_all_tres_but_cpu_nodes_from_obj($)
#Takes Slurm::Sacctmgr::Association instance and strips all TRES fields except CPU and node
{	my $instance = shift;

	my @tres_fields = qw( grptresmins grptresrunmins grptres maxtresmins maxtres);

	foreach my $tresfld (@tres_fields)
	{	my $hash = $instance->$tresfld;
		next unless $hash && ref($hash) eq 'HASH';

		my @keys = keys %$hash;
		my %keys = map { $_ => undef } @keys;
		delete $keys{cpu};
		delete $keys{node};
		@keys = keys %keys;
		foreach my $key (@keys)
		{	delete $hash->{$key};
		}
	}
}

sub strip_all_tres_but_cpu_nodes($)
#Takes a list ref of Slurm::Sacctmgr::Association instances and calls strip_all_tres_but_cpu_nodes_fom_obj
#on each item in turn
{	my $list = shift;
	return unless $list && ref($list) eq 'ARRAY';

	foreach my $inst (@$list)
	{	strip_all_tres_but_cpu_nodes_from_obj($inst);
	}
	return $list;
}

1;
