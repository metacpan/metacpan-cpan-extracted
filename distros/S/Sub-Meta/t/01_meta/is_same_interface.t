use Test2::V0;

use Sub::Meta;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;

my $p1 = Sub::Meta::Parameters->new(args => ['Str']);
my $p2 = Sub::Meta::Parameters->new(args => ['Int']);

my $r1 = Sub::Meta::Returns->new('Str');
my $r2 = Sub::Meta::Returns->new('Int');


my @TEST = (
    { subname => 'foo' } => {
    NG => [
    { subname => 'bar' }, 'invalid subname',
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

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $other = Sub::Meta->new($other_args);
                ok !$meta->is_same_interface($other), $test_message;
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
            }
        };
    };
}

done_testing;
