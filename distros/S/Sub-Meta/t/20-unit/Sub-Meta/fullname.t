use Test2::V0;

use Sub::Meta;

my @tests = (
    # message      # fullname arguments  # expected fullname    # expected subinfo
    'empty'         => ''                => ''                  => [undef, undef],
    'Foo::Bar::baz' => 'Foo::Bar::baz'   => 'Foo::Bar::baz'     => ['Foo::Bar', 'baz'],
    'Foo::bar'      => 'Foo::bar'        => 'Foo::bar'          => ['Foo', 'bar'],
    'Foo::Bar'      => 'Foo::Bar'        => 'Foo::Bar'          => ['Foo', 'Bar'],
    'Foo::_'        => 'Foo::_'          => 'Foo::_'            => ['Foo', '_'],
    'main::_method' => 'main::_method'   => 'main::_method'     => ['main', '_method'],
    'One1::two'     => 'One1::two'       => 'One1::two'         => ['One1','two'],
    'Foo::'         => 'Foo::'           => ''                  => [undef, undef],
    'Foo::Bar::'    => 'Foo::Bar::'      => ''                  => [undef, undef],
    '::bar'         => '::bar'           => ''                  => [undef, undef],
    'bar'           => 'bar'             => ''                  => [undef, undef],
);

while (@tests) {
    my ($message, $args, $expected_fullname, $expected_subinfo) = splice @tests, 0, 4;

    my $meta = Sub::Meta->new;
    subtest $message => sub {
        is $meta->set_fullname($args), $meta;
        is $meta->fullname, $expected_fullname;
        is $meta->subinfo, $expected_subinfo;
    };
}

done_testing;
