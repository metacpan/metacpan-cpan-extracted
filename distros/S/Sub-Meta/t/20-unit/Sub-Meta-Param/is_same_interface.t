use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(test_is_same_interface DummyType);

subtest "full args : { name => '\$msg', type => 'Str', required => 1, positional => 1 }" => sub {
    my $meta = Sub::Meta::Param->new({ name => '$msg', type => 'Str', required => 1, positional => 1 });
    my @tests = (
        fail => 'invalid other'      => undef,
        fail => 'invalid object'     => (bless {} => 'Some'),
        fail => 'invalid name'       => { name => '$gsm', type => 'Str', required => 1, positional => 1 },
        fail => 'undef name'         => { name =>  undef, type => 'Str', required => 1, positional => 1 },
        fail => 'invalid type'       => { name => '$msg', type => 'Srt', required => 1, positional => 1 },
        fail => 'invalid required'   => { name => '$msg', type => 'Str', required => 0, positional => 1 },
        fail => 'invalid positional' => { name => '$msg', type => 'Str', required => 1, positional => 0 },
        pass => 'valid'              => { name => '$msg', type => 'Str', required => 1, positional => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "no name: { type => 'Str', required => 1, positional => 1 }" => sub {
    my $meta = Sub::Meta::Param->new({ type => 'Str', required => 1, positional => 1 });
    my @tests = (
        fail       => 'invalid type'       => { type => 'Srt', required => 1, positional => 1 },
        fail       => 'invalid required'   => { type => 'Str', required => 0, positional => 1 },
        fail       => 'invalid positional' => { type => 'Str', required => 1, positional => 0 },
        relax_pass => 'not need name'      => { type => 'Str', required => 1, positional => 1, name => '$foo' },
        pass       => 'valid'              => { type => 'Str', required => 1, positional => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "no type: { name => '\$foo', required => 1, positional => 1 }" => sub {
    my $meta = Sub::Meta::Param->new({ name => '$foo', required => 1, positional => 1 });
    my @tests = (
        fail       => 'invalid name'       => { name => '$boo', required => 1, positional => 1 },
        fail       => 'invalid required'   => { name => '$foo', required => 0, positional => 1 },
        fail       => 'invalid positional' => { name => '$foo', required => 1, positional => 0 },
        relax_pass => 'not need type'      => { name => '$foo', required => 1, positional => 1, type => 'Str' },
        pass       => 'valid'              => { name => '$foo', required => 1, positional => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "no name and type: { required => 1, positional => 1 }" => sub {
    my $meta = Sub::Meta::Param->new({ required => 1, positional => 1 });
    my @tests = (
        fail       => 'invalid required'    => { required => 0, positional => 1 },
        fail       => 'invalid positional'  => { required => 1, positional => 0 },
        relax_pass => 'not need name'       => { required => 1, positional => 1, name => '$foo' },
        relax_pass => 'not need type'       => { required => 1, positional => 1, type => 'Str' },
        pass       => 'valid'               => { required => 1, positional => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "undef optional: { optional => undef }" => sub {
    my $meta = Sub::Meta::Param->new({ optional => undef });
    my @tests = (
        fail       => 'invalid optional' => { optional => 1 },
        relax_pass => 'not need name'    => { optional => undef, name => '$opts' },
        pass       => 'valid'            => { optional => undef },
        pass       => 'valid'            => { optional => 0 },
        pass       => 'valid'            => { required => !!1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "undef named: { named => undef }" => sub {
    my $meta = Sub::Meta::Param->new({ named => undef });
    my @tests = (
        fail => 'invalid named' => { named => 1 },
        pass => 'valid'         => { named => undef },
        pass => 'valid'         => { named => 0 },
        pass => 'valid'         => { positional => !!1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "blessed type { type => \$DummyType }" => sub {
    my $DummyType = DummyType;
    my $Some = bless {} => 'Some';

    my $meta = Sub::Meta::Param->new({ type => $DummyType });
    my @tests = (
        fail => 'empty type'              => {  },
        fail => 'undef type'              => { type => undef },
        fail => 'invalid type'            => { type => $Some },
        fail => 'not eq type name'        => { type => 'some' },
        pass => 'valid'                   => { type => $DummyType },
        pass => 'valid / different ref'   => { type => DummyType },
        pass => 'valid / eq type name'    => { type => 'DummyType' },
    );
    test_is_same_interface($meta, @tests);
};

done_testing;
