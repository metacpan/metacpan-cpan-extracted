use strict;
use warnings;

our $VERSION = '0.01';

# built out from DBD::Nullp;
{
    package DBD::SimpleMock;

    require DBI;
    require Carp;

    our @EXPORT = qw(); # Do NOT @EXPORT anything.
    our $VERSION = "0.01";

    our $drh = undef;    # holds driver handle once initialised

    sub driver  {
        return $drh if $drh;
        my ($class, $attr) = @_;
        $class .= "::dr";
        ($drh) = DBI::_new_drh($class, {
            'Name' => 'SimpleMock',
            'Version' => $VERSION,
            'Attribution' => 'Mock DBD for tests',
        });
        $drh;
    }

    sub CLONE {
        undef $drh;
    }
}


{   package DBD::SimpleMock::dr;
    our $imp_data_size = 0;
    use strict;

    sub connect {
        my $drh = shift;
        if (SimpleMock::Model::DBI::_get_dbi_meta('connect_fail')) {
            # If connect_fail is set, we simulate a connection failure
            $drh->set_err(1000, "Database unavailable");
            return;
        }
        my $dbh = $drh->SUPER::connect(@_)
            or return $drh->set_err(1000, "Database unavailable");
        $dbh->STORE(Active => 1);
        return $dbh;
    }

    sub DESTROY { undef }
}


{   package DBD::SimpleMock::db;
    use strict;
    use DBI;
    use base 'DBD::_::db';
    use Carp qw(croak);

    our $imp_data_size = 0;

    # Added get_info to support tests in 10examp.t
    sub get_info {
        my ($dbh, $type) = @_;

        if ($type == 29) {
            return '"';
        }
        return;
    }

    sub prepare {
        my ($dbh, $statement)= @_;

        # fail if prepare_fail META tag is set
        if (SimpleMock::Model::DBI::_get_dbi_meta('prepare_fail')) {
            return $dbh->set_err(1001, "Prepare failed");
        }

        my ($outer) = DBI::_new_sth($dbh, {
            'Statement' => $statement,
        });

        return $outer;
    }

    sub FETCH {
        my ($dbh, $attrib) = @_;
        return $dbh->SUPER::FETCH($attrib);
    }

    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        if ($attrib eq 'AutoCommit') {
            Carp::croak("Can't disable AutoCommit") unless $value;
            # convert AutoCommit values to magic ones to let DBI
            # know that the driver has 'handled' the AutoCommit attribute
            $value = ($value) ? -901 : -900;
        }
        return $dbh->SUPER::STORE($attrib, $value);
    }

    sub ping { 1 }

    sub disconnect {
        shift->STORE(Active => 0);
    }

}


{   package DBD::SimpleMock::st; # ====== STATEMENT ======
    our $imp_data_size = 0;
    use strict;

    sub bind_param {
        my ($sth, $param, $value, $attr) = @_;
        $sth->{ParamValues}{$param} = $value;
        if (defined $attr) {
            # attr (SQL type hints) accepted but not used by mock driver
        }
        return 1;
    }

    sub execute {
        my ($sth, @arg) = @_;
        if (SimpleMock::Model::DBI::_get_dbi_meta('execute_fail')) {
            return $sth->set_err(1002, "Execute failed");
        }
        my $mock = SimpleMock::Model::DBI::_get_mock_for($sth->{Statement}, \@arg);
        my $field_count = @{$mock->{data}->[0]};
        $sth->STORE(NUM_OF_FIELDS => $field_count);
        $sth->STORE(Active => 1);
        $sth->{simplemock_data} = $mock->{data};
        $sth->{NAME} = $mock->{cols} if ($mock->{cols});
        1;
    }

    sub fetchrow_arrayref {
        my $sth = shift;

        my $data = shift @{$sth->{simplemock_data}};
        if (!$data || !@$data) {
            $sth->finish;     # no more data so finish
            return;
        }
        return $sth->_set_fbav($data);
    }

    *fetch = \&fetchrow_arrayref;

    sub FETCH {
        my ($sth, $attrib) = @_;
        return $sth->SUPER::FETCH($attrib);
    }

    sub STORE {
        my ($sth, $attrib, $value) = @_;
        return $sth->SUPER::STORE($attrib, $value);
    }

}

