use Test::More tests => 11;

BEGIN {
    use_ok('Race::Condition');
}

diag("Testing Race::Condition $Race::Condition::VERSION");

ok( defined &race::condition, 'race::condition is defined' );
is_deeply( [ race::condition("foo") ], [], 'default race::condition() just return;s' );

{
    no warnings 'redefine';
    my $expect;
    my $name;
    local *race::condition = sub {
        is_deeply( \@_, $expect, $name );
    };

    $expect = [];
    $name   = 'function, no args';
    race::condition();

    $expect = [0];
    $name   = 'function, zero arg';
    race::condition(0);

    $expect = [''];
    $name   = 'function, empty arg';
    race::condition('');

    $expect = [undef];
    $name   = 'function, undef arg';
    race::condition(undef);

    $expect = ['World, Hello'];
    $name   = 'function, str arg';
    race::condition('World, Hello');

    $expect = [ 'Test::More', 'description' ];
    $name = 'class (loaded) method';
    Test::More->race::condition('description');

    $expect = [ 'Flarb::Flarb::Flarb', 'description' ];
    $name = 'class (not loaded) method';
    Flarb::Flarb::Flarb->race::condition('description');

    my $obj = bless {}, 'Race::Condition';
    $expect = [ $obj, 'yabba dabba' ];
    $obj->race::condition('yabba dabba');
}
