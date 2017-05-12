use Test::More;

{
    package Mock;
    use Mouse;

    with 'Spica::Event';
}


subtest 'simple' => sub {
    my $mock = Mock->new;

    ok $mock->on('test1', sub {
        my ($self, ) = @_;
        isa_ok $self => 'Mock', 'fist argument is Context.';
    }), 'added event successful';
    
    isa_ok $mock->trigger('test1') => 'Mock';
};

subtest 'execution sequence' => sub {
    my @data = qw(1 2 3);
    
    my $mock = Mock->new;

    $mock->on('test2', sub {
        is shift(@data) => 1;
    })->on('test2', sub {
        is shift(@data) => 2;
    })->on('test2', sub {
        is shift(@data) => 3;
    })->on('test2', sub {
        is shift(@data) => undef;
    })->trigger('test2');
};

done_testing;
