# 
# Helper routines for the Slurm::Sshare *-parse.t tests
#
# Basically, this is the data output from fake_sshare in Perlish format
#
# Any changes here need to be reflected in fake_sshare and vica versa, otherwise
# tests will fail.

my @sshare_test_data = 
(
  #Cluster yottascale
     #yottascale/root 

	{	account => 'root',
		cluster => 'yottascale',
		normalized_shares => 1.000000,
		raw_usage => 42000000,
		effective_usage => 0.000000,
		fairshare => 1.000000,
		cpurunmins => 5700070,
		tresrunmins => 
		{	cpu=>5700070,
			mem=>600000,
			energy=>0,
			node=>20000,
			'gres/gpu'=>4000,
		},
	},

     #yottascale/abc124
	{	account => 'abc124',
		cluster => 'yottascale',
		raw_shares => 1,
		normalized_shares => 0.333333,
		raw_usage => 20000000,
		normalized_usage => 0.476190,
		effective_usage => 0.476190,
		fairshare => 0.321144,
		grpcpumins => 12321153,
		cpurunmins => 3156000,
		grptresmins => 
		{	cpu=>12321153,
			'gres/gpu'=>8000,
		},
		tresrunmins => 
		{	cpu=>3156000,
			'gres/gpu'=>1000,
			node=>7000,
		},
	},

       #yottascale/abc124/george
	{	account => 'abc124',
		cluster => 'yottascale',
		user => 'george',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 5049600,
		normalized_usage => 0.120226,
		effective_usage => 0.120226,
		fairshare => 0.500000,
		cpurunmins => 315520,
		partition => "standard",
		tresrunmins => 
		{	cpu=>315520,
			'gres/gpu'=>0,
			node=>3000,
		},
		
	},

       #yottascale/abc124/kevin
	{	account => 'abc124',
		cluster => 'yottascale',
		user => 'kevin',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 11960320,
		normalized_usage => 0.284770,
		effective_usage => 0.284770,
		fairshare => 0.500000,
		partition => "standard",
		cpurunmins => 1420240,
		tresrunmins => 
		{	cpu=>1420240,
			'gres/gpu'=>0,
			node=>2000,
		},
	},

       #yottascale/abc124/payerle: 3 records
	{	account => 'abc124',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 1495040,
		normalized_usage => 0.035596,
		effective_usage => 0.035596,
		fairshare => 0.300000,
		cpurunmins => 236707,
		partition => "standard",
		tresrunmins => 
		{	cpu=> 236707,
			'gres/gpu'=>0,
			node=>500,
		},
	},
	{	account => 'abc124',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 996693,
		normalized_usage => 0.023737,
		effective_usage => 0.023737,
		fairshare => 0.600000,
		cpurunmins => 473413,
		partition => "highpri",
		tresrunmins => 
		{	cpu=> 473413,
			'gres/gpu'=>0,
			node=>1200,
		},
	},
	{	account => 'abc124',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 498347,
		normalized_usage => 0.011865,
		effective_usage =>  0.011865,
		fairshare => 0.200000,
		cpurunmins => 710120,
		partition => "gpu",
		tresrunmins => 
		{	cpu=>710120,
			'gres/gpu'=>1000,
			node=>300,
		},
	},

     #yottascale/fbi
	{	account => 'fbi',
		cluster => 'yottascale',
		raw_shares => 1,
		normalized_shares => 0.333333,
		raw_usage => 16500000,
		normalized_usage => 0.392857,
		effective_usage => 0.392857,
		fairshare => 0.500000,
		grpcpumins => 30000000,
		cpurunmins => 1234000,
		grptresmins => 
		{	cpu=>30000000,
			'gres/gpu'=>8000,
			nodes=>100000,
		},
		tresrunmins => 
		{	cpu=>1234000,
			'gres/gpu'=>50,
			nodes=>1000,
		},
	},

       #yottascale/fbi/george
	{	account => 'fbi',
		cluster => 'yottascale',
		user => 'george',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 4125000,
		normalized_usage => 0.098214,
		effective_usage => 0.098214,
		fairshare => 0.400000,
		partition => "highpri",
		cpurunmins => 308500,
		tresrunmins => 
		{	cpu=>308500,
			'gres/gpu'=>0,
			nodes=>320,
		},
	},

       #yottascale/fbi/payerle: 3 records
	{	account => 'fbi',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 4125000,
		normalized_usage => 0.098214,
		effective_usage => 0.098214,
		fairshare => 0.333333,
		partition => "standard",
		cpurunmins => 308500,
		tresrunmins => 
		{	cpu=>308500,
			'gres/gpu'=>0,
			nodes=>320,
		},
	},
	{	account => 'fbi',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 4125000,
		normalized_usage => 0.098214,
		effective_usage => 0.098214,
		fairshare => 0.333333,
		partition => "highpri",
		cpurunmins => 308500,
		tresrunmins => 
		{	cpu=>308500,
			'gres/gpu'=>0,
			nodes=>320,
		},
	},
	{	account => 'fbi',
		cluster => 'yottascale',
		user => 'payerle',
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 4125000,
		normalized_usage => 0.098214,
		effective_usage => 0.098214,
		fairshare => 0.333333,
		partition => "gpu",
		cpurunmins => 308500,
		tresrunmins => 
		{	cpu=>308500,
			'gres/gpu'=>50,
			nodes=>40,
		},
	},

     #yottascale/nsa
	{	account => 'nsa',
		cluster => 'yottascale',
		raw_shares => 1,
		normalized_shares => 0.333333,
		raw_usage => 5500000,
		normalized_usage => 0.130952,
		effective_usage => 0.130952,
		fairshare => 0.500000,
		grpcpumins => 90000000,
		cpurunmins => 1111111,
		grptresmins => 
		{	cpu=> 90000000,
			'gres/gpu'=>8000,
			nodes=>100000,
		},
		tresrunmins => 
		{	cpu=> 1111111,
			'gres/gpu'=>0,
			nodes=>1000,
		},
	},

       #yottascale/nsa/george
	{	account => 'nsa',
		cluster => 'yottascale',
		user => 'george',
		#No partition
		raw_shares => 1,
		normalized_shares => 0.1,
		raw_usage => 5500000,
		normalized_usage => 0.130952,
		effective_usage => 0.130952,
		fairshare => 0.500000,
		cpurunmins => 1111111,
		tresrunmins => 
		{	cpu=> 1111111,
			'gres/gpu'=>0,
			nodes=>1000,
		},
	},

  #Cluster test
     #test/root 
	{	account => 'root',
		cluster => 'test',
		normalized_shares => 1.000000,
		raw_usage => 12400,
		effective_usage => 0.000000,
		fairshare => 1.000000,
		cpurunmins => 248,
		tresrunmins=> 
		{	cpu=>248,
			'gres/gpu'=>0,
			nodes=>1,
		},
	},

     #test/abc124
	{	account => 'abc124',
		cluster => 'test',
		raw_shares => 1,
		normalized_shares => 1.000000,
		raw_usage => 12400,
		normalized_usage => 1.000000,
		effective_usage => 1.000000,
		fairshare => 0.321144,
		grpcpumins => 98765432,
		cpurunmins => 248,
		tresrunmins=> 
		{	cpu=>248,
			'gres/gpu'=>0,
			nodes=>1,
		},
		grptresmins => 
		{	cpu=>98765432,
			'gres/gpu'=>0,
			nodes=>10,
		},
	},

       #test/abc124/george
	{	account => 'abc124',
		cluster => 'test',
		user => 'george',
		#No partition
		raw_shares => 1,
		normalized_shares => 0.500000,
		raw_usage => 0,
		normalized_usage => 0.000000,
		effective_usage => 0.000000,
		fairshare => 1.000000,
		cpurunmins => 0,
		tresrunmins=> 
		{	cpu=>0,
			'gres/gpu'=>0,
			nodes=>0,
		},
	},
			    
       #test/abc124/payerle
	{	account => 'abc124',
		cluster => 'test',
		user => 'payerle',
		#No partition
		raw_shares => 1,
		normalized_shares => 0.500000,
		raw_usage => 12400,
		normalized_usage => 1.000000,
		effective_usage => 1.000000,
		fairshare => 0.050000,
		cpurunmins => 248,
		tresrunmins=> 
		{	cpu=>248,
			'gres/gpu'=>0,
			nodes=>1,
		},
		grptresmins=> { cpu=> 10000, },
		grpcpumins=> 10000,
	},
);


