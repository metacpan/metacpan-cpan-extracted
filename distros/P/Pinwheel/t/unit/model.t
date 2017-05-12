#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 63;

use Pinwheel::Model;


# Utility functions
{
    is(Pinwheel::Model::make_package_name('tests'), 'Models::Test',
            'can make a package name from "tests"');
    is(Pinwheel::Model::make_package_name('some_names'), 'Models::SomeName',
            'can make a package name from "some_names"');

    is(Pinwheel::Model::_make_singular('tests'), 'test', 'can make "tests" singular');
    is(Pinwheel::Model::_make_singular('series'), 'series', 'can make "series" singular');
    is(Pinwheel::Model::_make_singular('categories'), 'category');
}


# Type wrappers
{
    my $fn = \&Pinwheel::Model::_get_type_wrapper;

    # Different type codes
    is(&$fn('[-]'), \&Pinwheel::Model::_wrap_all_rows);
    is(&$fn('[1]'), \&Pinwheel::Model::_wrap_all_column);
    is(&$fn('-'), \&Pinwheel::Model::_wrap_one_row);
    is(&$fn('1'), \&Pinwheel::Model::_wrap_one_value);
    is(&$fn('x'), \&Pinwheel::Model::_wrap_nothing);

    # Types can be guessed from name
    is(&$fn(undef, 'find'), \&Pinwheel::Model::_wrap_one_row);
    is(&$fn(undef, 'find_by_foo'), \&Pinwheel::Model::_wrap_one_row);
    is(&$fn(undef, 'find_all'), \&Pinwheel::Model::_wrap_all_rows);
    is(&$fn(undef, 'count'), \&Pinwheel::Model::_wrap_one_value);
    is(&$fn(undef, 'set'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'add'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'remove'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'create'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'replace'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'update'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'delete'), \&Pinwheel::Model::_wrap_nothing);
    is(&$fn(undef, 'set_all'), \&Pinwheel::Model::_wrap_nothing);

    # Default type is '[-]'
    is(&$fn(undef, 'foo'), \&Pinwheel::Model::_wrap_all_rows);
    is(&$fn(undef, 'settings'), \&Pinwheel::Model::_wrap_all_rows);

    # $name doesn't override $type
    is(&$fn('[-]', 'find'), \&Pinwheel::Model::_wrap_all_rows);

    # Unknown type gives undef
    is(&$fn('wibble'), undef);
    # Missing type and name gives undef
    is(&$fn(), undef);
}


# Classify SQL parameters
{
    my ($sql, $sql2, $n, $d, $s);

    $sql = q{SELECT NOW()};
    ($sql2, $n, $d, $s) = @{Pinwheel::Model::_parse_sql($sql)};
    is($sql, $sql2);
    is($n, 0);
    is($d, undef);
    is_deeply($s, []);

    $sql = q{SELECT * FROM foo WHERE bar = ?};
    ($sql2, $n, $d, $s) = @{Pinwheel::Model::_parse_sql($sql)};
    is($sql, $sql2);
    is($n, 1);
    is($d, undef);
    is_deeply($s, [0]);

    $sql = q{SELECT * FROM foo WHERE bar = ?$\d+$};
    ($sql2, $n, $d, $s) = @{Pinwheel::Model::_parse_sql($sql)};
    is($sql, $sql2);
    is($n, 1);
    is_deeply($d, [[0, qr/^\d+$/]]);
    is_deeply($s, []);

    $sql = q{
        SELECT *
        FROM foo
        WHERE abc=?
        AND def < ?
        AND ghi ?$/[<>=!]+/$ ?
    };
    ($sql2, $n, $d, $s) = @{Pinwheel::Model::_parse_sql($sql)};
    is($sql, $sql2);
    is($n, 4);
    is_deeply($d, [[2, qr/^[<>=!]+$/]]);
    is_deeply($s, [0, 1, 3]);

    $sql = q{
        SELECT *
        FROM foo
        WHERE abc = ?$\d+$
        AND bar ?$!?=$ ?
    };
    ($sql2, $n, $d, $s) = @{Pinwheel::Model::_parse_sql($sql)};
    is($sql, $sql2);
    is($n, 3);
    is_deeply($d, [[0, qr/^\d+$/], [1, qr/^!?=$/]]);
    is_deeply($s, [2]);
}


# Insert dynamic SQL parameters
{
    my ($sql1, $sql2, $info);

    $info = [];
    $sql1 = q{SELECT NOW()};
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, []);
    is($sql1, $sql2);

    $info = [[0, qr/^\d+$/]];
    $sql1 = q{SELECT * FROM foo WHERE id = ?$\d+$};
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, [123]);
    is($sql2, q{SELECT * FROM foo WHERE id = 123});
    eval { Pinwheel::Model::_insert_dynamic_params($sql1, $info, ["'"]) };
    like($@, qr/does not match requirement/i);

    $info = [[0, qr/^(AND baz = \d+)?$/]];
    $sql1 = q{SELECT * FROM foo WHERE bar = ? ?$(AND baz = \d+)?$};
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, [undef]);
    is($sql2, q{SELECT * FROM foo WHERE bar = ? });
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['']);
    is($sql2, q{SELECT * FROM foo WHERE bar = ? });
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['AND baz = 123']);
    is($sql2, q{SELECT * FROM foo WHERE bar = ? AND baz = 123});

    $info = [[0, qr/^!?=$/], [1, qr/^\d+$/]];
    $sql1 = q{SELECT * FROM foo WHERE bar ?$!?=$ ?$\d+$};
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['=', 92]);
    is($sql2, q{SELECT * FROM foo WHERE bar = 92});
    $sql2 = Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['!=', 42]);
    is($sql2, q{SELECT * FROM foo WHERE bar != 42});
    eval { Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['<', 12]) };
    like($@, qr/does not match requirement/i);
    eval { Pinwheel::Model::_insert_dynamic_params($sql1, $info, ['=', 'a']) };
    like($@, qr/does not match requirement/i);
}


# Query function builder
{
    my $model_stash;

    { package Models::Test }
    $model_stash = \%::Models::Test::;

    { package Models::Test; Pinwheel::Model::query('find1') }
    isnt($model_stash->{find1}, undef);

    eval {
        { package Models::Test; Pinwheel::Model::query('find2', type => 'foo') }
    };
    like($@, qr/unknown query result type/i);
    is($model_stash->{find2}, undef);
}


# Prefetched links
{
    my (@links, $model, $data, $tables, $obj);

    {
        package Models::Test;
        our @ISA = qw(Pinwheel::Model::Base);
        sub missing { return undef };
        sub _prefetched_link { push @links, \@_ };
    }

    $model = {model_class => 'Models::Test', table => 'test', datetimes => []};
    $data = {'missing' => undef, 'missing.more_missing' => undef};
    $tables = ['missing', 'missing.more_missing'];
    $obj = Pinwheel::Model::_make_model_object($model, $data, $tables);
    is(scalar(@links), 1);
    is($links[0][1], 'missing');
    is($links[0][2], undef);
}
