#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 400_sshare_list-parse.t`
#
# Various tests of sshare_list using  fake_sshare to test parsing of sshare output
#

use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;
my $default_user = 'george';
my $default_cluster = 'yottascale';


require "${testDir}/helpers/parse-help.pl";

my $sa = 'Slurm::Sshare';
$sa->sshare("${testDir}/helpers/fake_sshare");

#---------------------------------------------------------
#	More helper routines
#---------------------------------------------------------

sub decluster_results($)
#Takes list ref of hash refs, and makes a clone with all cluster keys removed
{	my $olist = shift;

	my $nlist = [];
	foreach my $href (@$olist)
	{	my $nhash = { %$href };
		delete $nhash->{cluster};
		push @$nlist, $nhash;
	}
	return $nlist;
}

sub departition_results($)
#Takes list ref of hash refs, and makes clone with all partition keys removed
{	my $olist = shift;

	my $nlist = [];
	foreach my $href (@$olist)
	{	my $nhash = { %$href };
		delete $nhash->{partition};
		push @$nlist, $nhash;
	}
	return $nlist;
}

sub strip_noncpu_tres($)
#Takes a list ref of hash refs, and makes a clone.
#For all tres fields, clone them and remove any non-CPU entry
{	my $olist = shift;

	my @tres_fields = qw( grptresmins tresrunmins );
	my $nlist = [];
	foreach my $href ( @$olist )
	{	my $nhash = { %$href };

		TRES: foreach my $tresfld (@tres_fields)
		{	my $treshash = $nhash->{$tresfld};
			next TRES unless $treshash && ref($treshash) eq 'HASH';

			my $ntreshash = {};
			if ( exists $treshash->{cpu} )
			{	$ntreshash->{cpu} = $treshash->{cpu};
			}
			$nhash->{$tresfld} = $ntreshash;
		}

		push @$nlist, $nhash;
	}
	return $nlist;
}
		

my (%filter, $results, $expected, $exp2, $arglist);
my ($cluster, $account, @ulist, @alist);

#Test data should be hash ref with following keys
#	name: base name of test
#	args: list ref of arguments to sshare_list
#	filter: filter to use with filtered_test_data
#	filter2: If given, add results of filtered_test_data with this filter as well
#	decluster_flag: remove cluster info from filtered_test_data

