#! perl

# Change command base

use MooX::Cmd::Tester;
use Test::More;

use lib 't/lib';

for my $class ( qw[ Default Base ] ) {

    eval "use $class; 1" or die( "error loading $class: $@\n" );

    subtest "$class: app" => sub {

        {
            my $rv = test_cmd( $class => [] );

            is( $rv->execute_rv->[0]->app_opt, 'app_opt_v', 'default value' );
        }

        {
            my $rv = test_cmd( $class => [qw( --app-opt app )] );

            is( $rv->execute_rv->[0]->app_opt, 'app', 'set value' );
        }
    };

    subtest "$class: first" => sub {

        {
            my $rv = test_cmd( $class => [qw( first )] );

            is( $rv->execute_rv->[0]->first_opt,
                'first_opt_v', 'first: default value' );
            is( $rv->execute_rv->[0]->app_opt,
                'app_opt_v', 'app: default value' );
        }

        {
            my $rv
              = test_cmd(
                $class => [qw( --app-opt app first --first-opt first )] );

            is( $rv->execute_rv->[0]->first_opt, 'first', 'first: set value' );
            is( $rv->execute_rv->[0]->app_opt,   'app',   'app: set value' );
        }
    };

    subtest "$class: second" => sub {

        {
            my $rv = test_cmd( $class => [qw( first second )] );

            is( $rv->execute_rv->[0]->second_opt,
                'second_opt_v', 'second: default value' );
            is( $rv->execute_rv->[0]->first_opt,
                'first_opt_v', 'first: default value' );
            is( $rv->execute_rv->[0]->app_opt,
                'app_opt_v', 'app: default value' );
        }

        {
            my $rv = test_cmd(
                $class => [
                    qw( --app-opt app first --first-opt first second --second-opt second)
                ] );

            is( $rv->execute_rv->[0]->second_opt,
                'second', 'second: default value' );
            is( $rv->execute_rv->[0]->first_opt, 'first', 'first: set value' );
            is( $rv->execute_rv->[0]->app_opt,   'app',   'app: set value' );
        }
    };

}

done_testing;
