package NKTI::general::dbconnect;

use strict;
use warnings;
use JSON::XS;
use DBI;

# Create Module for Connection MySQL Database :
# ------------------------------------------------------------------------
sub mysql {
    # Define parameter Module :
    # ----------------------------------------------------------------
    my ($self, $get_db_config) = @_;

    # Declare scalar for result :
    # ----------------------------------------------------------------
    my $dbh;

    # Declare scalar for Database Config :
    # ----------------------------------------------------------------
    my $db_config = decode_json($get_db_config);
    my $db_user = $db_config->{'db_user'};
    my $db_pass = $db_config->{'db_pass'};
    my $db_name = $db_config->{'db_name'};
    my $db_host = $db_config->{'db_host'};

    # Define database conection :
    # ----------------------------------------------------------------
    my $dsn = 'DBI:mysql:database='.$db_name.';host='.$db_host;
    $dbh = DBI->connect($dsn, $db_user, $db_pass, {
            RaiseError => 0,
            PrintError => 0,
        });

    # Return Result :
    # ----------------------------------------------------------------
    return $dbh;
}
# End of Create Module for Connection MySQL Database.
# ===========================================================================================================

# Module for Connection PostgreSQL Database :
# ------------------------------------------------------------------------
sub pgsql {
	# ----------------------------------------------------------------
	# Defien parameter Subroutine :
	# ----------------------------------------------------------------
    my ($self, $get_db_config) = @_;
    # ----------------------------------------------------------------
    # Declare scalar for result :
    # ----------------------------------------------------------------
    my $dbh;
    # ----------------------------------------------------------------
    # Declare scalar for Database Config :
    # ----------------------------------------------------------------
    my $db_config = decode_json($get_db_config);
    my $db_user = $db_config->{'db_user'};
    my $db_pass = $db_config->{'db_pass'};
    my $db_name = $db_config->{'db_name'};
    my $db_host = $db_config->{'db_host'};
    # ----------------------------------------------------------------
    # Define database conection :
    # ----------------------------------------------------------------
    my $dsn = 'DBI:Pg:database='.$db_name.';host='.$db_host.';port=5432';
    $dbh = DBI->connect($dsn, $db_user, $db_pass, {RaiseError => 1});
    # ----------------------------------------------------------------
    # Return Result :
    # ----------------------------------------------------------------
    return $dbh;
}
# End of Module for Connection PostgreSQL DatabaseModule for Connection PostgreSQL Databas
# ===========================================================================================================

# Create Module for connection SQLite :
# ------------------------------------------------------------------------
sub sqlite {
    
    # Define parameter module :
    # ----------------------------------------------------------------
    my ($self, $fileloc_db) = @_;
    
    # EXPR
    # ----------------------------------------------------------------
    my $driver = "SQLite";
    my $dsn = "DBI:$driver:dbname=$fileloc_db";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
        or die $DBI::errstr;
        
    # Return Result :
    # ----------------------------------------------------------------
    return $dbh;
}
# End of Create Module for connection SQLite
# ===========================================================================================================

1;
__END__

=head1 NAME

NKTI::general::dbconnect - Preparing to multiple database connection.

=head1 SYNOPSIS

    use NKTI::general::dbconnect;

    # JSON database config :
    my $json_dbconfig = '{
        "db_host" : "localhost",
        "db_name" : "your_db",
        "db_user" : "your_userdb",
        "db_psas" : "your_passUserDb"
    }';

    # Initialization (example mysql) :
    my $dbh = NKTI::general::dbconnect->mysql($json_dbconfig);

    # For Disconnected :
    $dbh->disconnect();

=head1 DESCRIPTION

This module allows the use of multiple database connection database with portable way.
The purpose of this module is to be easy to use if you want to use more than one database connection.
This Module based DBI.

Modul ini memungkinkan penggunaan database koneksi database dengan cara portable.
Tujuan dari modul ini adalah mudah digunakan jika Anda ingin menggunakan lebih dari satu koneksi database.

