use Test2::V0;

use Sub::Meta::Parameters;

my $slurpy = Sub::Meta::Param->new("Slurpy");
my $p1 = Sub::Meta::Param->new("Str");
my $p2 = Sub::Meta::Param->new("Int");
sub param { my @args = @_; return Sub::Meta::Param->new(@args); }

my $obj = bless {} => 'Some';

my @TEST = (
    { args => [], slurpy => undef, nshift => 0 } => {
    NG => [
    undef, 'invalid other',
    $obj, 'invalid obj',
    { args => [$p1], slurpy => undef, nshift => 0 }, 'invalid args',
    { args => [], slurpy => $slurpy, nshift => 0 }, 'invalid slurpy',
    { args => [], slurpy => undef, nshift => 1 }, 'invalid nshift',
    ],
    OK => [
    { args => [], slurpy => undef, nshift => 0 }, 'valid',
    ]},

    # one args
    { args => [$p1], slurpy => undef, nshift => 0 } => {
    NG => [
    { args => [$p2], slurpy => undef, nshift => 0 }, 'invalid args',
    { args => [$p1, $p2], slurpy => undef, nshift => 0 }, 'too many args',
    { args => [], slurpy => undef, nshift => 0 }, 'too few args',
    ],
    OK => [
    { args => [$p1], slurpy => undef, nshift => 0 }, 'valid',
    ]},

    # two args
    { args => [$p1, $p2], slurpy => undef, nshift => 0 } => {
    NG => [
    { args => [$p2, $p1], slurpy => undef, nshift => 0 }, 'invalid args',
    { args => [$p1, $p2, $p1], slurpy => undef, nshift => 0 }, 'too many args',
    { args => [$p1], slurpy => undef, nshift => 0 }, 'too few args',
    ],
    OK => [
    { args => [$p1, $p2], slurpy => undef, nshift => 0 }, 'valid',
    ]},

    # slurpy
    { args => [], slurpy => $slurpy, nshift => 0 } => {
    NG => [
    { args => [$p1], slurpy => undef, nshift => 0 }, 'invalid args',
    { args => [], slurpy => undef, nshift => 0 }, 'invalid slurpy',
    { args => [], slurpy => $slurpy, nshift => 1 }, 'invalid nshift',
    ],
    OK => [
    { args => [], slurpy => $slurpy, nshift => 0 }, 'valid',
    ]},

    # empty slurpy
    { args => [], nshift => 0 } => {
    NG => [
    { args => [], slurpy => 'Str', nshift => 0 }, 'invalid slurpy',
    ],
    OK => [
    { args => [], nshift => 0 }, 'valid',
    ]},

    # nshift
    { args => [$p1], slurpy => undef, nshift => 1 } => {
    NG => [
    { args => [$p2], slurpy => undef, nshift => 1 }, 'invalid args',
    { args => [$p1, $p2], slurpy => undef, nshift => 1 }, 'too many args',
    { args => [$p1], slurpy => $slurpy, nshift => 1 }, 'invalid slurpy',
    ],
    OK => [
    { args => [$p1], slurpy => undef, nshift => 1 }, 'valid',
    ]},

    # slurpy & nshift
    { args => [$p1], slurpy => $slurpy, nshift => 1 } => {
    NG => [
    { args => [$p2], slurpy => $slurpy, nshift => 1 }, 'invalid args',
    { args => [$p1, $p2], slurpy => $slurpy, nshift => 1 }, 'too many args',
    { args => [$p1], slurpy => undef, nshift => 1 }, 'invalid slurpy',
    { args => [$p1], slurpy => $slurpy, nshift => 0 }, 'invalid nshift',
    { args => [$p1], slurpy => $slurpy, invocant => param(invocant => 1, name => '$self') }, 'valid',
    ],
    OK => [
    { args => [$p1], slurpy => $slurpy, nshift => 1 }, 'valid',
    { args => [$p1], slurpy => $slurpy, invocant => param(invocant => 1) }, 'valid',
    ]},

    # default invocant
    { args => [], invocant => param(invocant => 1) } => {
    NG => [
    { args => [], invocant => param(invocant => 1, name => '$class') }, 'invalid invocant',
    ],
    OK => [
    { args => [], invocant => param(invocant => 1) }, 'valid',
    { args => [], nshift => 1 }, 'valid nshift',
    ]},

    # invocant
    { args => [], invocant => param(invocant => 1, name => '$self') } => {
    NG => [
    { args => [], nshift => 0 }, 'invalid nshift',
    { args => [], nshift => 1 }, 'invalid nshift',
    { args => [], invocant => param(invocant => 1, name => '$class') }, 'invalid invocant',
    { args => [param(invocant => 1, name => '$self')] }, 'invalid invocant',
    ],
    OK => [
    { args => [], invocant => param(invocant => 1, name => '$self') }, 'valid',
    ]},
);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;
{
    no warnings qw/once/; ## no critic (ProhibitNoWarnings)
    *{Sub::Meta::Param::TO_JSON} = sub {
        my $s = $_[0]->type;
        $s .= ':named' if $_[0]->named;
        $s .= ':optional' if $_[0]->optional;
        return $s;
    }
}

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Parameters->new($args);
    my $inline = $meta->is_same_interface_inlined('$_[0]');
    my $is_same_interface = eval sprintf('sub { %s }', $inline); ## no critic (ProhibitStringyEval)

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $is_hash = ref $other_args && ref $other_args eq 'HASH';
                my $other = $is_hash ? Sub::Meta::Parameters->new($other_args) : $other_args;
                ok !$meta->is_same_interface($other), $test_message;
                ok !$is_same_interface->($other), "inlined: $test_message";
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta::Parameters->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
                ok $is_same_interface->($other), "inlined: $test_message";
            }
        };
    };
}

done_testing;
