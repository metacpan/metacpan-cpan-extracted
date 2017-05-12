use Test2::Bundle::Extended -target => 'Scientist';

my $ctx = {
    one_key    => 'first value',
    second_key => 'second value',
};

my $experiment = $CLASS->new(
    use        => sub { 10 },
    try        => sub { 20 },
    context    => $ctx,
);

my $result = $experiment->run;

is $experiment->result->{context}, $ctx, 'result was given context';

done_testing;
