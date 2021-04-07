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
    { subname => 'foo' } => [
    undef, 'must be Sub::Meta. got: ',
    $obj, qr/^must be Sub::Meta\. got: Some/,
    { subname => 'bar' }, 'invalid subname. got: bar, expected: foo',
    { subname => undef }, 'invalid subname. got: , expected: foo',
    { subname => 'foo', is_method => 1 }, 'should not be method',
    { subname => 'foo', parameters => $p1 }, 'should not have parameters',
    { subname => 'foo', returns => $r1 }, 'should not have returns',
    { subname => 'foo' }, '', # valid
    { fullname => 'path::foo' }, '', # valid
    ],

    # no args
    { } => [
    { subname => 'foo' }, 'should not have subname. got: foo',
    { }, '', # valid
    ],

    # method
    { is_method => 1 } => [
    { is_method => 0 }, 'must be method',
    { is_method => 1 }, '', # valid
    ],

    # p1
    { parameters => $p1 } => [
    { parameters => $p2 }, 'invalid parameters',
    {  }, 'invalid parameters',
    { parameters => $p1 }, '', #valid
    ],

    # r1
    { returns => $r1 } => [
    { returns => $r2 }, 'invalid returns',
    {  }, 'invalid returns',
    { returns => $r1 }, '', #valid
    ],
);

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;
{
    no warnings qw/once/; ## no critic (ProhibitNoWarnings)
    *{Sub::Meta::Parameters::TO_JSON} = sub {
        join ",", map { $_->type } @{$_[0]->args};
    };

    *{Sub::Meta::Returns::TO_JSON} = sub {
        $_[0]->scalar;
    };
}

{
    no warnings qw(redefine); ## no critic (ProhibitNoWarnings)
    *Sub::Meta::Parameters::interface_error_message = sub {
        my ($self, $other) = @_;
        return $self->is_same_interface($other) ? '' : 'invalid parameters';
    };

    *Sub::Meta::Returns::interface_error_message = sub {
        my ($self, $other) = @_;
        return $self->is_same_interface($other) ? '' : 'invalid returns';
    };
}

while (my ($args, $cases) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta->new($args);

    subtest "@{[$json->encode($args)]}" => sub {
        while (my ($other_args, $expected) = splice @{$cases}, 0, 2) {
            my $is_hash = ref $other_args && ref $other_args eq 'HASH';
            my $other = $is_hash ? Sub::Meta->new($other_args) : $other_args;

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