sub filter_data_list($$$)
#Takes list ref of hash refs, plus a key and value to filter on.
#Returns a list ref of hash refs; the subset of the original list (in same order)
#for which the filter matches.
#
#The filter matches when ($href is the hash ref being tested)
#If value is:
#	undef: the $href has no key $key, or it has an undef value
#	non-ref scalar: $href->{$key} eq $val
#	empty list ref: same as undef
#	non-empty list ref: $href->{$key} eq one of the values of the list ref
# The non-empty list can contain an undef value, which matches similar to an undef scalar.
{	my $list = shift;
	my $key = shift;
	my $val = shift;
	my $me = 'filter_data';

	die "$me: Invalid list $list; expecting a list ref at " 
		unless $list && ref($list) eq 'ARRAY';

	my $filtered = [];

	#Convert $val to list ref or undef
	if ( defined $val )
	{	if ( ref($val) eq 'ARRAY' )
		{	if ( scalar(@$val) == 0 )
			{	$val = undef;
			}
		} elsif ( ref($val) )
		{	die "$me: Invalid value $val: expecting scalar or list ref at "
		} else
		{	$val = [ $val ];
		}
	} 


	HREF: foreach my $href (@$list)
	{	my $hval = $href->{$key};
		if ( defined $val )
		{	#next HREF unless defined $hval;
			foreach my $tmpval (@$val)
			{	if ( defined $tmpval )
				{	if ( defined $hval && $hval eq $tmpval )
					{	push @$filtered, $href;
						next HREF;
					}
				} else
				{	#tmpval not defined, match if hval also undef
					unless ( defined $hval )
					{	push @$filtered, $href;
						next HREF;
					}
				}
			}
			next HREF;
		} else
		{	push @$filtered, $href unless defined $hval;
			next HREF;
		}
	}

	return $filtered;
}

