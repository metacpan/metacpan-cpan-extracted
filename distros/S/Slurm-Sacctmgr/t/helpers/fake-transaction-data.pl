
use strict;

our @fake_trans_data =
(	
	{ 
		action => 'Modify Clusters',
		actor => 'slurm',
		info => "control_host='10.99.1.1', control_port=6817, last_port=6817, rpc_version=7168, dimensions=1, plugin_id_select=101, flags=0",
		timestamp=>'2016-01-01T10:00:00',
		where=>"(name='yottascale')"
	},

	{ 
		action=>'Modify Associations',
		actor=>'root',
		info => 'grp_cpu_mins=1000000',
		timestamp=>'2016-01-02T11:30:31',
		where=>"(id_assoc=107)",
	},

	{ 
	 	action=>'Add Associations',
		actor=>'root',
		info=>"mod_time=1447858465, acct='physics', user='alavirad', `partition`='standard', shares=1, grp_cpu_mins=NULL, grp_cpu_run_mins=NULL, grp_cpus=NULL, grp_jobs=NULL, grp_mem=NULL, grp_nodes=NULL, grp_submit_jobs=NULL, grp_wall=NULL, is_def=1, max_cpu_mins_pj=NULL, max_cpu_run_mins=NULL, max_cpus_pj=NULL, max_jobs=NULL, max_nodes_pj=NULL, max_submit_jobs=NULL, max_wall_pj=NULL, def_qos_id=NULL, qos=',6,8,7,9,5,4,'",
		timestamp=>'2016-01-08T09:54:25',
		where=>'id_assoc=4741',
	},

);

sub generate_fake_data()
#Generate list ref of Slurm::Sacctmgr::Transaction instances forom @fake_trans_data
#Need new list each time in case strip changes data
{	
	my $fake_data = [];
	foreach my $fakedatum (@fake_trans_data)
	{	
		my $obj = Slurm::Sacctmgr::Transaction->new(%$fakedatum);
		push @$fake_data, $obj;
	}
	return $fake_data;
}

1;
