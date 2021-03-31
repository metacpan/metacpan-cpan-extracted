use Test2::V0;

{
package DummyType; ## no critic (RequireFilenameMatchesPackage)

use overload
    fallback => 1,
    '""' => sub { 'DummyType' }
    ;

sub new { my $class = shift; return bless {}, $class }
sub TO_JSON { my $self = shift; return ref $self }
}

use Sub::Meta::Returns;

my $obj = bless {} => 'Some';

my @TEST = (
    # scalar
    { scalar => 'Str', list => undef, void => undef } => {
    NG => [
    undef, 'invalid other',
    $obj, 'invalid obj',
    { scalar => 'Int', list => undef, void => undef }, 'invalid scalar',
    { scalar => 'Str', list => 'Str', void => undef }, 'invalid list',
    { scalar => 'Str', list => undef, void => 'Str' }, 'invalid void',
    ],
    OK => [
    { scalar => 'Str', list => undef, void => undef }, 'valid',
    ]},


    # list
    { scalar => undef, list => 'Str', void => undef } => {
    NG => [
    { scalar => undef, list => 'Int', void => undef }, 'invalid list',
    { scalar => 'Str', list => 'Str', void => undef }, 'invalid scalar',
    { scalar => undef, list => 'Str', void => 'Str' }, 'invalid void',
    ],
    OK => [
    { scalar => undef, list => 'Str', void => undef }, 'valid',
    ]},

    # void
    { scalar => undef, list => undef, void => 'Str' } => {
    NG => [
    { scalar => undef, list => undef, void => 'Int' }, 'invalid void',
    { scalar => 'Str', list => undef, void => 'Str' }, 'invalid scalar',
    { scalar => undef, list => 'Str', void => 'Str' }, 'invalid list',
    ],
    OK => [
    { scalar => undef, list => undef, void => 'Str' }, 'valid',
    ]},

    # array
    { scalar => [ 'Str', 'Str' ], list => undef, void => undef } => {
    NG => [
    { scalar => 'Str', list => undef, void => undef }, 'not array',
    { scalar => [ 'Str' ], list => undef, void => undef }, 'too few types',
    { scalar => [ 'Str', 'Str', 'Str' ], list => undef, void => undef }, 'too many types',
    { scalar => [ 'Str', 'Int' ], list => undef, void => undef }, 'invalid type',
    ],
    OK => [
    { scalar => [ 'Str', 'Str' ], list => undef, void => undef }, 'valid',
    ]},

    # ref but not array
    { scalar => DummyType->new, list => undef, void => undef } => {
    NG => [
    { scalar => "Foo", list => undef, void => undef }, 'invalid scalar',
    ],
    OK => [
    { scalar => DummyType->new, list => undef, void => undef }, 'valid',
    { scalar => "DummyType", list => undef, void => undef }, 'valid',
    ]},
);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Returns->new($args);
    my $inline = $meta->is_same_interface_inlined('$_[0]');
    my $is_same_interface = eval sprintf('sub { %s }', $inline); ## no critic (ProhibitStringyEval)

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $is_hash = ref $other_args && ref $other_args eq 'HASH';
                my $other = $is_hash ? Sub::Meta::Returns->new($other_args) : $other_args;
                ok !$meta->is_same_interface($other), $test_message;
                ok !$is_same_interface->($other), "inlined: $test_message";
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta::Returns->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
                ok $is_same_interface->($other), "inlined: $test_message";
            }
        };
    };
}

done_testing;