sub filtered_test_data(@)
#Takes a hash of key => val pairs as filter, and returns subset of @sshare_test_data which
#matches filter.  The filter is applied for each key separately, with results ANDed
#If val is undef or empty list ref, filter only matches if key is missing or undef value in
#the hash ref being tested.  For a non-ref scalar value, matches if value matches (string
#comparison).  For non-empty list ref, matches if value of key in hash ref being tested
#matches any element of the list.
{	my %where = @_;

	my $list = [ @sshare_test_data ];
	foreach my $key (keys %where)
	{	my $val = $where{$key};

		$list = filter_data_list($list,$key, $val);
	}
	return $list;
}

sub compare_href_results($$;$)
#Compares expected/got hash refs for a single sshare line
#
{       my $got = shift || {};
	my $expected = shift || {};
        my $name = shift || 'compare_href_results';

	my @text_fields = qw( 
		account 
		user 
		cluster
		partition
	);
	my @num_fields = qw( 
		raw_shares 
		normalized_shares
		raw_usage
		normalized_usage
		effective_usage
		fairshare
		grpcpumins
		cpurunmins
	);
	my @href_fields = qw(
		grptresmins
		tresrunmins
	);
	my $numtests = scalar(@text_fields)  + scalar(@num_fields) + scalar(@href_fields);

        subtest $name => sub {
                plan tests => $numtests;

		my $fld;
		foreach $fld (@text_fields)
		{	is( $got->{$fld}, $expected->{$fld}, "${name}: $fld");
		}
		NUMFLD: foreach $fld (@num_fields)
		{	my $gval = $got->{$fld};
			my $xval = $expected->{$fld};
			if ( ! defined $gval && ! defined $xval )
			{	#Neither defined, guess that's a pass
				pass("${name}: $fld (neither defined)");
				next NUMFLD;
			}
			unless ( defined $gval )
			{	fail("${name}: $fld (got value undef)");
				next NUMFLD;
			}
			unless ( defined $xval )
			{	fail("${name}: $fld (expected value undef)");
				next NUMFLD;
			}
			cmp_ok( $gval, '==', $xval, "${name}: $fld");
		}
		HASHFLD: foreach $fld (@href_fields)
		{	my $gval = $got->{$fld};
			my $xval = $expected->{$fld};
			if ( ! defined $gval && ! defined $xval )
			{	#Neither defined, guess that's a pass
				pass("${name}: $fld (neither defined)");
				next HASHFLD;
			}
			unless ( defined $gval )
			{	fail("${name}: $fld (got value undef)");
				next HASHFLD;
			}
			unless ( defined $xval )
			{	fail("${name}: $fld (expected value undef)");
				next HASHFLD;
			}
			is_deeply( $gval, $xval, "${name}: $fld");
		}

        };
}

