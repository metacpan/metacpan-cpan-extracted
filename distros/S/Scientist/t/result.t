use Test2::V0 -target => 'Scientist';

subtest result => sub {
    my $experiment = $CLASS->new(
        use => sub { 10 },
        try => sub { 20 },
    );

    my $result = $experiment->run;

    is $result, 10, 'Returns the result of the "use" code';
};

subtest result_duration => sub {
    my $experiment = $CLASS->new(
        use => sub { 10 },
        try => sub { 20 },
    );

    $experiment->run;

    ok $experiment->result->{control}{duration} > 0,
        'Returns duration timing of control';

    ok $experiment->result->{candidate}{duration} > 0,
        'Returns duration timing of candidate';
};

subtest result_match => sub {
    my $data = [ { foo => 1 }, { bar => 'x' } ];

    my $experiment = $CLASS->new(
        use => sub { $data },
        try => sub { $data },
    );

    my $result = $experiment->run;

    is $result, $data, 'Returns the result of the "use" code';
    ok !$experiment->result->{mismatched},
        'Correctly identified no mismatch between control and candidate';
};

subtest result_mismatch => sub {
    my $old = [ { foo => 1 }, { bar => 'x'   } ];
    my $new = [ { for => 1 }, { bar => 'ZZZ' } ];

    my $experiment = $CLASS->new(
        use => sub { $old },
        try => sub { $new },
    );

   my $result = $experiment->run;

   is $result, $old, 'Returns the result of the "use" code';
   ok $experiment->result->{mismatched},
       'Correctly identified a mismatch between control and candidate';
};

subtest result_observation => sub {
    my $experiment = $CLASS->new(
        use => sub { 10 },
        try => sub { 20 },
    );

    $experiment->run;

    is $experiment->result->{observation}{candidate},
        20,
        'Observation candidate data correct';

    is $experiment->result->{observation}{control},
        10,
        'Observation control data correct';

    is $experiment->result->{observation}{diagnostic},
        ( "+------+---------+----+-----------+\n"
        . "| PATH | CONTROL | OP | CANDIDATE |\n"
        . "+------+---------+----+-----------+\n"
        . "| [0]  | 20      | eq | 10        |\n"
        . "+------+---------+----+-----------+" ),
        'Observation diagnostic correct';
};

done_testing;
