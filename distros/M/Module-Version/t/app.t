#!perl

use strict;
use warnings;

use Test::More;

eval 'use File::Temp qw(tempfile)';
$@ and plan skip_all => 'File::Temp is required to run these tests';

eval 'use Test::Output';
$@ and plan skip_all => 'Test::Output is required to run these tests';

use lib 't/lib';

## TESTS ##
plan tests => 16;

use_ok('Module::Version::App');
my $app = Module::Version::App->new;
isa_ok( $app, 'Module::Version::App' );

{
    # check help()
    my $sub = sub { $app->help() };
    stdout_like( $sub, qr/\[ OPTIONS \] Module Module Module/, 'help() ok' );
}

{
    # checking process()
    my @modules = qw( Test::More File::Temp Module::Version );
    $app->process(@modules);
    is_deeply(
        $app->{'modules'},
        \@modules,
        'process() ok',
    );
}

my $run = sub { $app->run() };

{
    # check run() without input
    $app->{'modules'} = ['Test::More'];
    my $ver = $Test::More::VERSION;
    $ver = '1.3021350';
    $ver =~ s/0+$//;
    stdout_is( $run, "$ver\n", 'run() ok - regular' );
}

{
    # check run() without modules or input
    delete $app->{'modules'};
    eval { $run->() };
    is( $@, "Error: no modules to check\n", 'run() ok - no modules or input' );
}

{
    # check run() with input
    my ( $fh, $filename ) = tempfile();
    print {$fh} "Module::Version\n";
    close $fh or die "Can't close $fh: $!\n";

    $app->{'input'} = $filename;
    stdout_is( $run, "$Module::Version::VERSION\n", 'run() ok - with input' );
}

{
    # check run() with invalid input
    $app->{'input'} = 'zzzz765';
    eval { $run->() };
    like(
        $@,
        qr/^Cannot open 'zzzz765'/,
        'run() ok - with invalid input',
    );

    delete $app->{'input'};
}

{
    # check run() with no version from get_version
    $app->{'modules'} = ['NoExistenziano'];

    # without quiet
    stderr_like(
        $run,
        qr/^Warning\: module 'NoExistenziano' does not seem to be installed/,
        'run() ok - while crippling get_version, no quiet',
    );

    # with quiet
    $app->{'quiet'} = 1;
    stderr_is(
        $run,
        '',
        'run() ok - while crippling get_version, with quiet',
    );

    $app->{'quiet'} = 0;
}

{
    # check run() with full
    $app->{'modules'} = ['Module::Version'];
    $app->{'full'}    = 1;
    stdout_is(
        $run,
        "Module::Version $Module::Version::VERSION\n",
        'run() ok - full output',
    );

    $app->{'full'} = 0;
}

{
    # check run() with a developer version
    $app->{'modules'} = ['ModuleVersionTester'];
    stdout_is( $run, "0.0101\n", 'Handling developer version' );
}

{
    # check run() with a developer version with --dev (show AS developer ver)
    $app->{'dev'} = 1;
    stdout_is( $run, "0.01_01\n", 'Handling developer version with --dev' );
    $app->{'dev'} = 0;
}

{
    # check run() before includes
    $app->{'modules'} = ['ModuleVersionTesterInclude'];
    $app->{'quiet'  } = 1;

    stdout_is( $run, '', 'No include warrants no result' );

    $app->{'quiet'} = 0;
}

{
    # check run() with wrong type of includes
    $app->{'include'} = 'blah';

    eval { $run->() };
    is( $@, "Error: include must be an ARRAY ref\n", 'run() ok - bad include' );
}

{
    # check run() with includes
    $app->{'include'} = ['t/lib/include'];
    stdout_is( $run, "1.21\n", 'No include warrants no result' );
}

