use Test2::V0;

use Sub::Meta::Parameters;
use Sub::Meta::Param;

subtest 'exception' => sub {
    like dies { Sub::Meta::Parameters->new() },
        qr/parameters reqruires args/, 'requires args';

    like dies { Sub::Meta::Parameters->new(args => p(type => 'Foo', named => 1, optional => 1), nshift => 1) },
        qr/required positional parameters need more than nshift/, 'nshift';
};

my @TEST = (
    { args => [] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 0,
        args_max                 => 0,
    ],
    { args => [p(type => 'Foo')] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo')],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 1,
        args_max                 => 1,
    ],
    { args => [p(type => 'Foo')], nshift => 1 } => [
        nshift                   => 1,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo')],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(type => 'Foo'),
        invocants                => [p(type => 'Foo')],
        args_min                 => 1,
        args_max                 => 1,
    ],
    { args => [p(type => 'Foo')], nshift => 1, slurpy => 1 } => [
        nshift                   => 1,
        slurpy                   => !!1,
        args                     => [p(type => 'Foo')],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(type => 'Foo'),
        invocants                => [p(type => 'Foo')],
        args_min                 => 1,
        args_max                 => 0 + 'Inf',
    ],
    { args => [p(type => 'Foo', named => 1)] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo', named => 1)],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1)],
        named_required           => [p(type => 'Foo', named => 1)],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 2,
        args_max                 => 0 + 'Inf',
    ],
    { args => [p(type => 'Foo', optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo', optional => 1)],
        _all_positional_required => [],
        positional               => [p(type => 'Foo', optional => 1)],
        positional_required      => [],
        positional_optional      => [p(type => 'Foo', optional => 1)],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 0,
        args_max                 => 1,
    ],
    { args => [p(type => 'Foo', named => 1, optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo', named => 1, optional => 1)],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Foo', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 0,
        args_max                 => 0 + 'Inf',
    ],
    { args => [p(type => 'Foo', named => 1, optional => 1)], slurpy => 1 } => [
        nshift                   => 0,
        slurpy                   => !!1,
        args                     => [p(type => 'Foo', named => 1, optional => 1)],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Foo', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 0,
        args_max                 => 0 + 'Inf',
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar')] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar')],
        _all_positional_required => [p(type => 'Foo'), p(type => 'Bar')],
        positional               => [p(type => 'Foo'), p(type => 'Bar')],
        positional_required      => [p(type => 'Foo'), p(type => 'Bar')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 2,
        args_max                 => 2,
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar')], nshift => 1 } => [
        nshift                   => 1,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar')],
        _all_positional_required => [p(type => 'Foo'), p(type => 'Bar')],
        positional               => [p(type => 'Bar')],
        positional_required      => [p(type => 'Bar')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(type => 'Foo'),
        invocants                => [p(type => 'Foo')],
        args_min                 => 2,
        args_max                 => 2,
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar', named => 1)] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar', named => 1)],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [p(type => 'Bar', named => 1)],
        named_required           => [p(type => 'Bar', named => 1)],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 3,
        args_max                 => 0+'Inf',
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar', named => 1, optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar', named => 1,optional => 1)],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [p(type => 'Bar', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Bar', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        args_min                 => 1,
        args_max                 => 0+'Inf',
    ],
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

sub p { Sub::Meta::Param->new(@_); }

while (my ($parameters, $expect) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Parameters->new($parameters);
    subtest "parameters: @{[$json->encode($parameters)]}" => sub {
        while (my ($key, $exp) = splice @$expect, 0, 2) {
            is $meta->$key, $exp, "$key is @{[$json->encode($exp)]}";
        }
    };
}

subtest 'setter' => sub {
    my $parameters = Sub::Meta::Parameters->new(args => [p()]);

    is $parameters->nshift, 0, 'nshift';
    is $parameters->set_nshift(1), $parameters, 'set_nshift';
    is $parameters->nshift, 1, 'nshift';

    ok !$parameters->slurpy, 'slurpy';
    is $parameters->set_slurpy, $parameters, 'set_slurpy';
    ok $parameters->slurpy, 'slurpy';
    is $parameters->set_slurpy(0), $parameters, 'set_slurpy';
    ok !$parameters->slurpy, 'slurpy';

    is $parameters->args, [p()], 'args';
    is $parameters->set_args([p(type => 'Foo')]), $parameters, 'set_args';
    is $parameters->args, [p(type => 'Foo')], 'args';
};

subtest '_normalize_args' => sub {
    my $blessed_args = [bless {}, 'Some'];
    is(Sub::Meta::Parameters->_normalize_args($blessed_args), $blessed_args, 'blessed_args');
    is(Sub::Meta::Parameters->_normalize_args(['Foo', 'Bar']), [p('Foo'), p('Bar')], 'arrayref');
    is(Sub::Meta::Parameters->_normalize_args('Foo', 'Bar'), [p('Foo'), p('Bar')], 'array');
};

subtest 'invocant' => sub {
    my $parameters = Sub::Meta::Parameters->new(args => [p('Foo'), p('Bar')]);
    is $parameters->invocant, undef;
    is $parameters->set_nshift(1), $parameters;
    is $parameters->invocant, p('Foo');
    is $parameters->set_nshift(2), $parameters;
    dies { $parameters->invocant }, qr/Can't return a single invocant; this function has $parameters->nshift/;
};

done_testing;
