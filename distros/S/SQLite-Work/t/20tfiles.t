# miscelaneous tests of a database

#########################

use Test::More tests => 6;

#########################

# compare two files
sub compare {
    my $file1 = shift;
    my $file2 = shift;

    if (!open(F1, $file1))
    {
    	print "error - $file1 did not open\n";
	return 0;
    }
    if (!open(F2, $file2))
    {
    	print "error - $file2 did not open\n";
	return 0;
    }

    my $res = 1;
    my $count = 0;
    while (<F1>)
    {
	$count++;
	my $comp1 = $_;
	# remove newline/carriage return (in case these aren't both Unix)
	$comp1 =~ s/\n//;
	$comp1 =~ s/\r//;

	my $comp2 = <F2>;

	# check if F2 has less lines than F1
	if (!defined $comp2)
	{
	    print "error - line $count does not exist in $file2\n  $file1 : $comp1\n";
	    close(F1);
	    close(F2);
	    return 0;
	}

	# remove newline/carriage return
	$comp2 =~ s/\n//;
	$comp2 =~ s/\r//;
	if ($comp1 ne $comp2)
	{
	    print "error - line $count not equal\n  $file1 : $comp1\n  $file2 : $comp2\n";
	    close(F1);
	    close(F2);
	    return 0;
	}
    }
    close(F1);

    # check if F2 has more lines than F1
    if (defined($comp2 = <F2>))
    {
	$comp2 =~ s/\n//;
	$comp2 =~ s/\r//;
	print "error - extra line in $file2 : '$comp2'\n";
	$res = 0;
    }

    close(F2);

    return $res;
}

#-----------------------------------------------------------------

my $script = "$^X -I ./blib/lib scripts/sqlreport";
my $command = "$script --options tfiles/test1.args --table episodes --outfile test1.html";

my $res = system($command);
ok($res == 0, "ran $command");

# compare the files
$result = compare('tfiles/test1.html', 'test1.html');
ok($result, 'test file matches original example exactly');
if ($result) {
    unlink('test1.html');
}

# TEST 2
$command = "$script --options tfiles/test2.args --table episodes --outfile test2.html";
$res = system($command);
ok($res == 0, "ran $command");

# compare the files
$result = compare('tfiles/test2.html', 'test2.html');
ok($result, 'test file matches original example exactly');
if ($result) {
    unlink('test2.html');
}

# TEST 3
$command = "$script --options tfiles/test3.args --table episodes --outfile test3.html";
$res = system($command);
ok($res == 0, "ran $command");

# compare the files
$result = compare('tfiles/test3.html', 'test3.html');
ok($result, 'test file matches original example exactly');
if ($result) {
    unlink('test3.html');
}

