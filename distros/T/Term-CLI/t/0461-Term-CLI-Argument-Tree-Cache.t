#
#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
# Copyright (c) 2022, Diab Jerius, Smithsonian Astrophysical Observatory
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

use Test::More;

my $TEST_NAME = 'ARGUMENT';

sub Main() {
    if ( ( $::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"} )
        && !$::ENV{"TEST_$TEST_NAME"} )
    {
        plan skip_all => 'skipped because of environment';
    }
    Term_CLI_Argument_Tree_Cache_test->runtests();
    exit 0;
}

package Term_CLI_Argument_Tree_Cache_test {

    use parent 0.225 qw( Test::Class );

    use Test::More 1.001002;
    use Term::CLI::Argument::Tree;

    my $ARG_NAME = 'test_tree';

    our $called = 0;

    sub values {
        return { called => $called++ };
    }

    sub create {
        $called = 0;
        return Term::CLI::Argument::Tree->new(
            name   => $ARG_NAME,
            values => \&values,
            @_
        );
    }

    sub start_off : Test(4) {
        my $tree = create( cache_values => 0 );
        my $values;

        $values = $tree->values;
        is( $values->{called}, 0, 'initial' );

        $values = $tree->values;
        is( $values->{called}, 1, 'second' );

        $tree->cache_values(1);

        $values = $tree->values;
        is( $values->{called}, 2, 'first after cache on' );

        $values = $tree->values;
        is( $values->{called}, 2, 'second after cache on' );

        return;
    }

    sub start_on : Test(4) {
        my $tree = create( cache_values => 1 );
        my $values;

        $values = $tree->values;
        is( $values->{called}, 0, 'initial' );

        $values = $tree->values;
        is( $values->{called}, 0, 'second' );

        $tree->cache_values(0);

        $values = $tree->values;
        is( $values->{called}, 1, 'first after cache off' );

        $values = $tree->values;
        is( $values->{called}, 2, 'second after cache off' );

        return;
    }

}

Main();
