#!perl

use Test::More tests => 18;

BEGIN {
    use_ok('POE');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Filter::Line');
    use_ok('POE::Wheel::Run');
    use_ok('WWW::Google::Calculator');
    use_ok('Carp');
	use_ok( 'POE::Component::WWW::Google::Calculator' );
}

diag( "Testing POE::Component::WWW::Google::Calculator $POE::Component::WWW::Google::Calculator::VERSION, Perl $], $^X" );

use POE qw(Component::WWW::Google::Calculator);

my $poco = POE::Component::WWW::Google::Calculator->spawn( alias => 'calc',
debug => 1);

can_ok($poco, qw(calc shutdown session_id));

POE::Session->create(
    package_states => [
        'main' => [ qw( _start calc_result calc_method_result ) ],
    ],
);

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('test_session');
        },
        got_calc => \&got_calc,
    }
);
my $tested_tests = 0;
$poe_kernel->run;

sub _start {
    $poe_kernel->alias_set('foo');
    $poe_kernel->post( 'calc' => 'calc' => {
            term => '2+2',
            event => 'calc_result',
            _random_name => 'random_value',
        }
    );
    print "\nPosted a calc event. Trying to send a query "
        . "with OO interface...\n";
    $poco->calc( {
            term => '3+3',
            event => 'calc_method_result',
            _user => 'test',
        }
    );
    
    print "\nNow sending a request with 'session' parameter\n";
    eval { $poco->calc(
        {
            term => '2/2',
            event => 'got_calc',
            session => 'test_session',
            _user   => 'Joe Shmoe',
        }
    ); };

}

sub calc_method_result {
    my $result = $_[ARG0];
    ok(
        ref $result eq 'HASH',
        "(method call) Expecting result as a hashref."
            . " And ref(\$result) gives us: " . ref $result
    );
    
    if ( $result->{error} ) {
        ok(
            !defined ($result->{out}),
            "(method call) Got error. Result should be undefined"
                . " Error text: `$result->{error}`"
        );
    }
    else {
        ok(
            $result->{out} eq '3 + 3 = 6',
            "(method call) Did we get correct result? "
                . "(expecting: '3 + 3 = 6' "
                . "got '$result->{out}')"
        );
        ok(
            $result->{_user} eq 'test',
            "(method call) user defined args (expecting: "
                . "'test' "
                . "got '$result->{_user}')"
        );
    }
    
    $poco->shutdown if ++$tested_tests eq 3;
}

sub calc_result {
    my ( $kernel, $result ) = @_[ KERNEL, ARG0 ];
    
    ok(
        ref $result eq 'HASH',
        "(event call) expecting result as a hashref in"
            . " calc_result()."
            . " And ref(\$result) gives us: " . ref $result
    );
    
    if ( $result->{error} ) {
        ok(
            !defined ($result->{out}),
            "(event call) Got error. Result should be undefined."
                . " Error text: `$result->{error}`"
        );
    }
    else {
        ok(
            $result->{out} eq '2 + 2 = 4',
            "(event call) Did we get correct result? "
                . "(expecting: '2 + 2 = 4' "
                . "got '$result->{out}')"
        );

        ok(
            $result->{_random_name} eq 'random_value',
            "(event call) User defined args (expecting: 'random_value' "
                . "got '$result->{_random_name}')"
        );
    }

    $poco->shutdown if ++$tested_tests eq 3;

    print "\n";
    ok(
        2+2 == 4,
        "testing if 2+2 IS infact 4. If this test fails, burn "
            . "your computer before it eats you!"
    );
    print "\n";
}

sub got_calc {
    my ( $kernel, $result ) = @_[ KERNEL, ARG0 ];
    
    print "\n###  Got results from another session:\n";
    
    ok(
        ref $result eq 'HASH',
        "expecting result as a hashref in"
            . " got_calc()."
            . " And ref(\$result) gives us: " . ref $result
    );
    
    if ( $result->{error} ) {
        ok(
            !defined ($result->{out}),
            "Got error. Result should be undefined."
                . " Error text: `$result->{error}`"
        );
    }
    else {
        ok(
            $result->{out} eq '2 / 2 = 1',
            "Did we get correct result? "
                . "(expecting: '2 / 2 = 1' "
                . "got '$result->{out}')"
        );

        ok(
            $result->{_user} eq 'Joe Shmoe',
            "User defined args (expecting: 'Joe Shmoe' "
                . "got '$result->{_user}')"
        );
    }

    $poco->shutdown if ++$tested_tests eq 3;
}