sub compare_lref_results($$;$)
#Compares two list refs of hash refs
#
{       my $got = shift || [];
	my $expected = shift || [];
        my $name = shift || 'compare_lref_results';

	$num_tests_run++;

	my $numtests = scalar(@$expected);
	$numtests = scalar(@$got) if scalar(@$got) > $numtests;
	unless ( $numtests )
	{	pass("${name}: both lists empty");
		return;
	}

        subtest $name => sub {
                plan tests => $numtests;

		my $index;
		INDEX: foreach $index ( 0 .. ($numtests-1) )
		{	my $gothref = $got->[$index];
			my $exphref = $expected->[$index];
			
			if ( ! defined $gothref && ! defined $exphref )
			{	#Neither defined, guess that's a pass
				pass("${name} [element $index] --- neither href defined");
				next INDEX;
			}
			unless ( defined $gothref )
			{	fail("${name} [element $index] --- got href not defined");
				next INDEX;
			}
			unless ( defined $exphref )
			{	fail("${name} [element $index] --- exp href not defined");
				next INDEX;
			}
		
			compare_href_results($gothref, $exphref, "${name} [element $index]");
		}
			
        };
}

#-----------------------------------------------------------
# Tests and expected output for sbalance command
#-----------------------------------------------------------

my $sshare_usage_ys = 
{	'abc124' =>
	{	%{$sshare_test_data[1]},
		users_hash =>
		{	george => { %{$sshare_test_data[2]} },
			kevin => { %{$sshare_test_data[3]} },
			payerle => 
			{	cluster=>'yottascale',
				account=>'abc124',
				user=>'payerle',
				raw_shares => 3,
				normalized_shares => 0.3,
				raw_usage => 1495040 + 996693 + 498347,
				normalized_usage => 0.035596 + 0.023737 + 0.011865,
				effective_usage => 0.035596 + 0.023737 + 0.011865,
				grpcpumins => 0,
				cpurunmins => 236707 + 473413 + 710120,
			},
		},
	},

	'fbi' =>
	{	%{$sshare_test_data[7]},
		users_hash => 
		{	george => { %{$sshare_test_data[8]} },
			payerle =>
			{	cluster=>'yottascale',
				account=>'abc124',
				user=>'payerle',
				raw_shares => 3,
				normalized_shares => 0.3,
				raw_usage => 3 * 4125000,
				normalized_usage => 3 * 0.098214,
				effective_usage => 3 * 0.098214,
				grpcpumins => 0,
				cpurunmins =>  3 * 308500,
			},
		},
	},

	'nsa' => 
	{	%{$sshare_test_data[12]},
		users_hash =>
		{	george => { %{$sshare_test_data[13]}  },
		},
	},
};

my $sshare_usage_testcl = 
{	'abc124' =>
	{	%{$sshare_test_data[15]},
		users_hash =>
		{	george => { %{$sshare_test_data[16]} },
			payerle => { %{$sshare_test_data[17]} },
		},
	},
};



