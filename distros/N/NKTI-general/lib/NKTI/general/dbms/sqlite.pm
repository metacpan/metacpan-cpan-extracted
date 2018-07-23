package NKTI::general::dbms::sqlite;

use strict;
use warnings;
use DBI;
use JSON;
use Data::Dumper;

# Subroutine for SQLite error Handling :
# ------------------------------------------------------------------------
=head1 SUBROUTINE errconn()
    
    Deskripsi subroutine errconn() :
    ----------------------------------------
    Subroutine yang berfungsi untuk handel Error Connection MySQL.
    
    Parameter subroutine errconn() :
    ----------------------------------------
    No Parameter Subroutine
    
=cut
sub errconn {
	
	# Define array for place error DBMS Connection :
	# ----------------------------------------------------------------
	my @data = ();
	
	# Check IF defined $DBI::err;
	# ----------------------------------------------------------------
	if (defined $DBI::err) {
		$data[0] = $DBI::err;
	} else {
		$data[0] = 00000;
	}
	
	# Check IF defined $DBI::state :
	# ----------------------------------------------------------------
	if (defined $DBI::state) {
		$data[1] = $DBI::state;
	} else {
		$data[1] = 0;
	}
	
	# Check IF defined $DBI::errstr :
	# ----------------------------------------------------------------
	if (defined $DBI::errstr) {
		$data[2] = $DBI::errstr;
	} else {
		$data[2] = 'none';
	}
	
	# Return Result :
	# ----------------------------------------------------------------
	return \@data;
}
# End of Subroutine for SQLite error Handling.
# ===========================================================================================================

# Subroutine for Error Handling Data SQLite :
# ------------------------------------------------------------------------
=head1 SUBROUTINE errdata()
    
    Deskripsi subroutine errdata() :
    ----------------------------------------
    Subroutine yang berfungsi untuk menampilkan error saat proses koneksi Data SQLite.

    Parameter subroutine errdata() :
    ---------------------------------------- 
    $sth		=>	Berisi scalar $sth.
    
=cut
sub errdata {                                                                  
	
	# Define parameter Subroutine :
	# ----------------------------------------------------------------
	my ($self, $sth) = @_;
	
	# Define array for place result :
	# ----------------------------------------------------------------
	my @data = ();
	
	# Place result :
	# ----------------------------------------------------------------
	$data[0] = $sth->err;
	$data[1] = $sth->state;
	$data[2] = $sth->errstr;
	
	# Return Result :
	# ----------------------------------------------------------------
	return \@data;
}
# End of Subroutine for Error Handling Data SQLite.
# ===========================================================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk database SQLite.
=cut