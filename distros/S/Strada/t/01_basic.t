#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

# Check if the module loads
BEGIN { use_ok('Strada') }

# Check if libmath.so exists (built from example)
my $lib_path = "$Bin/../example/libmath.so";
unless (-f $lib_path) {
    plan skip_all => "libmath.so not built - run 'cd example && ./build.sh' first";
}

# Test low-level API
subtest 'Low-level API' => sub {
    my $handle = Strada::load($lib_path);
    ok($handle, 'load() returns handle');

    my $add_func = Strada::get_func($handle, 'math_lib__add');
    ok($add_func, 'get_func() returns function pointer');

    my $result = Strada::call($add_func, 2, 3);
    is($result, 5, 'call() with two args works');

    Strada::unload($handle);
    pass('unload() completed');
};

# Test high-level API
subtest 'High-level API' => sub {
    my $lib = Strada::Library->new($lib_path);
    ok($lib, 'Library->new() works');

    is($lib->call('math_lib__add', 10, 20), 30, 'add works');
    is($lib->call('math_lib__subtract', 50, 30), 20, 'subtract works');
    is($lib->call('math_lib__multiply', 6, 7), 42, 'multiply works');

    my $greeting = $lib->call('math_lib__greet', 'Perl');
    is($greeting, 'Hello, Perl!', 'greet works');

    $lib->unload();
    pass('Library->unload() completed');
};

# Test array handling
subtest 'Array handling' => sub {
    my $lib = Strada::Library->new($lib_path);

    # Get array from Strada
    my $nums = $lib->call('math_lib__get_numbers');
    is_deeply($nums, [10, 20, 30, 40, 50], 'get_numbers returns array');

    # Pass array to Strada
    my $sum = $lib->call('math_lib__sum_array', [1, 2, 3, 4, 5]);
    is($sum, 15, 'sum_array works with array arg');

    $lib->unload();
};

# Test hash handling
subtest 'Hash handling' => sub {
    my $lib = Strada::Library->new($lib_path);

    # Get hash from Strada
    my $person = $lib->call('math_lib__get_person');
    is($person->{name}, 'Alice', 'get_person returns correct name');
    is($person->{age}, 30, 'get_person returns correct age');
    is($person->{city}, 'Boston', 'get_person returns correct city');

    # Pass hash to Strada
    my $desc = $lib->call('math_lib__describe_person', { name => 'Bob', age => 25 });
    is($desc, 'Bob is 25 years old', 'describe_person works with hash arg');

    $lib->unload();
};

done_testing();