#First, manual calc to manually check against below
#Cluster=yottascale
#    Account abc124
#	Limit= 12321153 cpu-min = 205.3525 kSU
#	Usage= 20000000 cpu-sec = 5.5555 kSU (2.700% of limit)
#	Running= 3156000 cpu-min = 52.6000 kSU
#	Used+Running = 58.1555 kSU (28.310% of limit)
#	User george
#		Usage= 5049600 cpu-sec = 1.4026 kSU (25.24% of used)
#		Running= 315520 cpu-min = 5.2586 kSU (9.99% of running)
#		Used+Run= 6.6612 kSU (11.45% of U+R)
#	User kevin
#		Usage= 11960320 cpu-sec = 3.3223 kSU (59.8% of used)
#		Running=1420240 cpu-min = 23.6706 kSU (45.0% of running)
#		Used+Run= 26.9929 kSU (46.41% of U+R)
#	User payerle
#		Usage= 1495040+996693+498347=2990080 cpu-sec= 0.8305 kSU (14.94% of used)
#		Running= 236707+473413+710120=1420240 cpu-min= 23.6706 kSU (45.0% of running)
#		Used+Run=24.5011 kSU ( 42.13% of U+R)
#
#    Account fbi
#	Limit= 30000000 cpu-min = 500.00 kSU
#	Usage= 16500000 cpu-sec = 4.5833 kSU (0.91% of limit)
#	Running= 1234000 cpu-min = 20.5666 kSU 
#	Used+Running= 25.1499 kSU (5.02% of limit)
#	User george
#		Usage= 4125000 cpu-sec = 1.1458 kSU (24.99% of used)
#		Running= 308500 cpu-min = 5.1416 kSU (24.99% of running)
#		Used+Run= 6.2874 kSU (24.99% of U+R)
#	User payerle
#		Used = 3*4125000 = 12375000 cpu-sec = 3.4375 kSU (75.0% of used)
#		Running = 3*308500 = 925500 cpu-min = 15.4250 kSU (75% of running)
#		Used+Run= 18.8625 kSU (75.0% of U+R)
#
#    Account nsa
#	Limit= 90000000 cpu-min = 1500.00 kSU 
#	Usage= 5500000 cpu-sec = 1.5277 kSU (0.10% of limit)
#	Running= 1111111 cpu-min = 18.5185 kSU 
#	Used+Running= 20.0462 kSU (1.33% of limit)
#	User george
#		Usage= 5500000 cpu-sec = 1.5277 kSU (100% of used)
#		Running=111111 cpu-min = 18.5185 kSU (100% of running)
#		Used+Run= 20.0462 kSU (100% of U+R)
#
#Cluster=test
#    Account abc124
#	Limit=  98765432 cpu-min = 1646.0905 kSU 
#	Usage= 12400 cpu-sec = 0.0034 kSU (0.000% of limit)
#	Running= 248 cpu-min = 0.0041 kSU 
#	Used+Running= 0.0075 kSU (0.000% of limit)
#	User george
#		Usage= 0 cpu-sec = 0 kSU (0% of used)
#		Running= 0 cpu-min = 0 kSU (0% of running)
#		Used+Run= 0 kSU (0% of U+R)
#	User payerle
#		Usage= 12400 cpu-sec = 0.0034 kSU (100% of used)
#		Running = 248 cpu-min = 0.0041 kSU (100% of running)
#		Used+Run = 0.0075 kSU (100% of U+R)


sub convert_ys_to_default($)
{	my $text = shift;
	my $ys = 'yottascale';
	my $default = 'DEFAULT';

	$text =~ s/$ys/$default/g;
	return $text;
}

my $sbalout_ys_noacct_george = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)

Account: fbi (yottascale)
Limit: 	   500.00 kSU
Unused:    495.42 kSU 
Used:  	   4.58 kSU (0.9 % of limit)
	User george used 1.1458 kSU (25.0 % of total usage)

Account: nsa (yottascale)
Limit: 	   1500.00 kSU
Unused:    1498.47 kSU 
Used:  	   1.53 kSU (0.1 % of limit)
	User george used 1.5278 kSU (100.0 % of total usage)
EOF

my $sbalout_ys_noacct_payerle = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User payerle used 0.8306 kSU (15.0 % of total usage)

Account: fbi (yottascale)
Limit: 	   500.00 kSU
Unused:    495.42 kSU 
Used:  	   4.58 kSU (0.9 % of limit)
	User payerle used 3.4375 kSU (75.0 % of total usage)
EOF

my $sbalout_ys_noacct_kevin = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User kevin used 3.3223 kSU (59.8 % of total usage)
EOF

my $sbalout_ys_noacct_george_allusers = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)
	User kevin used 3.3223 kSU (59.8 % of total usage)
	User payerle used 0.8306 kSU (15.0 % of total usage)

Account: fbi (yottascale)
Limit: 	   500.00 kSU
Unused:    495.42 kSU 
Used:  	   4.58 kSU (0.9 % of limit)
	User george used 1.1458 kSU (25.0 % of total usage)
	User payerle used 3.4375 kSU (75.0 % of total usage)

Account: nsa (yottascale)
Limit: 	   1500.00 kSU
Unused:    1498.47 kSU 
Used:  	   1.53 kSU (0.1 % of limit)
	User george used 1.5278 kSU (100.0 % of total usage)
