{
    # tests #14
    # Make sure that trimmed_mean caching works but checking execution times
    # This test may fail on very fast machines but I'm not sure how to get
    # better timing without requiring extra modules to be added.

    my $stat = Statistics::Descriptive::Full->new();
    ##Make this a really big array so that it takes some time to execute!
    $stat->add_data((1,2,3,4,5,6,7,8,9,10,11,12,13) x 10000);

    my ($t0,$t1,$td);
    my @t = ();
    foreach (0..1) {
      $t0 = new Benchmark;
      $stat->trimmed_mean(0.1,0.1);
      $t1 = new Benchmark;
      $td = timediff($t1,$t0);
      push @t, $td->cpu_p();
    }

    # TEST
    ok ($t[1] < $t[0],
        "trimmed_mean caching works",
    );
}
