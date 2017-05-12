
use strict;

################################################################3
#		Set up expected results
################################################################3

my @fake_event_data =
(	
	{ 
		cluster=>'yottascale', 
		clusternodes=>'compute-0', nodename=>'compute-0.umd.edu',
		tres => 'cpu=20,node=1,mem=120000',
		event=>'Node', eventraw=>2, state=>'DRAIN', stateraw=>514,
		start=>'2016-01-01T00:00:00', end=>'2016-01-01T18:00:00', duration=>'18:00:00',
		user=>'payerle', reason=>'bad powersupply',
	},
	{ 
		cluster=>'yottascale', 
		clusternodes=>'compute-[11-20]', nodename=>undef,
		tres => 'cpu=200,node=10,mem=1280000',
		event=>'Cluster', eventraw=>1, state=>'DRAIN', stateraw=>514,
		start=>'2016-01-05T00:00:00', end=>'2016-01-05T19:00:00', duration=>'19:00:00',
		user=>'root', reason=>'bad nw card in switch',
	},
	{
		cluster=>'test1', 
		clusternodes=>'test-0', nodename=>'test-0',
		tres => 'cpu=2,node=1,mem=32000', 
		event=>'Node', eventraw=>2, state=>'DRAIN', stateraw=>514,
		start=>'2016-02-05T00:00:00', end=>'2016-02-05T13:00:00', duration=>'13:00:00',
		user=>'payerle', reason=>'no reason',
	},
);

sub generate_fake_data()
#Generates a list of Slurm::Sacctmgr::Event instances from @fake_event_data
#We need a new list as strip_* changes data
{	
	my $fake_data = [];
	foreach my $rec (@fake_event_data)
	{	my $obj = Slurm::Sacctmgr::Event->new(%$rec);
		push @$fake_data, $obj;
	}
	return $fake_data;
}

#######################################################################
#	Strip out stuff not available in preTRES slurms
#######################################################################

sub strip_all_tres_but_cpu_from_obj($)
{	my $instance = shift;

	my @tres_fields=qw( tres );

	foreach my $tresfld (@tres_fields)
	{	my $hash = $instance->$tresfld;
		next unless $hash && ref($hash) eq 'HASH';

		my @keys = keys %$hash;
		my %keys = map { $_ => undef } @keys;
		delete $keys{cpu};
		#delete $keys{node};
		@keys = keys %keys;
		foreach my $key (@keys)
		{	delete $hash->{$key};
		}
	}
}

sub strip_all_tres_but_cpu($)
#Takes a list ref of Slurm::Sacctmgr::Event instances and runs
#strip_all_tre_but_cpu_nodes_from_obj on each of them
{	my $list = shift;
	return unless $list && ref($list) eq 'ARRAY';

	foreach my $inst (@$list)
	{	strip_all_tres_but_cpu_from_obj($inst);
	}
	return $list;
}



1;

