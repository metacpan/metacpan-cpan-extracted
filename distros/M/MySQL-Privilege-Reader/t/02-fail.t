#!perl -T
use Test::More tests => 6;
use Test::Exception;
use Test::MockObject;

BEGIN {    # Test #1
    use_ok('MySQL::Privilege::Reader') || print "Bail out!";
}

{          # Test #2
    my $dbh = Test::MockObject->new;
    $dbh->fake_module('DBI');
    $dbh->fake_module('DBI::db');
    $dbh->mock( isa => sub { my $class = shift; return $class eq 'DBI::db' } );
    $dbh->mock(
        selectall_arrayref => sub {
            die q{DBD::mysql::db selectall_arrayref }
              . q{failed: MySQL server has gone away};
        }
    );
    dies_ok { MySQL::Privilege::Reader->get_privileges($dbh) }
    q{Exception thrown as expected};
}

{    # Test #3
    dies_ok { MySQL::Privilege::Reader->get_privileges(undef) }
    q{Dies if undef is passed instead of a DBI object};
}

{    # Test #4
    my $dbh = Test::MockObject->new;
    dies_ok { MySQL::Privilege::Reader->get_privileges() }
    q{Dies if some other type of reference is passed in};
}

{    # Test #5
    dies_ok { MySQL::Privilege::Reader->get_privileges(1) }
    q{Dies on a defined-but-not-reference value};
}

{    # Test #6
    my $dbh = Test::MockObject->new;
    $dbh->fake_module('NotDBI');
    $dbh->mock( isa => sub { my $class = shift; return $class eq 'NotDBI' } );
    dies_ok { MySQL::Privilege::Reader->get_privileges($dbh) }
    q{Dies if a valid object other than a DBI::db is passed in as argument.}
}
