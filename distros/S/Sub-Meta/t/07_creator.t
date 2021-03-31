use Test2::V0;

use Sub::Meta::Creator;

sub finder {
    my $sub = shift;
    return { sub => $sub };
}

subtest 'new' => sub {
    like dies { Sub::Meta::Creator->new() }, qr/^required finders/;
    like dies { Sub::Meta::Creator->new(finders => '') }, qr/^finders must be an arrayref/;
    like dies { Sub::Meta::Creator->new(finders => {}) }, qr/^finders must be an arrayref/;
    like dies { Sub::Meta::Creator->new(finders => ['']) }, qr/^elements of finders have to be a code reference/;
    like dies { Sub::Meta::Creator->new(finders => [{}]) }, qr/^elements of finders have to be a code reference/;

    subtest 'create' => sub {
        my $creator = Sub::Meta::Creator->new(finders => [ \&finder ]);
        isa_ok $creator, 'Sub::Meta::Creator';
    };

    subtest 'create by hashref' => sub {
        my $creator = Sub::Meta::Creator->new({ finders => [ \&finder ] });
        isa_ok $creator, 'Sub::Meta::Creator';
    };
};

subtest 'accessors' => sub {
    my $creator = Sub::Meta::Creator->new(finders => [ \&finder ]);

    is $creator->sub_meta_class, 'Sub::Meta';
    is $creator->finders, [ \&finder ];
};

subtest 'find_materials' => sub {
    subtest 'finders is empty list' => sub {
        my $creator = Sub::Meta::Creator->new(finders => [ ]);
        is $creator->find_materials(sub {}), undef;
    };

    subtest 'empty finder' => sub {
        my $creator = Sub::Meta::Creator->new(finders => [ sub {} ]);
        is $creator->find_materials(sub {}), undef;
    };

    subtest 'one finder' => sub {
        my $code = sub {};
        my $creator = Sub::Meta::Creator->new(finders => [ sub { +{ hello => $_[0] } } ]);
        is $creator->find_materials($code), { hello => $code };
    };

    subtest 'multi finder' => sub {
        my $code = sub {};
        my $creator = Sub::Meta::Creator->new(finders => [ sub {}, sub { +{ sub => $_[0] } } ]);
        is $creator->find_materials($code), { sub => $code };
    };
};

subtest 'create' => sub {
    subtest 'empty finder' => sub {
        my $code = sub {};
        my $creator = Sub::Meta::Creator->new(finders => [ sub {} ]);
        is $creator->create($code), undef;
    };

    subtest 'finder' => sub {
        my $code = sub {};
        my $creator = Sub::Meta::Creator->new(finders => [ sub { +{ subname => 'hello' } } ]);
        is $creator->create($code), Sub::Meta->new(subname => 'hello');
    };
};

done_testing;
