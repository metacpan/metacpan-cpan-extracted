# 
# Helper routines for the Slurm::Sacctmgr *-echo.t tests

sub check_results($$;$$)
#Test that we got the expected results from running echo_cmdline or 
#echo_cmdline_to_stderr
#
#Returns false if results match, else a (true) error message
{	my $args = shift || [];
	my $results = shift || [];
	my $name = shift || 'check_results';
	my $prog = shift || 'echo_cmdline';

	subtest $name => sub {
		plan tests => 3;
		is( scalar(@$results), 2, 'line count matches');
		my $header = $results->[0]; chomp $header;
		my $cmdline = $results->[1]; chomp $cmdline;
		my $wanted = "Slurm test: $prog";
		is($header, $wanted, 'header matches');

		$wanted = join ' ', @$args;
		#$wanted = "./helpers/$prog $wanted";
		is($cmdline, $wanted, 'cmdline matches');
	};
	$num_tests_run++;
}

sub stringify_value($);
sub stringify_value($)
#Converts refs to a string
{	my $value = shift;
	return '' unless defined $value;
	return $value unless ref($value);

	if ( ref($value) eq 'ARRAY' )
	{	#Array ref, return as *ordered* csv
		my $str = join ',', @$value;
		return $str;
	}

	if ( ref($value) eq 'HASH' )
	{	#Hash ref, return as csv of key=value, 
		#alphabetized on key
		my $str = '';
		foreach my $key (sort (keys %$value))
		{	my $val = $value->{$key};
			$str .= ',' if $str;
			$str .= "$key=$val";
		}
		return $str;
	}
}

sub hash_to_arglist(@)
#combines key=>value pairs to key=value elements
#takes and returns lists
{	my @in = @_;

	my @out = ();
	my ($key, $value, $arg);
	while ( $key = shift @in )
	{	$value = shift @in;
		$value = stringify_value($value);
		#No quotes.  Args get called using execpe, not going through shell
		#so we should NOT quote them
		$arg = "${key}=${value}";
		push @out, $arg;
	}
	return @out;
}

sub hash_to_arglist_lexical(@)
#combines key=>value pairs to key=value elements 
#takes and returns lists (sorts list first)
{	my %in = @_;

	my @out = ();
	my ($key, $value, $arg);
	foreach $key (sort (keys %in) )
	{	$value = $in{$key};
		$value = stringify_value($value);
		#No quotes.  Args get called using execpe, not going through shell
		#so we should NOT quote them
		$arg = "${key}=${value}";
		push @out, $arg;
	}
	return @out;
}

1;
