use strict;
use warnings;

use Test::Tester;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::CleanNamespaces;

use lib 't/lib';

{
    my $return_value;
    my (undef, @results) = run_tests(sub { $return_value = namespaces_clean('Test::CleanNamespaces') });
    cmp_results(
        \@results,
        [ {
            ok => 1,
            name => 'Test::CleanNamespaces contains no imported functions',
        } ],
        'namespaces_clean success',
    );

    diag 'got result: ', explain(\@results) if not Test::Builder->new->is_passing;

    ok($return_value, 'returned true');
}

{
    my $return_value;
    my (undef, @results) = check_test(sub { $return_value = namespaces_clean('DoesNotCompile') }, {
        ok => 1,
        type => 'skip',
    }, 'namespace_clean compilation fail');

    like($results[0]{reason}, qr/failed to load/, 'useful diagnostics on compilation fail')
        or diag 'got result: ', explain(\@results);

    diag 'got result: ', explain(\@results) if not Test::Builder->new->is_passing;

    # meh, we could return true or false here...
    ok($return_value, 'returned true');
}

foreach my $package (qw(Dirty SubDirty))
{
    my $return_value;
    my (undef, @results) = run_tests(sub { $return_value = namespaces_clean($package) });
    cmp_results(
        \@results,
        [ {
            ok => 0,
            name => $package . ' contains no imported functions',
        } ],
        $package . ' has an unclean namespace - found all uncleaned imports',
    );

    like($results[0]{diag}, qr/remaining imports/, $package . ': diagnostic mentions "remaining imports"')
        or diag 'got result: ', explain(\@results);
    like($results[0]{diag}, qr/'stuff'\s+=>\s+'(Sub)?ExporterModule::stuff'/,
        $package . ': diagnostic lists the remaining imports')
        or diag 'got result: ', explain(\@results);

    diag 'got result: ', explain(\@results) if not Test::Builder->new->is_passing;

    ok(!$return_value, 'returned false');

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

foreach my $package (qw(Clean SubClean ExporterModule SubExporterModule))
{
    my $return_value;
    my (undef, @results) = run_tests(sub { $return_value = namespaces_clean($package) });
    cmp_results(
        \@results,
        [ {
            ok => 1,
            name => $package . ' contains no imported functions',
        } ],
        $package . ' has a clean namespace',
    );
    diag 'got result: ', explain(\@results) if not Test::Builder->new->is_passing;

    ok($return_value, 'returned true');

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

ok(!exists($INC{'Class/MOP.pm'}), 'Class::MOP has not been loaded');
ok(!exists($INC{'Moose.pm'}), 'Moose has not been loaded');
ok(!exists($INC{'Mouse.pm'}), 'Mouse has not been loaded');

done_testing;
