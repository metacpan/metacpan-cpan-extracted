use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::Needs 'Mouse';
use Test::Deep;
use Module::Runtime 'require_module';
use Test::CleanNamespaces;

plan skip_all => 'at least Mouse 0.37_01 required, for class_of()'
    if not Mouse::Util->can('class_of');

use lib 't/lib';

foreach my $package (qw(MouseyDirty))
{
    require_module($package);

    local $TODO = 'Mouse::Meta::Module::get_method_list does not track method origin';
    my $imports;
    warnings { $imports = Test::CleanNamespaces::_remaining_imports($package) };
    cmp_deeply(
        $imports,
        superhashof({
            map { $_ => ignore } @{ $package->DIRTY },
        }),
        $package . ' has an unclean namespace - found all uncleaned imports',
    );

    undef $TODO;

    # run the test again without TODO, except we overlook the failure to
    # detect the File::Spec::Functions::catdir import
    cmp_deeply(
        $imports,
        superhashof({
            map { $_ => ignore } grep { $_ ne 'catdir' } @{ $package->DIRTY },
        }),
        $package . ' has an unclean namespace - found the Mouse-specific uncleaned imports',
    );

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

foreach my $package (qw(MouseyClean MouseyRole MouseyComposer))
{
    require_module($package);
    my $imports;
    warnings { $imports = Test::CleanNamespaces::_remaining_imports($package) };
    cmp_deeply(
        $imports,
        {},
        $package . ' has a clean namespace',
    );

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

ok(!exists($INC{'Class/MOP.pm'}), 'Class::MOP has not been loaded');
ok(!exists($INC{'Moose.pm'}), 'Moose has not been loaded');

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
