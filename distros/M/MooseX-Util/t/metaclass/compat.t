use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.016;

use Test::Requires 'Reindeer';

use aliased 'MooseX::TraitFor::Meta::Class::BetterAnonClassNames'
    => 'MetaTrait';
use aliased 'MooseX::Util::Meta::Class'
    => 'MetaClass';

# this is a rather sideways test; we're checking for metaclass compatibility
# between anon classes we create with our class metaclass subclass and
# packages already known to not be using an unadulterated Moose::Meta::Class
# metaclass.  This needs some work, but it's OK as a parakeet in the
# proverbial metaclass tunnel (for now).
#
# we do have a weird issue w.r.t. the metaclass instance for our last
# generated class claiming to not be anonymous, but I might be getting the
# metaness jumbled here.

{ package Zombie::Catcher;                              use Reindeer;    }
{ package Zombie::Catcher::Tools::Machete;              use Moose::Role; }
{ package Zombie::Catcher::Tools::TracyChapmansFastCar; use Reindeer::Role; }

my $catcher = MooseX::Util::Meta::Class->create_anon_class(
    superclasses => [ 'Zombie::Catcher' ],
    weaken => 0,
    roles => [ qw{
        Zombie::Catcher::Tools::Machete
    } ],
);

# created anon classname like: Zombie::Catcher::__ANON__::SERIAL::42
note $catcher->name;

validate_class $catcher->name => (
    anonymous => 1,
    isa       => [ 'Zombie::Catcher' ],
    does      => [ qw{
        Zombie::Catcher::Tools::Machete
    }],
);

like $catcher->name, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';

my $fast_catcher = MooseX::Util::Meta::Class->create_anon_class(
    superclasses => [ $catcher->name ],
    weaken => 0,
    roles => [ qw{
        Zombie::Catcher::Tools::TracyChapmansFastCar
    } ],
);

subtest q{validate $fast_catcher's metaclass} => sub {

    validate_class $fast_catcher => (
        anonymous => 1,
        # a trait we know Reindeer uses, and ours
        does => [
            'MooseX::StrictConstructor::Trait::Class',
            MetaTrait,
        ],
        attributes => [
            'is_anon',
        ],
        methods => [ 'is_anon' ],
    );

    is_anon $fast_catcher;
    is $fast_catcher->meta->is_anon, 1, 'is_anon is set correctly (true)';
};

subtest q{validate $fast_catcher} => sub {


    validate_class $fast_catcher->name => (
        # see TODO, below
        #anonymous => 1,
        isa  => [ $catcher->name ],
        does => [ qw{
            Zombie::Catcher::Tools::TracyChapmansFastCar
        }],
    );

    is $fast_catcher->is_anon, 1, 'is_anon is set correctly (true)';
    is
        $fast_catcher->anon_package_prefix,
        'Zombie::Catcher::__ANON__::SERIAL::',
        'anon_package_prefix correct',
        ;

    {
        local $TODO = 'known issue -- metaclass compat weirdness with is_anon fail';
        is_anon $fast_catcher->name;
    }

    like $fast_catcher->name, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';
};

done_testing;
