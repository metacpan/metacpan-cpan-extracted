package NKTI::general::dbconnect_devel;

use strict;
use warnings;
use JSON;
use DBI;

# Subroutine for MySQL RDMS connection :
# ------------------------------------------------------------------------
=head1 SUBROUTINE mysql()
    
    Deskripsi subroutine mysql() :
    ----------------------------------------
    Subroutine yang berfungsi untuk koneksi ke DBMS tanpa nama database.

    Parameter subroutine mysql() :
    ----------------------------------------
    $get_db_config		=>		Berisi database config.
    
=cut
sub mysql {
    
    # Define parameter subroutine :
    # ----------------------------------------------------------------
    my ($get_db_config) = @_;

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
    my $dsn = 'DBI:mysql:;host='.$db_host;
    $dbh = DBI->connect($dsn, $db_user, $db_pass, {RaiseError => 1});

    # Return Result :
    # ----------------------------------------------------------------
    return $dbh;
}
# End of Subroutine for MySQL RDMS connection.
# ===========================================================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk koneksi database development.
=cut