EOF


my $sbalout_ys_noacct_payerle_allusers = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)
	User kevin used 3.3223 kSU (59.8 % of total usage)
	User payerle used 0.8306 kSU (15.0 % of total usage)

Account: fbi (yottascale)
Limit: 	   500.00 kSU
Unused:    495.42 kSU 
Used:  	   4.58 kSU (0.9 % of limit)
	User george used 1.1458 kSU (25.0 % of total usage)
	User payerle used 3.4375 kSU (75.0 % of total usage)
EOF


my $sbalout_ys_abc124_nouser = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
EOF

my $sbalout_ys_abc124_george = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)
EOF

my $sbalout_ys_abc124_george_kevin = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)
	User kevin used 3.3223 kSU (59.8 % of total usage)
EOF

my $sbalout_ys_abc124_allusers = <<EOF;
Account: abc124 (yottascale)
Limit: 	   205.35 kSU
Unused:    199.80 kSU 
Used:  	   5.56 kSU (2.7 % of limit)
	User george used 1.4027 kSU (25.2 % of total usage)
	User kevin used 3.3223 kSU (59.8 % of total usage)
	User payerle used 0.8306 kSU (15.0 % of total usage)
EOF

my $sbalout_ys_nsa_kevin = <<EOF;
Account: nsa (yottascale)
Limit: 	   1500.00 kSU
Unused:    1498.47 kSU 
Used:  	   1.53 kSU (0.1 % of limit)
EOF

my $sbalout_test_noacct_george = <<EOF;
Account: abc124 (test)
Limit: 	   1646.09 kSU
Unused:    1646.09 kSU 
Used:  	   0.00 kSU (0.0 % of limit)
EOF

my $sbalout_test_noacct_payerle = <<EOF;
Account: abc124 (test)
Limit: 	   1646.09 kSU
Unused:    1646.09 kSU 
Used:  	   0.00 kSU (0.0 % of limit)
	User payerle used 0.0034 kSU (100.0 % of total usage)
EOF


my $sbalout_test_noacct_payerle_all0 = <<EOF;
Account: abc124 (test)
Limit: 	   1646.09 kSU
Unused:    1646.09 kSU 
Used:  	   0.00 kSU (0.0 % of limit)
	User george used 0.0000 kSU (0.0 % of total usage)
	User payerle used 0.0034 kSU (100.0 % of total usage)
EOF



#Array refs are
# [ $testname, $expected, @sbalance_arguments ]
#It is assumed the $ENV{USER} is set to 'george' for the tests

