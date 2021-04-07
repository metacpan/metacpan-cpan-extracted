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
    { scalar => 'Str' } => [
    undef, 'must be Sub::Meta::Returns. got: ',
    $obj, qr/^must be Sub::Meta::Returns\. got: Some/,
    { scalar => 'Int' }, 'invalid scalar return. got: Int, expected: Str',
    { scalar => 'Str', list => 'Str' }, 'should not have list return',
    { scalar => 'Str', void => 'Str' }, 'should not have void return',
    { scalar => 'Str' }, '', # valid
    { scalar => 'Str', list => undef, void => undef }, '', # valid
    ],

    # list
    { list => 'Str' } => [
    { list => 'Int' }, 'invalid list return. got: Int, expected: Str',
    { list => 'Str', scalar => 'Str' }, 'should not have scalar return',
    { list => 'Str', void => 'Str' }, 'should not have void return',
    { list => 'Str' }, '', # valid
    { list => 'Str', scalar => undef, void => undef }, '', # valid
    ],

    # void
    { void => 'Str' } => [
    { void => 'Int' }, 'invalid void return. got: Int, expected: Str',
    { void => 'Str', scalar => 'Str' }, 'should not have scalar return',
    { void => 'Str', list => 'Str' }, 'should not have list return',
    { void => 'Str' }, '', # valid
    { void => 'Str', scalar => undef, list => undef }, '', # valid
    ],

);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Returns->new($args);

    subtest "@{[$json->encode($args)]}" => sub {
        while (my ($other_args, $expected) = splice @{$cases}, 0, 2) {
            my $is_hash = ref $other_args && ref $other_args eq 'HASH';
            my $other = $is_hash ? Sub::Meta::Returns->new($other_args) : $other_args;

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
