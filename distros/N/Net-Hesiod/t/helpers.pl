#!/usr/local/bin/perl5 -w
# Helper functions for the tests

$::VERBOSE=1; #If true, be talkative

sub are_arrays_equal($$)
{	my $parr1 = shift;
	my $parr2 = shift;

	if (! defined $parr1 )
	{	if (! defined $parr2 )
		{	return 1;
		} else
		{	print STDERR "Array 1 not defined, Array 2 is\n" 
				if $::VERBOSE;
			return 0;
		}
	} 
	if (! defined $parr2 )
	{	print STDERR "Array 2 not defined, Array 1 is\n" if $::VERBOSE;
		return 0;
	}
		

	my $ret = 1;
	if (scalar(@$parr1) != scalar(@$parr2) ) 
	{	print STDERR "Arrays have unequal sizes, array1 is size ",
			scalar(@$parr1), " and array2 is ",
			scalar(@$parr2), "\n" if $::VERBOSE;
		$ret *=0;
	}

	my ($i,$tmp1,$tmp2);
	foreach ($i=0; $i < scalar(@$parr1); $i++)
	{	$tmp1 = $$parr1[$i];
		$tmp2 = $$parr2[$i];
		if ( $tmp1 eq "UNDEF" ) { undef $tmp1; }
		if ( $tmp2 eq "UNDEF" ) { undef $tmp2; }
		if ( defined $tmp1 && defined $tmp2 )
		{	if ( $tmp1 ne $tmp2 ) 
			{	print STDERR "Element $i of arrays differ: A1[$i]=$tmp1, A2[$i]=$tmp2\n" if $::VERBOSE;
				$ret *=0;
			}
		} elsif ( defined $tmp1 )
		{	print STDERR "Element $i is defined in A1 ($tmp1), but not in A2\n" if $::VERBOSE;
			$ret *=0;
		} elsif ( defined $tmp2 )
		{	print STDERR "Element $i is defined in A2 ($tmp2), but not in A1\n" if $::VERBOSE;
			$ret *=0;
		}
		else
		{	#Not defined in either, a match 
		}
	}

	return $ret;
}

1;
