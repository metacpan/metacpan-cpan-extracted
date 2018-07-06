#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;

use Perl::Critic::MergeProfile;

main();

sub main {

    my $class = 'Perl::Critic::MergeProfile';

    note('read string');
    {
        my $obj = $class->new();

        my $merge = 0;
        my @merge_args;
        my $module = Test::MockModule->new($class);
        $module->mock( '_merge', sub { @merge_args = @_; $merge++; return; } );

        is( $obj->read_string("global_1=global_val1\n[Policy1]\npolicy_1=policy_val1"), $obj, 'read_string returns $self' );
        is( $merge,                                                                     1,    '_merge was called once' );
        is( scalar @merge_args,                                                         2,    '... with two arguments' );
        is( $merge_args[0],                                                             $obj, '... $self' );
        isa_ok( $merge_args[1], 'Config::Tiny', '... a Config::Tiny object' );
    }

    note('invalid string');
    {
        my $obj = $class->new();

        my $merge  = 0;
        my $module = Test::MockModule->new($class);
        $module->mock( '_merge', sub { $merge++; return; } );

        like( exception { $obj->read_string('x') }, qr{.*}, 'read_string throws an error' );
        is( $merge, 0, '_merge was not called' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
