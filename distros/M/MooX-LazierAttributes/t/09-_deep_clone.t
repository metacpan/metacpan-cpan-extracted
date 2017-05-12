use Test::More;

require MooX::LazierAttributes;

run_test(
    args => 'one two',
    expected => 'one two',
    name => '_deep_clone a scalar',
);

run_test(
    args => { one => 'two' },
    expected => { one => 'two' },
    name => '_deep_clone a Hash',
);

run_test(
    args => [ qw/one two/ ],
    expected => [ qw/one two/ ],
    name => '_deep_clone a Array' ,
);

sub run_test {
    my %test = @_;
    return is_deeply( &MooX::LazierAttributes::_deep_clone($test{args}), $test{expected}, "$test{name}");
}

done_testing();
