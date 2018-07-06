#!perl

use 5.006;
use strict;
use warnings;

use Config::Tiny;

use Test::Fatal;
use Test::More 0.88;

use Perl::Critic::MergeProfile;

main();

sub main {

    my $class = 'Perl::Critic::MergeProfile';

    #
    note('initialize obj with first read');

    my $obj = $class->new();
    ok( !exists $obj->{_config}, '_config does not exist for a new obj' );

    my $config   = Config::Tiny->read('corpus/file1.ini');
    my $expected = Config::Tiny->read('corpus/file1.ini');

    is( $obj->_merge($config), undef, '_merge returns undef' );
    is_deeply( $obj->{_config}, $expected, q{... and stores it's argument in the _config attribute} );

    #
    note('merge with an empty config file');

    my $config2 = Config::Tiny->read_string(q{});
    is( $obj->_merge($config2), undef, '_merge returns undef' );
    is_deeply( $obj->{_config}, $expected, '... no changes from empty ini file' );

    #
    note('merge with a single, additional  policy');

    $config2 = Config::Tiny->read_string('[Policy2]');
    is( $obj->_merge($config2), undef, '_merge returns undef' );

    $expected->{Policy2} = {};
    is_deeply( $obj->{_config}, $expected, '... new policy is added' );

    #
    note('merge with 2 policies, one was disabled before');

    $config2 = Config::Tiny->read_string("[Policy3]\n[Policy4]");
    is( $obj->_merge($config2), undef, '_merge returns undef' );

    $expected->{Policy3} = {};
    delete $expected->{'-Policy3'};
    $expected->{Policy4} = {};
    is_deeply( $obj->{_config}, $expected, '... new policies are added, deactivated policy is activated' );

    #
    note('merge with a single disabled policy');

    $config2 = Config::Tiny->read_string('[-Policy1]');
    is( $obj->_merge($config2), undef, '_merge returns undef' );

    delete $expected->{'Policy1'};
    $expected->{'-Policy1'} = {};
    is_deeply( $obj->{_config}, $expected, '... policy got disabled' );

    #
    note('changed global settings');

    $config2 = Config::Tiny->read_string("global_key_2=global_value_2b\nglobal_key_3=global_value_3");
    is( $obj->_merge($config2), undef, '_merge returns undef' );

    $expected->{'_'}->{'global_key_2'} = 'global_value_2b';
    $expected->{'_'}->{'global_key_3'} = 'global_value_3';
    is_deeply( $obj->{_config}, $expected, '... policy got disabled' );

    # ----------------------------------------------------------
    note('add global settings');

    $obj = $class->new();
    ok( !exists $obj->{_config}, '_config does not exist for a new obj' );

    $config   = Config::Tiny->read_string("[Policy1]\n[Policy2]");
    $expected = Config::Tiny->read_string("[Policy1]\n[Policy2]");

    is( $obj->_merge($config), undef, '_merge returns undef' );
    is_deeply( $obj->{_config}, $expected, q{... and stores it's argument in the _config attribute} );

    $config2 = Config::Tiny->read_string("global_key_2=global_value_2b\nglobal_key_3=global_value_3");
    is( $obj->_merge($config2), undef, '_merge returns undef' );

    $expected->{'_'}->{'global_key_2'} = 'global_value_2b';
    $expected->{'_'}->{'global_key_3'} = 'global_value_3';
    is_deeply( $obj->{_config}, $expected, '... policy got disabled' );

    #
    note('policy enabled and disabled');
    $config2 = Config::Tiny->read_string("[Policy5]\n[-Policy5]");
    like( exception { $obj->_merge($config2) }, qr{Policy5 is enabled and disabled in the same profile}, '_merge throws an error if the same policy is enabled and disabled' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