1;

=head1 NAME

DBD::SimpleMock - A mock DBD for testing DBI applications

=head1 SYNOPSIS

Generally, you will use this directly via the SimpleMock module, but see the test
for a standalone usage example.

    use SimpleMock qw(register_mocks);
    use Module::To::Test;
    my $d1 = [
        [ 'Clive', 'clive@testme.com' ],
        [ 'Colin', 'colin@testme.com' ],
    ];

    my $d2 = [
        [ 'Dave', 'dave@testme.com' ],
        [ 'Diane', 'diane@testme.com' ],
    ];

    register_mocks(
        DBI => {
            # see below for global flags that can be set - by default they are all 0
            META => {
                allow_unmocked_queries => 0, # Set to 1 to allow unmocked queries to not be fatal
                connect_fail => 0,           # Set to 1 to simulate a connection failure
                prepare_fail => 0,           # Set to 1 to simulate a prepare failure
                execute_fail => 0,           # Set to 1 to simulate an execute failure
            },
            QUERIES => [
                {
                    sql => 'SELECT id, name, email FROM my_table WHERE name LIKE ?',
                    # each query can have multiple results defined based on placeholder values
                    # note: the C%/D% in the args are literals on the actual args sent
                    #       the code may be using a wild card, but the mocks are not aware of that
                    results => [
                        { args => [ 'C%' ], data => $d1 },
                        { args => [ 'D%' ], data => $d2 },
                    ],
                    # define cols if using any of the *_hashref methods
                    cols => [ 'id', 'name', 'email' ],
                },
            ],
        }
    );

    # call the code that runs the query
    my $result = Module::To::Test->get_data('C%');
    is_deeply $result, $d1, 'Got expected data for C%';

    my $result2 = Module::To::Test->get_data('D%');
    is_deeply $result2, $d2, 'Got expected data for D%';

    done_testing();

=head1 DESCRIPTION

DBD::SimpleMock is a mock database driver for DBI that allows you to simulate database
interactions in your tests without needing a real database connection. It is particularly
useful for unit testing DBI-based applications.

=head1 USAGE

In your test, register your mock queries and their expected results using the `register_mocks` function from the SimpleMock module:

    use Test::More;
    use SimpleMock qw(register_mocks);
    register_mocks(
        DBI => {
            # optional meta settings
            META => {
                ...
            },
            # each query must have an 'sql' and at least one 'results' entry
            # If you are using the `*_hashref` methods, you must also define 'cols'
            QUERIES => [
                {
                    sql => 'SELECT id, name, email FROM my_table WHERE name LIKE ?',
                    results => [
                        # data is an array ref of arrayrefs, each representing a row 
                        { args => [ 'C%' ], data => $d1 },
                        { args => [ 'D%' ], data => $d2 },
                        # no args means it will match any query with no placeholders
                        { data => $d3 }, # this will match any query without placeholders
                    ],
                    # optional, if you are using the *_hashref methods
                    cols => [ 'id', 'name', 'email' ],
                },
            ],
        }
    });

Meta tags are used to make aspects of the DBD to explicitly fail, or to allow unmocked queries to return empty results instead of throwing an exception.

=head1 META SETTINGS

These are the available flags you can set in the `META` section of your mocks registration:

=over

=item * `allow_unmocked_queries`: If set to 1, unmocked queries will return an empty result set and not throw an exception.
=item * `connect_fail`: If set to 1, simulates a connection failure when connecting to the mock database.
=item * `prepare_fail`: If set to 1, simulates a failure when preparing a statement.
=item * `execute_fail`: If set to 1, simulates a failure when executing a statement.

=back

Note that if you set connect_fail, prepare_fail & execute_fail are moot at that point, so best practice is to only enable each as needed by the test.

=cut
