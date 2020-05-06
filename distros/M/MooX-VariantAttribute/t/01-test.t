use Moonshine::Test qw/:all/;
use lib '.';
use t::odea::Test;

{
    package Test::Parser::One;

    use Moo;

    sub parse {
        return 'parse string';
    }

    sub parse_file {
        return 'parse file';
    }
}

{
    package Random::Parser::Two;

    use Moo;

    sub parse_string {
        return 'parse string';
    }

    sub parse_from_file {
        return 'parse file';
    }
}

{
    package Another::Parser::Three;

    use Moo;

    sub meth_one {
        return 'parse string';
    }

    sub meth_two {
        return 'parse file';
    }
}

{
    package Just::Dont::Exist;

    use Moo;
}

package main;

my %test_args = (
    'Test::Parser::One'   => Test::Parser::One->new(),
    'Random::Parser::Two' => Random::Parser::Two->new(),
    'Another::Parser::Three' => Another::Parser::Three->new(),
);

moon_test(
    name => 'Test::Parser::One' ,
    build => {
        class => 't::odea::Test',
        args  => {
            parser => $test_args{'Test::Parser::One'},
        }
    },
    instructions => [
        {
            test => 'obj',
            func => 'parser',
            expected => 'Test::Parser::One',
            subtest => [
                {
                    test => 'scalar',
                    func => 'parse',
                    expected => 'parse string',
                },
                {
                    test => 'scalar',
                    func => 'parse_file',
                    expected => 'parse file',
                }
            ],
        }
    ],
);

{
    eval { t::odea::Test->new( parser => Just::Dont::Exist->new )->parser };
    my $death = $@;

    moon_test_one(
        test  => 'like',
        instance => $death,
        expected => qr/Could not find - Just::Dont::Exist/
    );
}

for (sort keys %test_args) {
    moon_test(
        name => $_,
        build => {
            class => 't::odea::Test',
            args  => {
                parser => $test_args{$_},
            }
        },
        instructions => [
            {
                test => 'obj',
                func => 'parser',
                expected => $_,
                subtest => [
                    {
                        test => 'scalar',
                        func => 'parse_string',
                        expected => 'parse string',
                    },
                    {
                        test => 'scalar',
                        func => 'parse_file',
                        expected => 'parse file',
                    }
                ],
            }
        ],
    );
}

moon_test(
    name => 'string test',
    build => {
        class => 't::odea::Test',
        args  => {}
    },
    instructions => [
        {
            test => 'scalar',
            func => 'string',
            args => [ 'one' ],
            args_list => 1,
            expected => 'one - cold, cold, cold inside',
        },
        {
            test => 'scalar',
            func => 'string',
            args => [],
            args_list => 1,
            expected => 'one - cold, cold, cold inside',
        },
        {
            test => 'scalar',
            func => 'string',
            args => [ 'two' ],
            args_list => 1,
            expected => 'two - don\'t look at me that way',
        },
        {
            test => 'scalar',
            func => 'string',
            args => [],
            args_list => 1,
            expected => 'two - don\'t look at me that way',
        },
         {
            test => 'scalar',
            func => 'string',
            args => [ 'three' ],
            args_list => 1,
            expected => 'three - how hard will i fall if I live a double life',
        },
        {
            test => 'scalar',
            func => 'string',
            args => [],
            args_list => 1,
            expected => 'three - how hard will i fall if I live a double life',
        },
    ],
);

moon_test(
    name => 'ref test',
    build => {
        class => 't::odea::Test',
        args  => {}
    },
    instructions => [
        {
            test => 'scalar',
            func => 'refs',
            args => [ 'one' ],
            args_list => 1,
            expected => 'refs returned - SCALAR - one',
        },
        {
            test => 'scalar',
            func => 'refs',
            args => [],
            args_list => 1,
            expected => 'refs returned - SCALAR - one',
        },
        {
            test => 'scalar',
            func => 'refs',
            args => [ { one => 'two' } ],
            args_list => 1,
            expected => 'refs returned - HASH - one=>two',
        },
        {
            test => 'scalar',
            func => 'refs',
            args => [ ],
            args_list => 1,
            expected => 'refs returned - HASH - one=>two',
        },
        {
            test => 'scalar',
            func => 'refs',
            args => [[qw/one two/]],
            args_list => 1,
            expected => 'refs returned - ARRAY - one,two',
        },
        {
            test => 'scalar',
            func => 'refs',
            args => [ ],
            args_list => 1,
            expected => 'refs returned - ARRAY - one,two',
        },
    ],
);

sunrise(35, strut);
