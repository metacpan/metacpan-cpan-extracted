use Test2::V0;

use Sub::Meta::Returns;
use Sub::Meta::Test qw(test_is_same_interface DummyType);

subtest "scalar: { scalar => 'Str', list => undef, void => undef }" => sub {
    my $meta = Sub::Meta::Returns->new({ scalar => 'Str', list => undef, void => undef });
    my @tests = (
        fail => 'invalid other'  => undef,
        fail => 'invalid obj'    => (bless {} => 'Some'),
        fail => 'invalid scalar' => { scalar => 'Int', list => undef, void => undef },
        relax_pass => 'invalid list'   => { scalar => 'Str', list => 'Str', void => undef },
        relax_pass => 'invalid void'   => { scalar => 'Str', list => undef, void => 'Str' },
        pass => 'valid'          => { scalar => 'Str', list => undef, void => undef },
    );
    test_is_same_interface($meta, @tests);
};

subtest "list: { scalar => undef, list => 'Str', void => undef }" => sub {
    my $meta = Sub::Meta::Returns->new({ scalar => undef, list => 'Str', void => undef });
    my @tests = (
        fail => 'invalid list'   => { scalar => undef, list => 'Int', void => undef },
        relax_pass => 'invalid scalar' => { scalar => 'Str', list => 'Str', void => undef },
        relax_pass => 'invalid void'   => { scalar => undef, list => 'Str', void => 'Str' },
        pass => 'valid'          => { scalar => undef, list => 'Str', void => undef },
    );
    test_is_same_interface($meta, @tests);
};

subtest "void: { scalar => undef, list => undef, void => 'Str' }" => sub {
    my $meta = Sub::Meta::Returns->new({ scalar => undef, list => undef, void => 'Str' });
    my @tests = (
        fail => 'invalid void'   => { scalar => undef, list => undef, void => 'Int' },
        relax_pass => 'invalid scalar' => { scalar => 'Str', list => undef, void => 'Str' },
        relax_pass => 'invalid list'   => { scalar => undef, list => 'Str', void => 'Str' },
        pass => 'valid'          => { scalar => undef, list => undef, void => 'Str' },
    );
    test_is_same_interface($meta, @tests);
};

subtest "array: { scalar => [ 'Str', 'Str' ], list => undef, void => undef }" => sub {

    my $meta = Sub::Meta::Returns->new({ scalar => [ 'Str', 'Str' ], list => undef, void => undef });
    my @tests = (
        fail => 'not array'      => { scalar => 'Str', list => undef, void => undef },
        fail => 'too few types'  => { scalar => [ 'Str' ], list => undef, void => undef },
        fail => 'too many types' => { scalar => [ 'Str', 'Str', 'Str' ], list => undef, void => undef },
        fail => 'invalid type'   => { scalar => [ 'Str', 'Int' ], list => undef, void => undef },
        pass => 'valid'          => { scalar => [ 'Str', 'Str' ], list => undef, void => undef },
    );
    test_is_same_interface($meta, @tests);
};

subtest "reference but not array: { scalar => \$DummyType, list => undef, void => undef }" => sub {
    my $DummyType = DummyType;
    my $Some = bless {} => 'Some';

    my $meta = Sub::Meta::Returns->new({ scalar => $DummyType, list => undef, void => undef });
    my @tests = (
        fail => 'invalid scalar'        => { scalar => "Foo", list => undef, void => undef },
        fail => 'invalid scalar'        => { scalar => $Some, list => undef, void => undef },
        pass => 'valid'                 => { scalar => $DummyType, list => undef, void => undef },
        pass => 'valid / different ref' => { scalar => DummyType, list => undef, void => undef },
        pass => 'valid / eq type name'  => { scalar => "DummyType", list => undef, void => undef },
    );
    test_is_same_interface($meta, @tests);
};

done_testing;
