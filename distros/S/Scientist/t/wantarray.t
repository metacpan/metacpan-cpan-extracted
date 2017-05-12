use Test2::Bundle::Extended -target => 'Scientist';

subtest wantarray_only_control => sub {
    my $experiment = $CLASS->new(
        use     => \&whattayawant,
        enabled => 0,
    );

    my $scalar_result = $experiment->run;
    my @list_result   = $experiment->run;

    is $scalar_result, 'one two three', 'Got scalar result';
    is \@list_result, [qw/one two three/], 'Got list result';
};

subtest wantarray_with_candidate => sub {
    my @a = qw/one two three/;

    my $experiment = $CLASS->new(
        use => \&whattayawant,
        try => \&whattayawant,
    );

    my $scalar_result = $experiment->run;
    my @list_result   = $experiment->run;

    is $scalar_result, 'one two three', 'Got scalar result';
    is \@list_result, [qw/one two three/], 'Got list result';
};

sub whattayawant {
    return wantarray ? qw/one two three/ : "one two three";
}

done_testing;
