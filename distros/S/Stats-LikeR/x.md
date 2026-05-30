## aoh2hoh

Take an array of hashes and turn it into a hash of hash

### with pivot key/row name

    my @aoh = (
    {
    	a => 'A',
    	b => 'B',
    	r => '1st'
    },
    {
    	a => 'C',
    	b => 'D',
    	r => '2nd'
    }
    );
    my $t0 = Time::HiRes::time();
    my $hoh = aoh2hoh( \@aoh,  'r' ); # second item is pivot key or row name
    my $t1 = Time::HiRes::time();

    p $hoh;
    printf("aoh2hoh in %g seconds\n", $t1 - $t0);
