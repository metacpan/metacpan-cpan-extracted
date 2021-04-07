use Test2::V0;

use Sub::Meta::Parameters;

my $Slurpy = Sub::Meta::Param->new("Slurpy");
my $Str = Sub::Meta::Param->new("Str");
my $Int = Sub::Meta::Param->new("Int");

my $obj = bless {} => 'Some';

my @TEST = (
    { args => [] } => [
    undef, 'must be Sub::Meta::Parameters. got: ',
    $obj, qr/^must be Sub::Meta::Parameters\. got: Some/,
    { args => [$Str] }, 'args length is not equal. got: 1, expected: 0', 
    { args => [], slurpy => $Slurpy }, 'should not have slurpy', 
    { args => [], nshift => 1 }, 'nshift is not equal. got: 1, expected: 0', 
    { args => [] }, '', # valid
    { args => [], slurpy => undef }, '', # valid
    { args => [], nshift => 0 }, '', # valid
    { args => [], slurpy => undef, nshift => 0 }, '', # valid
    ],

    # one args
    { args => [$Str] } => [
    { args => [$Int] }, 'args[0] is invalid. got: Int, expected: Str',
    { args => [$Str] }, '', # valid
    ],

    # two args
    { args => [$Str, $Int] } => [
    { args => [$Int, $Str] }, 'args[0] is invalid. got: Int, expected: Str',
    { args => [$Str, $Str] }, 'args[1] is invalid. got: Str, expected: Int',
    { args => [$Str, $Int] }, '', # valid
    ],

    # slurpy
    { args => [], slurpy => $Str } => [
    { args => [] }, 'invalid slurpy. got: , expected: Str',
    { args => [], slurpy => $Int }, 'invalid slurpy. got: Int, expected: Str',
    { args => [], slurpy => $Str }, '', # 'valid',
    ],

    # nshift
    { args => [], nshift => 1 } => [
    { args => [] }, 'nshift is not equal. got: 0, expected: 1',
    { args => [], nshift => 0}, 'nshift is not equal. got: 0, expected: 1',
    { args => [], nshift => 1 }, '', # 'valid',
    ],
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

    subtest "@{[$json->encode($args)]}" => sub {
        while (my ($other_args, $expected) = splice @{$cases}, 0, 2) {
            my $is_hash = ref $other_args && ref $other_args eq 'HASH';
            my $other = $is_hash ? Sub::Meta::Parameters->new($other_args) : $other_args;

            if (ref $expected && ref $expected eq 'Regexp') {
                like $meta->interface_error_message($other), $expected;
            }
            else {
                is $meta->interface_error_message($other), $expected;
            }

        }
    };
}

done_testing;
