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

use Sub::Meta::Param;

my $obj = bless {} => 'Some';

my @TEST = (
    # full args
    { name => '$msg', type => 'Str', required => 1, positional => 1 } => {
    NG => [
    undef, 'invalid other',
    $obj, 'invalid obj',
    { name => '$mgs', type => 'Str', required => 1, positional => 1 }, 'invalid name',
    { name =>  undef, type => 'Str', required => 1, positional => 1 }, 'undef name',
    { name => '$msg', type => 'Srt', required => 1, positional => 1 }, 'invalid type',
    { name => '$msg', type => 'Str', required => 0, positional => 1 }, 'invalid required',
    { name => '$msg', type => 'Str', required => 1, positional => 0 }, 'invalid positional',
    ],
    OK => [
    { name => '$msg', type => 'Str', required => 1, positional => 1 }, 'valid',
    ]},

    # no name
    { type => 'Str', required => 1, positional => 1 } => {
    NG => [
    { type => 'Srt', required => 1, positional => 1 }, 'invalid type',
    { type => 'Str', required => 0, positional => 1 }, 'invalid required',
    { type => 'Str', required => 1, positional => 0 }, 'invalid positional',
    { type => 'Str', required => 1, positional => 1, name => '$foo' }, 'not need name',
    ],
    OK => [
    { type => 'Str', required => 1, positional => 1 }, 'valid',
    ]},

    # no type
    { name => '$foo', required => 1, positional => 1 } => {
    NG => [
    { name => '$boo', required => 1, positional => 1 }, 'invalid name',
    { name => '$foo', required => 0, positional => 1 }, 'invalid required',
    { name => '$foo', required => 1, positional => 0 }, 'invalid positional',
    { name => '$foo', required => 1, positional => 1, type => 'Str' }, 'not need type',
    ],
    OK => [
    { name => '$foo', required => 1, positional => 1 }, 'valid',
    ]},

    # no name and type
    { required => 1, positional => 1 } => {
    NG => [
    { required => 0, positional => 1 }, 'invalid required',
    { required => 1, positional => 0 }, 'invalid positional',
    { required => 1, positional => 1, name => '$foo' }, 'not need name',
    { required => 1, positional => 1, type => 'Str' }, 'not need type',
    ],
    OK => [
    { required => 1, positional => 1 }, 'valid',
    ]},

    # undef optional 
    { optional => undef } => {
    NG => [
    { optional => 1 }, 'invalid optional',
    ],
    OK => [
    { optional => undef }, 'valid',
    { optional => 0 }, 'valid',
    { required => !!1 }, 'valid',
    ]},

    # undef named
    { named => undef } => {
    NG => [
    { named => 1 }, 'invalid named',
    ],
    OK => [
    { named => undef }, 'valid',
    { named => 0 }, 'valid',
    { positional => !!1 }, 'valid',
    ]},

    # blessed type
    { type => DummyType->new } => {
    NG => [
    {  }, 'invalid type',
    { type => undef }, 'invalid type',
    { type => $obj }, 'invalid type',
    { type => 'some' }, 'invalid type',
    ],
    OK => [
    { type => 'DummyType' }, 'valid type',
    { type => DummyType->new }, 'valid type',
    ]},
);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Param->new($args);
    my $inline = $meta->is_same_interface_inlined('$_[0]');
    my $is_same_interface = eval sprintf('sub { %s }', $inline); ## no critic (ProhibitStringyEval)

    subtest "@{[$json->encode($args)]}" => sub {

        subtest 'NG cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{NG}}, 0, 2) {
                my $is_hash = ref $other_args && ref $other_args eq 'HASH';
                my $other = $is_hash ? Sub::Meta::Param->new($other_args) : $other_args;
                ok !$meta->is_same_interface($other), $test_message;
                ok !$is_same_interface->($other), "inlined: $test_message";
            }
        };

        subtest 'OK cases' => sub {
            while (my ($other_args, $test_message) = splice @{$cases->{OK}}, 0, 2) {
                my $other = Sub::Meta::Param->new($other_args);
                ok $meta->is_same_interface($other), $test_message;
                ok $is_same_interface->($other), "inlined: $test_message";
            }
        };
    };
}

done_testing;
