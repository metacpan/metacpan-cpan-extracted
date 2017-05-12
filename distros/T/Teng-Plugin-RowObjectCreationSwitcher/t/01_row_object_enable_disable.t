#!perl
use strict;
use warnings;
use Test::More;
use t::Utils;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->load_plugin('RowObjectCreationSwitcher');
$db->setup_test_db;
$db->fast_insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

my $condition = { name     => 'perl' };
my $option    = { order_by => 'id'   };


subtest 'suppress row object', sub {
    $db->suppress_row_objects(0);
    my $row = $db->single('mock_basic', $condition, $option);
    ok( $row->isa('Teng::Row') );
    {
        my $guard = $db->temporary_suppress_row_objects_guard(1);
        $row = $db->single('mock_basic', $condition, $option);
        is( $db->suppress_row_objects, 1 );
        is( ref $row, 'HASH' );
    }
    # dismiss guard
    $row = $db->single('mock_basic', $condition, $option);
    ok( $row->isa('Teng::Row') );
};


subtest 'enable row object', sub {
    $db->suppress_row_objects(1);
    my $row = $db->single('mock_basic', $condition, $option);
    is( ref $row, 'HASH' );
    {
        my $guard = $db->temporary_suppress_row_objects_guard(0);
        $row = $db->single('mock_basic', $condition, $option);
        ok( $row->isa('Teng::Row') );
    }
    # dismiss guard
    $row = $db->single('mock_basic', $condition, $option);
    is( ref $row, 'HASH' );
};


subtest 'nested guard', sub {
    $db->suppress_row_objects(0);
    my $row = $db->single('mock_basic', $condition, $option);
    ok( $row->isa('Teng::Row') );
    {
        my $guard = $db->temporary_suppress_row_objects_guard(1);
        $row = $db->single('mock_basic', $condition, $option);
        is( ref $row, 'HASH' );
        {
            my $guard = $db->temporary_suppress_row_objects_guard(1);
            $row = $db->single('mock_basic', $condition, $option);
            is( ref $row, 'HASH' );
        }
        $row = $db->single('mock_basic', $condition, $option);
        is( ref $row, 'HASH' );
    }
    # dismiss guard
    $row = $db->single('mock_basic', $condition, $option);
    ok( $row->isa('Teng::Row') );
};

subtest 'void context (guard object is not received)', sub {
    eval {
        $db->temporary_suppress_row_objects_guard(1);
        fail "expected exception";
    };
    like( $@, qr/Can't create a Scope::Guard in void context/ );
};

subtest 'missing argument', sub {
    eval {
        $db->temporary_suppress_row_objects_guard();
        fail "expected exception";
    };
    like( $@, qr/error: missing argument/ );
};



done_testing();
