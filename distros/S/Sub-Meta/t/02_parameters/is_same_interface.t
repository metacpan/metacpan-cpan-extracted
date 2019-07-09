use Test2::V0;

use Sub::Meta::Parameters;

my $p1 = Sub::Meta::Param->new("Str");
my $p2 = Sub::Meta::Param->new("Int");

my @TEST = (
    { args => [], slurpy => 0, nshift => 0 } => {
    NG => [
    { args => [$p1], slurpy => 0, nshift => 0 }, 'invalid args',
    { args => [], slurpy => 1, nshift => 0 }, 'invalid slurpy',
    #{ args => [], slurpy => 0, nshift => 1 }, 'invalid nshift', => exception _assert_nshift
    ],
    OK => [
    { args => [], slurpy => 0, nshift => 0 }, 'valid',
    ]},

    # nshift undef
    { args => [$p1], nshift => undef } => {
    NG => [
    { args => [$p1], nshift => 1 }, 'invalid nshift/1',
    { args => [$p1], nshift => 0 }, 'invalid nshift/0',
    ],
    OK => [
    { args => [$p1], nshift => undef }, 'valid',
    ]},

    # one args
    { args => [$p1], slurpy => 0, nshift => 0 } => {
    NG => [
    { args => [$p2], slurpy => 0, nshift => 0 }, 'invalid args',
    { args => [$p1, $p2], slurpy => 0, nshift => 0 }, 'too many args',
    { args => [], slurpy => 0, nshift => 0 }, 'too few args',
    ],
    OK => [
    { args => [$p1], slurpy => 0, nshift => 0 }, 'valid',
    ]},

    # two args
    { args => [$p1, $p2], slurpy => 0, nshift => 0 } => {
    NG => [
    { args => [$p2, $p1], slurpy => 0, nshift => 0 }, 'invalid args',
    { args => [$p1, $p2, $p1], slurpy => 0, nshift => 0 }, 'too many args',
    { args => [$p1], slurpy => 0, nshift => 0 }, 'too few args',
    ],
    OK => [
    { args => [$p1, $p2], slurpy => 0, nshift => 0 }, 'valid',
    ]},

    # slurpy
    { args => [], slurpy => 1, nshift => 0 } => {
    NG => [
    { args => [$p1], slurpy => 0, nshift => 0 }, 'invalid args',
    { args => [], slurpy => 0, nshift => 0 }, 'invalid slurpy',
    #{ args => [], slurpy => 0, nshift => 1 }, 'invalid nshift', => exception _assert_nshift
    ],
    OK => [
    { args => [], slurpy => 1, nshift => 0 }, 'valid',
    ]},

    # nshift
    { args => [$p1], slurpy => 0, nshift => 1 } => {
    NG => [
    { args => [$p2], slurpy => 0, nshift => 1 }, 'invalid args',
    { args => [$p1, $p2], slurpy => 0, nshift => 1 }, 'too many args',
    { args => [$p1], slurpy => 1, nshift => 1 }, 'invalid slurpy',
    ],
    OK => [
    { args => [$p1], slurpy => 0, nshift => 1 }, 'valid',
    ]},

    # slurpy & nshift
    { args => [$p1], slurpy => 1, nshift => 1 } => {
    NG => [
    { args => [$p2], slurpy => 1, nshift => 1 }, 'invalid args',
    { args => [$p1, $p2], slurpy => 1, nshift => 1 }, 'too many args',
    { args => [$p1], slurpy => 0, nshift => 1 }, 'invalid slurpy',
    { args => [$p1], slurpy => 1, nshift => 0 }, 'invalid nshift',
    ],
    OK => [
    { args => [$p1], slurpy => 1, nshift => 1 }, 'valid',
    ]},


);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;
{
    no warnings qw/once/;
    *{Sub::Meta::Param::TO_JSON} = sub {
        my $s = $_[0]->type;
        $s .= ':named' if $_[0]->named;
        $s .= ':optional' if $_[0]->optional;
        return $s;
    }
}

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Parameters->new($args);

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $other = Sub::Meta::Parameters->new($other_args);
                ok !$meta->is_same_interface($other), $test_message;
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta::Parameters->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
            }
        };
    };
}

done_testing;
