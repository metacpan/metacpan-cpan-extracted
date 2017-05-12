
use strict;

#Set up expected results
our @fake_cluster_data =
(	
	{ 	cluster=>'yottascale',
		classification=>'imaginary', 
		controlhost=>'ys-master1',
		controlport=>6817, 
		flags=>'virtual', 
		rpc=>7168,
		nodenames=>'compute-[0-99999]', 
		pluginidselect=>1,
		tres => { node=>1000000, cpu=>20000000, mem=>128000000000 },
	},
	{ 	cluster=>'test1', 
		classification=>'test', 
		controlhost=>'test1-master',
		controlport=>6817, 
		flags=>'debug', 
		rpc=>7168,
		nodenames=>'test-[0-1]', 
		pluginidselect=>1,
		#cpucount=>4,
		#nodecount=>2, 
		tres => { cpu=>4, node=>2, mem=>32000 },
	},
);


sub generate_fake_objs()
#Returns a list ref of fake Slurm::Sacctmgr::Cluster instances 
#corresponding to @fake_cluster_data
{	my $fake_data = [];

	foreach my $record (@fake_cluster_data)
	{
		my $obj = Slurm::Sacctmgr::Cluster->new(
			%$record);
		push @$fake_data, $obj;
	}
	
	##Make sort sorted by cluster name
	#$fake_data = [ sort {$a->cluster cmp $b->cluster} @$fake_data ];
	return $fake_data;
}

#------	Routine to strip TRES data cannot fake in non-TRES versions

sub strip_all_tres_but_cpu_nodes_from_obj($)
#Takes Slurm::Sacctmgr::Cluster instance and strips all TRES fields except CPU and node
{	my $instance = shift;

	my @tres_fields = qw( tres );

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