@::sbalance_tests = 
(	#Give cluster and zero or one user, with and without --all and --nosuppress0 flags
	[ "cluster=ys, no user given", $sbalout_ys_noacct_george, '--cluster' => 'yottascale' ],
	[ "cluster=ys, user=george", $sbalout_ys_noacct_george, '--cluster' => 'yottascale', '--user' => 'george' ],
	[ "cluster=ys, user=payerle", $sbalout_ys_noacct_payerle, '--cluster' => 'yottascale', '--user' => 'payerle' ],
	[ "cluster=ys, user=kevin", $sbalout_ys_noacct_kevin, '--cluster' => 'yottascale', '--user' => 'kevin' ],
	[ "cluster=ys, user=george --all", $sbalout_ys_noacct_george_allusers, '--cluster' => 'yottascale', '--user' => 'george', '--allusers' ],
	[ "cluster=ys, user=george --all -nosup0", $sbalout_ys_noacct_george_allusers,
		 '--cluster' => 'yottascale', '--user' => 'george', '--allusers', '--nosuppress0' ],
	[ "cluster=ys, user=payerle --all", $sbalout_ys_noacct_payerle_allusers, '--cluster' => 'yottascale', '--user' => 'payerle', '--allusers' ],
	[ "cluster=ys, user=payerle --all -nosup0", $sbalout_ys_noacct_payerle_allusers, 
		'--cluster' => 'yottascale', '--user' => 'payerle', '--allusers','--nosuppress0'],

	#As above, but defaulting the cluster
	[ "cluster=def, no user given", convert_ys_to_default($sbalout_ys_noacct_george), ],
	[ "cluster=def, user=george", convert_ys_to_default($sbalout_ys_noacct_george),  '--user' => 'george' ],
	[ "cluster=def, user=payerle", convert_ys_to_default($sbalout_ys_noacct_payerle), '--user' => 'payerle' ],
	[ "cluster=def, user=kevin", convert_ys_to_default($sbalout_ys_noacct_kevin), '--user' => 'kevin' ],
	[ "cluster=def, user=george --all", convert_ys_to_default($sbalout_ys_noacct_george_allusers), '--user' => 'george', '--allusers' ],
	[ "cluster=def, user=george --all -nosup0", convert_ys_to_default($sbalout_ys_noacct_george_allusers), '--user'=>'george', '--allusers', '--nosuppress0' ],
	[ "cluster=def, user=payerle --all", convert_ys_to_default($sbalout_ys_noacct_payerle_allusers), '--user'=>'payerle', '--allusers' ],
	[ "cluster=def, user=payerle --all -nosup0", convert_ys_to_default($sbalout_ys_noacct_payerle_allusers), '--user'=>'payerle', '--allusers','--nosuppress0'],

	#Give cluster and account, with and without users 
	[ "cluster=ys, acct=abc124, no user", $sbalout_ys_abc124_nouser, '--cluster' => 'yottascale', '--account' => 'abc124' ],
	[ "cluster=ys, acct=abc124, user=george", $sbalout_ys_abc124_nouser, '--cluster' => 'yottascale', '--account' => 'abc124', user=>'george' ],
	[ "cluster=ys, acct=abc124, user=george,kevin", $sbalout_ys_abc124_george_kevin,
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'george', '--user'=>'kevin', ],
	
	#Adding --all flag
	[ "cluster=ys, acct=abc124, allusers", $sbalout_ys_abc124_allusers, '--cluster' => 'yottascale', '--account' => 'abc124', '--allusers' ],
	[ "cluster=ys, acct=abc124, user=george, allusers", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'george','--allusers'],
	[ "cluster=ys, acct=abc124, user=kevin, allusers", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'kevin','--allusers'],
	[ "cluster=ys, acct=abc124, user=george,kevin allusers", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'george', '--user'=>'kevin', '--allusers'],

	#and --nosuppress0
	[ "cluster=ys, acct=abc124, all0", $sbalout_ys_abc124_allusers, '--cluster' => 'yottascale', '--account' => 'abc124', '--allusers', '--nosuppress0' ],
	[ "cluster=ys, acct=abc124, user=george, all0", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'george','--allusers', '--nosuppress0' ],
	[ "cluster=ys, acct=abc124, user=kevin, all0", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'kevin','--allusers', '--nosuppress0' ],
	[ "cluster=ys, acct=abc124, user=george,kevin all0", $sbalout_ys_abc124_allusers, 
		'--cluster' => 'yottascale', '--account' => 'abc124', '--user'=>'george', '--user'=>'kevin', '--allusers', '--nosuppress0' ],

	#What if user is not in specified account
	[ "cluster=ys, acct=nsa user=kevin", $sbalout_ys_nsa_kevin, '--cluster' => 'yottascale', '--account' => 'nsa', '--user'=>'kevin' ],

	#Test cluster, in particular, test of zero usage
	[ "cluster=test, noacct nouser", $sbalout_test_noacct_george, '--cluster' => 'test',  ],
	[ "cluster=test, noacct user=george", $sbalout_test_noacct_george, '--cluster' => 'test', '--user'=>'george' ],
	[ "cluster=test, noacct user=payerle", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'payerle' ],
	[ "cluster=test, noacct user=payerle,george", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'payerle', '--user'=>'george' ],
	[ "cluster=test, noacct user=payerle,george", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'payerle', '--user'=>'george' ],

	[ "cluster=test, noacct nouser -all", $sbalout_test_noacct_payerle, '--cluster' => 'test', '-allusers' ],
	[ "cluster=test, noacct user=george -all", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'george', '-allusers' ],
	[ "cluster=test, noacct user=payerle -all", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'payerle', '-allusers' ],
	[ "cluster=test, noacct user=george,payerle -all", $sbalout_test_noacct_payerle, '--cluster' => 'test', '--user'=>'george', '--user'=>'payerle', '-allusers' ],

	[ "cluster=test, noacct -all0", $sbalout_test_noacct_payerle_all0, '--cluster' => 'test', '-allusers', '--nosuppress0' ],
);

1;
