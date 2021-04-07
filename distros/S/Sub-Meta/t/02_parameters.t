use lib 't/lib';
use Test2::V0;

use Sub::Meta::Parameters;
use Sub::Meta::Param;
use MySubMeta::Param;

subtest 'exception' => sub {
    like dies { Sub::Meta::Parameters->new() },
        qr/parameters reqruires args/, 'requires args';

    like dies { Sub::Meta::Parameters->new(args => 'Str') },
        qr/args must be a reference/, 'args is not reference';
};

my @TEST = (
    { args => [] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [],
        all_args                 => [],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 0,
        args_max                 => 0,
    ],
    { args => [p(type => 'Foo')] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo')],
        all_args                 => [p(type => 'Foo')],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 1,
        args_max                 => 1,
    ],
    { args => [p(type => 'Foo')], nshift => 1 } => [
        nshift                   => 1,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo')],
        all_args                 => [p(invocant => 1), p(type => 'Foo')],
        _all_positional_required => [p(invocant => 1), p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(invocant => 1),
        invocants                => [p(invocant => 1)],
        has_invocant             => !!1,
        args_min                 => 2,
        args_max                 => 2,
    ],
    { args => [p(type => 'Foo')], invocant => p(name => '$self') } => [
        nshift                   => 1,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo')],
        all_args                 => [p(name => '$self', invocant => 1), p(type => 'Foo')],
        _all_positional_required => [p(name => '$self', invocant => 1), p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(name => '$self', invocant => 1),
        invocants                => [p(name => '$self', invocant => 1)],
        has_invocant             => !!1,
        args_min                 => 2,
        args_max                 => 2,
    ],
    { args => [p(type => 'Foo')], nshift => 1, slurpy => 'Str' } => [
        nshift                   => 1,
        slurpy                   => p(type => 'Str'),
        has_slurpy               => !!1,
        args                     => [p(type => 'Foo')],
        all_args                 => [p(invocant => 1), p(type => 'Foo')],
        _all_positional_required => [p(invocant => 1), p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(invocant => 1),
        invocants                => [p(invocant => 1)],
        has_invocant             => !!1,
        args_min                 => 2,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
    ],
    { args => [p(type => 'Foo', named => 1)] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo', named => 1)],
        all_args                 => [p(type => 'Foo', named => 1)], 
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1)],
        named_required           => [p(type => 'Foo', named => 1)],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 2,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
    ],
    { args => [p(type => 'Foo', optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo', optional => 1)],
        all_args                 => [p(type => 'Foo', optional => 1)],
        _all_positional_required => [],
        positional               => [p(type => 'Foo', optional => 1)],
        positional_required      => [],
        positional_optional      => [p(type => 'Foo', optional => 1)],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 0,
        args_max                 => 1,
    ],
    { args => [p(type => 'Foo', named => 1, optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo', named => 1, optional => 1)],
        all_args                 => [p(type => 'Foo', named => 1, optional => 1)],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Foo', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 0,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
    ],
    { args => [p(type => 'Foo', named => 1, optional => 1)], slurpy => 'Str' } => [
        nshift                   => 0,
        slurpy                   => p(type => 'Str'),
        has_slurpy               => !!1,
        args                     => [p(type => 'Foo', named => 1, optional => 1)],
        all_args                 => [p(type => 'Foo', named => 1, optional => 1)],
        _all_positional_required => [],
        positional               => [],
        positional_required      => [],
        positional_optional      => [],
        named                    => [p(type => 'Foo', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Foo', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 0,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar')] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar')],
        all_args                 => [p(type => 'Foo'), p(type => 'Bar')],
        _all_positional_required => [p(type => 'Foo'), p(type => 'Bar')],
        positional               => [p(type => 'Foo'), p(type => 'Bar')],
        positional_required      => [p(type => 'Foo'), p(type => 'Bar')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 2,
        args_max                 => 2,
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar')], nshift => 1 } => [
        nshift                   => 1,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar')],
        all_args                 => [p(invocant => 1), p(type => 'Foo'), p(type => 'Bar')],
        _all_positional_required => [p(invocant => 1), p(type => 'Foo'), p(type => 'Bar')],
        positional               => [p(type => 'Foo'), p(type => 'Bar')],
        positional_required      => [p(type => 'Foo'), p(type => 'Bar')],
        positional_optional      => [],
        named                    => [],
        named_required           => [],
        named_optional           => [],
        invocant                 => p(invocant => 1),
        invocants                => [p(invocant => 1)],
        has_invocant             => !!1,
        args_min                 => 3,
        args_max                 => 3,
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar', named => 1)] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar', named => 1)],
        all_args                 => [p(type => 'Foo'), p(type => 'Bar', named => 1)],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [p(type => 'Bar', named => 1)],
        named_required           => [p(type => 'Bar', named => 1)],
        named_optional           => [],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 3,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
    ],
    { args => [p(type => 'Foo'), p(type => 'Bar', named => 1, optional => 1)] } => [
        nshift                   => 0,
        slurpy                   => undef,
        has_slurpy               => !!0,
        args                     => [p(type => 'Foo'), p(type => 'Bar', named => 1,optional => 1)],
        all_args                 => [p(type => 'Foo'), p(type => 'Bar', named => 1,optional => 1)],
        _all_positional_required => [p(type => 'Foo')],
        positional               => [p(type => 'Foo')],
        positional_required      => [p(type => 'Foo')],
        positional_optional      => [],
        named                    => [p(type => 'Bar', named => 1, optional => 1)],
        named_required           => [],
        named_optional           => [p(type => 'Bar', named => 1, optional => 1)],
        invocant                 => undef,
        invocants                => [],
        has_invocant             => !!0,
        args_min                 => 1,
        args_max                 => 0 + 'Inf', ## no critic (ProhibitMismatchedOperators)
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

sub p { my @args = @_; return Sub::Meta::Param->new(@args); }

while (my ($parameters, $expect) = splice @TEST, 0, 2) {
    my $meta = Sub::Meta::Parameters->new($parameters);
    subtest "parameters: @{[$json->encode($parameters)]}" => sub {
        while (my ($key, $exp) = splice @$expect, 0, 2) {
            is $meta->$key, $exp, "$key is @{[$json->encode($exp)]}";
        }
    };
}

subtest 'setter' => sub {
    my $some = bless {}, 'Some';
    my $parameters = Sub::Meta::Parameters->new(args => [p()]);

    is $parameters->nshift, 0, 'nshift';
    is $parameters->set_nshift(1), $parameters, 'set_nshift';
    is $parameters->nshift, 1, 'nshift';

    ok !$parameters->slurpy, 'slurpy';
    is $parameters->set_slurpy('Str'), $parameters, 'set_slurpy';
    is $parameters->slurpy, p(type => 'Str'), 'slurpy';
    is $parameters->set_slurpy(p(type => 'Int')), $parameters, 'set_slurpy';
    is $parameters->slurpy, p(type => 'Int'), 'slurpy';
    is $parameters->set_slurpy($some), $parameters, 'set_slurpy';
    is $parameters->slurpy, p(type => $some), 'slurpy';

    is $parameters->args, [p()], 'args';
    is $parameters->set_args([p(type => 'Foo')]), $parameters, 'set_args';
    is $parameters->args, [p(type => 'Foo')], 'args';
    is $parameters->set_args(p(type => 'Foo')), $parameters, 'set_args';
    is $parameters->args, [p(type => 'Foo')], 'args';
};

subtest '_normalize_args' => sub {
    my $some = bless {}, 'Some';

## no critic (ProtectPrivateSubs)
    is(Sub::Meta::Parameters->_normalize_args([$some]), [p($some)], 'blessed arg list');
    is(Sub::Meta::Parameters->_normalize_args(['Foo', 'Bar']), [p('Foo'), p('Bar')], 'arrayref');

    is(Sub::Meta::Parameters->_normalize_args($some), [p($some)], 'single arg');

    like dies { Sub::Meta::Parameters->_normalize_args('Foo', 'Bar') },
        qr/args must be a reference/, 'cannot use array';

    is(Sub::Meta::Parameters->_normalize_args(
        { a => 'Foo', b => 'Bar'}),
        [p(type => 'Foo', name => 'a', named => 1), p(type => 'Bar', name => 'b', named => 1)], 'hashref');

    is(Sub::Meta::Parameters->_normalize_args(
        { a => { isa => 'Foo' }, b => { isa => 'Bar' } }),
        [p(type => 'Foo', name => 'a', named => 1), p(type => 'Bar', name => 'b', named => 1)], 'hashref');

    my $foo = sub { 'Foo' };
    is(Sub::Meta::Parameters->_normalize_args(
        { a => $foo }),
        [p(type => $foo, name => 'a', named => 1)], 'hashref');
## use critic
};

subtest 'invocant' => sub {
    my $parameters = Sub::Meta::Parameters->new(args => [p('Foo'), p('Bar')]);
    is $parameters->invocant, undef, 'no invocant';
    is $parameters->set_nshift(1), $parameters, 'if set nshift';
    is $parameters->invocant, p(invocant => 1), 'then set default invocant';

    like dies { $parameters->set_nshift(2) }, qr/^Can't set this nshift: /, $parameters;
    like dies { $parameters->set_nshift(undef) }, qr/^Can't set this nshift: /, $parameters;

    is $parameters->set_nshift(0), $parameters, 'if set nshift:0';
    is $parameters->invocant, undef, 'then remove invocant';

    is $parameters->set_invocant(p(name => '$self')), $parameters, 'if set original invocant';
    is $parameters->invocant, p(name => '$self', invocant => 1), 'then original with invocant flag';

    is $parameters->set_invocant({ name => '$class'}), $parameters, 'set_invocant can take hashref';
    is $parameters->invocant, p(name => '$class', invocant => 1);

    my $some = bless {}, 'Some';
    is $parameters->set_invocant($some), $parameters, 'set_invocant can take type';
    is $parameters->invocant, p(type=> $some, invocant => 1);

    my $myparam = MySubMeta::Param->new(name => '$self');
    is $parameters->set_invocant($myparam), $parameters, 'set_invocant can take your Sub::Meta::Param';
    is $parameters->invocant, $myparam->set_invocant(1);
};

done_testing;
