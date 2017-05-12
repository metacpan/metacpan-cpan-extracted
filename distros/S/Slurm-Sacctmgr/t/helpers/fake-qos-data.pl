
use strict;
#===============================================================
#		Set up expected results
#===============================================================
our @fake_qos_data =
(	
	{ 	name=>'high-priority', 
		description=>'High priority QoS',
		id => 1,
		gracetime=>120, 
		grpjobs=>75, grpsubmitjobs=>100, grpwall=>600,
		maxjobs=>75, maxsubmitjobs=>100, maxwall=>600,
		preempt=>'scavenger', preemptmode=>'cluster',
		priority=>500, usagefactor=>2,

		#Do tres based
		grptresmins=> "cpu=6000",
		grptres=> "cpu=50,node=10,mem=800000",
		maxtresmins=> "cpu=12000",
		maxtresperjob=> "cpu=100,node=20,mem=24000000",
		maxtresperuser=> "cpu=25,node=5,mem=320000",
	},

	{ 	name=>'standard', 
		description=>'standard priority QoS',
		id => 2,
		gracetime=>60, 
		maxjobs=>150, maxsubmitjobs=>200, maxwall=>1200,
		preempt=>'scavenger', preemptmode=>'cluster',
		priority=>100, usagefactor=>1,

		#Do preTRES
		maxcpus=>200, maxnodes=>40,
		maxcpumins=>24000, 
		maxcpusperuser=>50, maxnodesperuser=>10,
	},

	{ 	name=>'scavenger', 
		description=>'bottom feeder QoS',
		id => 3,
		gracetime=>10, 
		preemptmode=>'cluster',
		priority=>0, usagefactor=>0,
	},

);

sub generate_fake_objs()
#Generates a list ref of Slurm::Sacctmgr::Qos instances from @fake_qos_data
#We need a new list each time as strip changes things.
{	
	my $fake_data = [];
	foreach my $rec (@fake_qos_data)
	{	
		my $obj = Slurm::Sacctmgr::Qos->new(%$rec);

		push @$fake_data, $obj;
	}

	return $fake_data;
}

#Routines to strip TRES data not available in non-TRES versions

sub strip_all_tres_but_cpu_nodes_from_obj($)
#Takes Slurm::Sacctmgr::Cluster instance and strips all TRES fields except CPU and node
{	my $instance = shift;

	my @tres_fields = qw( 
		grptresmins 
		grptresrunmins 
		grptres 
		maxtresmins 
		maxtresperjob
		maxtrespernode
		maxtresperuser
		mintresperjob
	);

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
#Takes a list ref of Slurm::Sacctmgr::Cluster instances and calls strip_all_tres_but_cpu_nodes_fom_obj
#on each item in turn
{	my $list = shift;
	return unless $list && ref($list) eq 'ARRAY';

	foreach my $inst (@$list)
	{	strip_all_tres_but_cpu_nodes_from_obj($inst);
	}
	return $list;
}

1;
