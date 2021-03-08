use Test2::V0;

use Sub::Meta;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;

my $p1 = Sub::Meta::Parameters->new(args => ['Str']);
my $p2 = Sub::Meta::Parameters->new(args => ['Int']);

my $r1 = Sub::Meta::Returns->new('Str');
my $r2 = Sub::Meta::Returns->new('Int');

my $obj = bless {} => 'Some';

my @TEST = (
    { subname => 'foo' } => {
    NG => [
    undef, 'invalid other',
    $obj, 'invalid obj',
    { subname => 'bar' }, 'invalid subname',
    { subname => undef }, 'undef subname',
    { subname => 'foo', parameters => $p1 }, 'invalid parameters',
    { subname => 'foo', returns => $r1 }, 'invalid returns',
    ],
    OK => [
    { subname => 'foo' }, 'valid',
    { fullname => 'path::foo' }, 'valid',
    ]},

    # no args
    {  } => {
    NG => [
    { subname => 'foo' }, 'invalid subname',
    ],
    OK => [
    {  }, 'valid',
    ]},

    # p1
    { parameters => $p1 } => {
    NG => [
    { parameters => $p2 }, 'invalid parameters',
    {  }, 'no parameters',
    { parameters => $p1, subname => 'foo' }, 'invalid subname',
    { parameters => $p1, returns => $r1 }, 'invalid returns',
    ],
    OK => [
    { parameters => $p1 }, 'valid',
    ]},

    # r1
    { returns => $r1 } => {
    NG => [
    { returns => $r2 }, 'invalid returns',
    {  }, 'no returns',
    { returns => $r1, subname => 'foo' }, 'invalid subname',
    { returns => $r1, parameters => $p1 }, 'invalid parameters',
    ],
    OK => [
    { returns => $r1 }, 'valid',
    ]},

    # full args
    { subname => 'foo', parameters => $p1, returns => $r1 } => {
    NG => [
    { subname => 'bar', parameters => $p1, returns => $r1 }, 'invalid subname',
    { subname => 'foo', parameters => $p2, returns => $r1 }, 'invalid parameters',
    { subname => 'foo', parameters => $p1, returns => $r2 }, 'invalid returns',
    ],
    OK => [
    { subname => 'foo', parameters => $p1, returns => $r1 }, 'valid',
    { subname => 'foo', parameters => $p1, returns => $r1, stashname => 'main' }, 'valid w/ stashname',
    { subname => 'foo', parameters => $p1, returns => $r1, attribute => ['method'] }, 'valid w/ attribute',
    { subname => 'foo', parameters => $p1, returns => $r1, prototype => '$' }, 'valid w/ prototype',
    ]},

    # method
    { subname => 'foo', is_method => !!1 } => {
    NG => [
    { subname => 'foo', is_method => !!0 }, 'invalid method',
    { subname => 'foo' }, 'invalid method',
    ],
    OK => [
    { subname => 'foo', is_method => !!1 }, 'valid method',
    ]},

    { subname => 'foo', is_method => !!0, } => {
    NG => [
    { subname => 'foo', is_method => !!1 }, 'invalid method',
    ],
    OK => [
    { subname => 'foo', is_method => !!0 }, 'valid method',
    { subname => 'foo' }, 'valid method',
    ]},

    { subname => 'foo', is_method => !!1, parameters => $p1 } => {
    NG => [
    { subname => 'foo', is_method => !!0, parameters => $p1 }, 'invalid method',
    { subname => 'foo',                parameters => $p1 }, 'invalid method',
    { subname => 'foo', is_method => !!1, parameters => $p2 }, 'invalid parameters',
    ],
    OK => [
    { subname => 'foo', is_method => !!1, parameters => $p1 }, 'valid method',
    ]},
);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;
{
    no warnings qw/once/;
    *{Sub::Meta::Parameters::TO_JSON} = sub {
        join ",", map { $_->type } @{$_[0]->args};
    };

    *{Sub::Meta::Returns::TO_JSON} = sub {
        $_[0]->scalar;
    };
}

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta->new($args);
    my $inline = $meta->is_same_interface_inlined('$_[0]');
    my $is_same_interface = eval sprintf('sub { %s }', $inline);

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $is_hash = ref $other_args && ref $other_args eq 'HASH';
                my $other = $is_hash ? Sub::Meta->new($other_args) : $other_args;
                ok !$meta->is_same_interface($other), $test_message;
                ok !$is_same_interface->($other), "inlined: $test_message";
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
                ok $is_same_interface->($other), "inlined: $test_message";
            }
        };
    };
}

done_testing;
