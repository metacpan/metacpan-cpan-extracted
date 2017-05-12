    use Schedule::Poll;
   
    # Let's run a few things every 3 seconds,
    # and some things every 6 seconds
 
    my $config = {
        a => 3,
        b => 3,
        c => 3,
        d => 6,
        e => 6,
        f => 6,
        g => 1,
        h => 2
    };

    my $poll = Schedule::Poll->new( $config );

    my $x;
    
    while(1) {
        ++$x;

        if (my $aref =  $poll->which  ) {

            for my $each (@$aref) {

                printf("%d %s fired!\n", $x,$each);
            }
        }
        sleep 1;
    }