my @test_data =
(	
    #========== yottascale tests

	#No arguments
	{ 	name => "sshare_list, no args",
		args => [],
		filter => { 	cluster=>$default_cluster, 
				user=>[ undef, $default_user],
			},
		decluster_flag =>1,
	},

	# User lists
	{	name => 'sshare_list, ys, single user (aref)',
		args => [ clusters=>'yottascale', users=>[ 'payerle' ] ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle' ], },
	},
	{	name => 'sshare_list, ys, single user (csv)',
		args => [ clusters=>'yottascale', users=>'payerle' ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle' ], },
	},


	{	name => 'sshare_list, ys, 2 users (aref)',
		args => [ clusters=>'yottascale', users=>[ 'payerle', 'kevin' ] ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle', 'kevin' ], },
	},
	{	name => 'sshare_list, ys, 2 users (csv)',
		args => [ clusters=>'yottascale', users=>'payerle,kevin' ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle', 'kevin' ], },
	},
	
	{	name => 'sshare_list, ys, 3 users (aref)',
		args => [ clusters=>'yottascale', users=>[ 'payerle', 'kevin', 'george' ] ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle', 'kevin', 'george' ], },
	},
	{	name => 'sshare_list, ys, 3 users (csv)',
		args => [ clusters=>'yottascale', users=>'payerle,kevin,george' ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle', 'kevin', 'george' ], },
	},

	# Now for ALL users
	{	name => 'sshare_list, ys, all users (aref)',
		args => [ clusters=>'yottascale', users=>[ 'ALL' ] ],
		filter => { cluster=>'yottascale', },
	},
	{	name => 'sshare_list, ys, all users (csv)',
		args => [ clusters=>'yottascale', users=>'ALL' ],
		filter => { cluster=>'yottascale', },
	},

	# Account list tests, no users specified
	{	name => "sshare_list, ys, single acct (aref)",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124' ], ],
		filter => { cluster=>'yottascale', user=>[undef, 'george' ], account=>[ 'abc124' ], },
	},
	{	name => "sshare_list, ys, single acct (csv)",
		args => [ clusters=>'yottascale', accounts=>'abc124' ],
		filter => { cluster=>'yottascale', user=>[undef, 'george' ], account=>[ 'abc124' ], },
	},


	# Account list tests, explicitly request no users
	{	name => "sshare_list, ys, single acct no users (aref)",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124' ], users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124' ], },
	},
	{	name => "sshare_list, ys, single acct no users (csv)",
		args => [ clusters=>'yottascale', accounts=>'abc124', users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124' ], },
	},

	{	name => "sshare_list, ys, 2 accts no users (aref)",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124', 'fbi' ], users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124', 'fbi' ], },
	},
	{	name => "sshare_list, ys, 2 accts no users (csv)",
		args => [ clusters=>'yottascale', accounts=>'abc124,fbi', users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124', 'fbi' ], },
	},

	{	name => "sshare_list, ys, 3 accts no users (aref)",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124', 'fbi', 'nsa' ], users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124', 'fbi', 'nsa' ], },
	},
	{	name => "sshare_list, ys, 3 accts no users (csv)",
		args => [ clusters=>'yottascale', accounts=>'abc124,fbi,nsa', users=>[] ],
		filter => { cluster=>'yottascale', user=>[undef], account=>[ 'abc124', 'fbi', 'nsa' ], },
	},

	# Account and user lists
	{	name => "sshare_list, ys, single acct + user (aref)",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124'], users=>[ 'payerle'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle' ], account=>[ 'abc124' ], },
	},
	{	name => "sshare_list, ys, single acct + user (csv)",
		args => [ clusters=>'yottascale', accounts=>'abc124', users=>'payerle' ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle' ], account=>[ 'abc124', ], },
	},

	{	name => "sshare_list, ys, single acct + user not in account",
		args => [ clusters=>'yottascale', accounts=>[ 'cia'], users=>[ 'payerle'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle' ], account=>[ 'cia' ], },
	},


	{	name => "sshare_list, ys, 2 accts + 1 user",
		args => [ clusters=>'yottascale', accounts=>[ 'fbi', 'cia'], users=>[ 'payerle'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle' ], account=>[ 'fbi', 'cia' ], },
	},

	{	name => "sshare_list, ys, 1 acct + 2 users",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124'], users=>[ 'payerle', 'kevin'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle', 'kevin' ], account=>[ 'abc124' ], },
	},

	{	name => "sshare_list, ys, 2 accts + 2 users",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124', 'cia', ], users=>[ 'payerle', 'george'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle', 'george' ], account=>[ 'abc124', 'cia' ], },
	},

	{	name => "sshare_list, ys, 3 accts + 3 users",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124', 'cia', 'fbi' ], users=>[ 'payerle', 'george', 'kevin'] ],
		filter => { cluster=>'yottascale', user=>[undef, 'payerle', 'george', 'kevin' ], account=>[ 'abc124', 'cia', 'fbi' ], },
	},

	{	name => "sshare_list, ys, 3 accts + all users",
		args => [ clusters=>'yottascale', accounts=>[ 'abc124', 'cia', 'fbi' ], users=>[ 'ALL' ] ],
		filter => { cluster=>'yottascale', account=>[ 'abc124', 'cia', 'fbi' ], },
	},

    #========== test cluster tests

	# User list tests, no accounts
	{	name => 'sshare_list, testcl, single user (aref)',
		args => [ clusters=>'test', users=>[ 'payerle'] ],
		filter => { cluster=>'test', user=>[ undef, 'payerle'], },
	},
	{	name => 'sshare_list, testcl, single user (csv)',
		args => [ clusters=>'test', users=>'payerle' ],
		filter => { cluster=>'test', user=>[ undef, 'payerle' ], },
	},

	{	name => 'sshare_list, testcl, 2 users (aref)',
		args => [ clusters=>'test', users=>[ 'payerle', 'george' ] ],
		filter => { cluster=>'test', user=>[ undef, 'payerle', 'george' ], },
	},
	{	name => 'sshare_list, testcl, 2 users (csv)',
		args => [ clusters=>'test', users=>'payerle,george' ],
		filter => { cluster=>'test', user=>[ undef, 'payerle', 'george'  ], },
	},

	# Now for ALL users
	{	name => 'sshare_list, testcl, all users (aref)',
		args => [ clusters=>'test', users=>[ 'ALL' ] ],
		filter => { cluster=>'test' },
	},
	{	name => 'sshare_list, testcl, all users (csv)',
		args => [ clusters=>'test', users=>'ALL' ],
		filter => { cluster=>'test' },
	},

	# Account list tests, no users
	{	name => 'sshare_list, testcl, single acct (aref)',
		args => [ clusters=>'test', accounts=>[ 'abc124'] ],
		filter => { cluster=>'test', account=>[ 'abc124' ], user=>[ undef, 'george'], },
	},
	{	name => 'sshare_list, testcl, single acct (csv)',
		args => [ clusters=>'test', accounts=>'abc124' ],
		filter => { cluster=>'test', account=>[ 'abc124' ], user=>[ undef, 'george'],  },
	},

	# Account and user lists
	{	name => 'sshare_list, testcl, single acct+user (aref)',
		args => [ clusters=>'test', accounts=>[ 'abc124'], users=>['payerle'],  ],
		filter => { cluster=>'test', account=>[ 'abc124' ], user=>[undef, 'payerle' ], },
	},
	{	name => 'sshare_list, testcl, single acct+user (csv)',
		args => [ clusters=>'test', accounts=>'abc124', users=>'payerle',  ],
		filter => { cluster=>'test', account=>[ 'abc124' ], user=>[undef, 'payerle' ], },
	},

	{	name => 'sshare_list, testcl, single acct+ all users',
		args => [ clusters=>'test', accounts=>[ 'abc124'], users=>['ALL'],  ],
		filter => { cluster=>'test', account=>[ 'abc124' ] },
	},


    #========== tests on both clusters

	# Only cluster arguments
	{	name => 'sshare_list, 2 clusters (reversed) (aref)',
		args => [ clusters=>[ 'test', 'yottascale' ]  ],
		filter => { cluster=>'test', user=>[ undef, 'george'], },
		filter2 => { cluster=>'yottascale', user=>[ undef, 'george'], },
	},
	{	name => 'sshare_list, 2 clusters (reversed) (csv)',
		args => [ clusters=>'test,yottascale',  ],
		filter => { cluster=>'test', user=>[ undef, 'george'], },
		filter2 => { cluster=>'yottascale', user=>[ undef, 'george'], },
	},

	{	name => 'sshare_list, 2 clusters (aref)',
		args => [ clusters=>[ 'yottascale', 'test' ]  ],
		filter => { cluster=>'yottascale', user=>[ undef, 'george'], },
		filter2 => { cluster=>'test', user=>[ undef, 'george'], },
	},
	{	name => 'sshare_list, 2 clusters (csv)',
		args => [ clusters=>'yottascale, test',  ],
		filter => { cluster=>'yottascale', user=>[ undef, 'george'], },
		filter2 => { cluster=>'test', user=>[ undef, 'george'], },
	},

	#Single user, no acct
	{	name => 'sshare_list, 2 clusters, single user',
		args => [ clusters=>[ 'yottascale', 'test' ], users=>[ 'payerle' ],  ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle'], },
		filter2 => { cluster=>'test', user=>[ undef, 'payerle'], },
	},

	#Two users, no acct
	{	name => 'sshare_list, 2 clusters, 2 users',
		args => [ clusters=>[ 'yottascale', 'test' ], users=>[ 'payerle', 'george' ],  ],
		filter => { cluster=>'yottascale', user=>[ undef, 'payerle', 'george'], },
		filter2 => { cluster=>'test', user=>[ undef, 'payerle', 'george'], },
	},

	#Single account, no user
	{	name => 'sshare_list, 2 clusters, single acct',
		args => [ clusters=>[ 'yottascale', 'test' ], accounts=>[ 'abc124' ],  ],
		filter => { cluster=>'yottascale', account=> [ 'abc124' ], user=>[ undef, 'george'], },
		filter2 => { cluster=>'test', account=> [ 'abc124' ], user=>[ undef, 'george'], },
	},

	#Single account, 2 users
	{	name => 'sshare_list, 2 clusters, 1 acct + 2 users',
		args => [ clusters=>[ 'yottascale', 'test' ], accounts=>[ 'abc124' ], users=>[ 'payerle', 'george' ],   ],
		filter => { cluster=>'yottascale', account=> [ 'abc124' ], user=>[ undef, 'payerle', 'george' ], },
		filter2 => { cluster=>'test', account=> [ 'abc124' ], user=>[ undef, 'payerle', 'george' ], },
	},

	#Single account, all users
	{	name => 'sshare_list, 2 clusters, 1 acct + all users',
		args => [ clusters=>[ 'yottascale', 'test' ], accounts=>[ 'abc124' ], users=>[ 'ALL' ],   ],
		filter => { cluster=>'yottascale', account=> [ 'abc124' ], },
		filter2 => { cluster=>'test', account=> [ 'abc124' ],  },
	},

);

#---------------------------------------------------------
#	sshare v14, no partition info
#---------------------------------------------------------

$sa->sshare("${testDir}/helpers/fake_sshare");
$ENV{FAKESSHARE_EMULATE_VERSION}='14';
my ($testrec, $tname, $args, $filter, $decluster, $got, $exp);
my ($name, $filter2, $debug);

my $basename = "(sshare v14, nopartinfo)";
my @args;


foreach $testrec (@test_data)
{	$tname = $testrec->{name} || 'unnamed';
	$args = $testrec->{args} || [];
	$filter = $testrec->{filter} || {};
	$filter2 = $testrec->{filter2};
	$decluster = $testrec->{decluster_flag};
	$debug = $testrec->{debug};

	$exp = filtered_test_data(%$filter);
	if ( $filter2 )
	{	my $tmp = filtered_test_data(%$filter2);
		push @$exp, @$tmp if $tmp && ref($tmp) eq 'ARRAY';
	}
	$exp = decluster_results($exp) if $decluster;

	#V14, always departition and strip_noncpu_tres
	$exp = departition_results($exp);
	$exp = strip_noncpu_tres($exp);

	@args = ( @$args );
	#Force no partinfo
	push @args, nopartinfo => 1;

	$got = $sa->sshare_list(@args);
	$name = "${tname} $basename";

	if ( $debug )
	{	use Data::Dumper;
		print STDERR "got is $got\n", Dumper($got), "\n\n";
		print STDERR "exp is $exp\n", Dumper($exp), "\n\n";
	}

	compare_lref_results($got, $exp, $name);
}
	
#---------------------------------------------------------
#	sshare v14, nopartinfo unset
#---------------------------------------------------------

$sa->sshare("${testDir}/helpers/fake_sshare");
$ENV{FAKESSHARE_EMULATE_VERSION}='14';

$basename = "(sshare v14)";

foreach $testrec (@test_data)
{	$tname = $testrec->{name} || 'unnamed';
	$args = $testrec->{args} || [];
	$filter = $testrec->{filter} || {};
	$filter2 = $testrec->{filter2};
	$decluster = $testrec->{decluster_flag};
	$debug = $testrec->{debug};

	$exp = filtered_test_data(%$filter);
	if ( $filter2 )
	{	my $tmp = filtered_test_data(%$filter2);
		push @$exp, @$tmp if $tmp && ref($tmp) eq 'ARRAY';
	}
	$exp = decluster_results($exp) if $decluster;

	#V14, always departition and strip_noncpu_tres
	$exp = departition_results($exp);
	$exp = strip_noncpu_tres($exp);

	@args = ( @$args );

	$got = $sa->sshare_list(@args);
	$name = "${tname} $basename";

	if ( $debug )
	{	use Data::Dumper;
		print STDERR "got is $got\n", Dumper($got), "\n\n";
		print STDERR "exp is $exp\n", Dumper($exp), "\n\n";
	}

	compare_lref_results($got, $exp, $name);
}


#---------------------------------------------------------
#	sshare v15.08.2, no partition info
#---------------------------------------------------------

$sa->sshare("${testDir}/helpers/fake_sshare");
$ENV{FAKESSHARE_EMULATE_VERSION}='15.08.2';

$basename = "(sshare v15.08.2, nopartinfo)";

foreach $testrec (@test_data)
{	$tname = $testrec->{name} || 'unnamed';
	$args = $testrec->{args} || [];
	$filter = $testrec->{filter} || {};
	$filter2 = $testrec->{filter2};
	$decluster = $testrec->{decluster_flag};
	$debug = $testrec->{debug};

	$exp = filtered_test_data(%$filter);
	if ( $filter2 )
	{	my $tmp = filtered_test_data(%$filter2);
		push @$exp, @$tmp if $tmp && ref($tmp) eq 'ARRAY';
	}
	$exp = decluster_results($exp) if $decluster;

	$exp = departition_results($exp);

	@args = ( @$args );
	#Force no partinfo
	push @args, nopartinfo => 1;

	$got = $sa->sshare_list(@args);
	$name = "${tname} $basename";

	if ( $debug )
	{	use Data::Dumper;
		print STDERR "got is $got\n", Dumper($got), "\n\n";
		print STDERR "exp is $exp\n", Dumper($exp), "\n\n";
	}

	compare_lref_results($got, $exp, $name);
}
	
#---------------------------------------------------------
#	sshare v15.08.2, with partition info
#---------------------------------------------------------

$sa->sshare("${testDir}/helpers/fake_sshare");
$ENV{FAKESSHARE_EMULATE_VERSION}='15.08.2';

$basename = "(sshare v15.08.2, w partinfo)";

foreach $testrec (@test_data)
{	$tname = $testrec->{name} || 'unnamed';
	$args = $testrec->{args} || [];
	$filter = $testrec->{filter} || {};
	$filter2 = $testrec->{filter2};
	$decluster = $testrec->{decluster_flag};
	$debug = $testrec->{debug};

	$exp = filtered_test_data(%$filter);
	if ( $filter2 )
	{	my $tmp = filtered_test_data(%$filter2);
		push @$exp, @$tmp if $tmp && ref($tmp) eq 'ARRAY';
	}
	$exp = decluster_results($exp) if $decluster;

	@args = ( @$args );
	$got = $sa->sshare_list(@args);
	$name = "${tname} $basename";

	if ( $debug )
	{	use Data::Dumper;
		print STDERR "got is $got\n", Dumper($got), "\n\n";
		print STDERR "exp is $exp\n", Dumper($exp), "\n\n";
	}

	compare_lref_results($got, $exp, $name);
}
	
#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);