=head1 EXAMPLE 1

    # Example file (db_one.pl) :
    #!/usr/bin/perl
    use strict;
    use warnings;
    use NKTI::general::dbconnect;

    # Database Config 1 :
    my $json_dbconfig1 = '{
        "db_host" : "localhost",
        "db_name" : "your_db1",
        "db_user" : "your_userdb1",
        "db_psas" : "your_passUserDb1"
    }';

    # Database Config 2 :
    my $json_dbconfig2 = '{
        "db_host" : "localhost",
        "db_name" : "your_db1",
        "db_user" : "your_userdb1",
        "db_psas" : "your_passUserDb1"
    }';

    # Establishe Database Interface 1 :
    my $dbh = NKTI::general::dbconnect->mysql($json_dbconfig1);

    # Statement Handle :
    my $sth = $dbh->prepare('SELECT * FROM yourtable');
    $sth->execute();
    my $rv = $sth->rows;
    if ($rv >= 1) {

        # Established Database Interface 2 :
        my $dbh1 = NKTI::general::dbconnect->mysql($json_dbconfig2);

        # Statement Handle :
        my $sth1 = $dbh1->prepare('SELECT * FROM yourtable');
        $sth1->execute();
        my $rv1 = $sth1->rows;
        if ($rv1 >= 1) {
            # true action ...
        } else {
            # false action ...
        }

        # Disconnect and Finishing Query 2 :
        $sth1->finish();
        $dbh1->disconnect();

    } else {
        # false action ...
    }

    # Disconnect and Finishing Query 1 :
    $sth->finish();
    $dbh->disconnect();

=head1 EXAMPLE 2

    # Example file (db_two.pl) :
    #!/usr/bin/perl
    use strict;
    use warnings;
    use NKTI::general::dbconnect;

    # Database Config MySQL :
    my $json_dbconfig1 = '{
        "db_host" : "localhost",
        "db_name" : "your_db1",
        "db_user" : "your_userdb1",
        "db_psas" : "your_passUserDb1"
    }';

    # Database Config SQLite :
    my $dbconfig_sqlite = '/your/path/sqlite.db';

    # Establishe Database Interface MySQL :
    my $dbh = NKTI::general::dbconnect->mysql($json_dbconfig1);

    # Statement Handle :
    my $sth = $dbh->prepare('SELECT * FROM yourtable');
    $sth->execute();
    my $rv = $sth->rows;
    if ($rv >= 1) {

        # Established Database Interface SQLite :
        my $dbh1 = NKTI::general::dbconnect->sqlite($dbconfig_sqlite);

        # Statement Handle :
        my $sth1 = $dbh1->prepare('SELECT * FROM yourtable');
        $sth1->execute();
        my $rv1 = $sth1->rows;
        if ($rv1 >= 1) {
            # true action ...
        } else {
            # false action ...
        }

        # Disconnect and Finishing Query SQLite :
        $sth1->finish();
        $dbh1->disconnect();

    } else {
        # false action ...
    }

    # Disconnect and Finishing Query :
    $sth->finish();
    $dbh->disconnect();

=head1 EXPLAIN Subroutine mysql

    Description Subroutine :
    ----------------------------------------
    Subroutine for MySQL Database.

    Parameter Subroutine :
    ----------------------------------------
    $get_db_config      =>  JSON Format Database config.

=head1 EXPLAIN Subroutine pgsql

	Deskripsi subroutine pgsql() :
	----------------------------------------
	Subroutne for PostgreSQL Database.

	Parameter subroutine pgsql() :
	----------------------------------------
	$your_dbconifg      =>  JSON Format Database config.

=head1 EXPLAIN Subroutine sqlite

    Description Subroutine :
    ----------------------------------------
    Subroutine for SQLite Database.

    Parameter Subroutine :
    ----------------------------------------
    $fieloc_db          =>  Location of File database SQLite.

=head1 SEE ALSO



=head1 AUTHOR

Achmad Yusri Afandi, (yusrideb@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

Library for Database Interface.

=cut