use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(sub_meta);
use lib 't/lib';

subtest 'set_parameters' => sub {
    use MySubMeta::Parameters;
    my $parameters   = Sub::Meta::Parameters->new(args => ['Int']);
    my $myparameters = MySubMeta::Parameters->new(args => ['Str', 'Str']);

    my @tests = (
        # message         # arguments            # expected
        'parameters'      => $parameters         => $parameters,
        'my parameters'   => $myparameters       => $myparameters,
        'parameters args' => { args => ['Int'] } => $parameters,
    );

    my $meta = Sub::Meta->new;
    while (@tests) {
        my ($message, $args, $expected) = splice @tests, 0, 3;

        is $meta->set_parameters($args), $meta, 'set_parameters';
        is $meta, sub_meta({
            parameters => $expected,
        });
    }

    note 'exceptions';
    ok dies { $meta->set_parameters(bless {}, 'Foo') }, 'not Sub::Meta::Parameters object';
    ok dies { $meta->set_parameters({}) },              'hashref';
    ok dies { $meta->set_parameters('Int') },           'string';
    ok dies { $meta->set_parameters(['Int']) },         'arrayref';
};

subtest 'set_args' => sub {
    my $meta = Sub::Meta->new;

    is $meta->set_args(['Int']), $meta;
    is $meta->args, Sub::Meta::Parameters->new(args => ['Int'])->args;

    is $meta->set_args(['Str', 'Str']), $meta;
    is $meta->args, Sub::Meta::Parameters->new(args => ['Str', 'Str'])->args;

    is $meta->set_args([]), $meta;
    is $meta->args, Sub::Meta::Parameters->new(args => [])->args;
};

subtest 'set_slurpy' => sub {
    my $meta = Sub::Meta->new;
    ok dies { $meta->set_slurpy('Int') }, 'no parameters';

    is $meta->set_args([]), $meta, 'set parameters';

    is $meta->set_slurpy('Int'), $meta;
    is $meta->slurpy, Sub::Meta::Param->new(isa => 'Int');

    is $meta->set_slurpy(Sub::Meta::Param->new(isa => 'Str')), $meta;
    is $meta->slurpy, Sub::Meta::Param->new(isa => 'Str');
};

subtest 'set_nshift' => sub {
    my $meta = Sub::Meta->new(args => ['Str']);
    $meta->set_nshift(1);
    is $meta->nshift, 1;

    $meta->set_is_method(1);
    $meta->set_nshift(1);
    is $meta->nshift, 1;

    like dies { $meta->set_nshift(0) },
    qr/nshift of method cannot be zero/, 'invalid nshift';
};

subtest 'invocant/invocants/set_invocant' => sub {
    my $invocant = Sub::Meta::Param->new(name => '$self');
    my $p1 = Sub::Meta::Param->new(type => 'Str');

    my $meta = Sub::Meta->new(args => [$p1]);
    is $meta->all_args, [ $p1 ];
    is $meta->invocant, undef;

    is $meta->set_invocant($invocant), $meta;
    is $meta->invocant, $invocant;
    is $meta->invocants, [ $invocant ];

    is $meta->all_args, [ $invocant, $p1 ];
    is $meta->args, [$p1];
};



done_testing;
