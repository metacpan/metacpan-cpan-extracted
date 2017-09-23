package NKTI::general::dbms::mysql;

use strict;
use warnings;
use DBI;
use JSON;
use Data::Dumper;

# Define Version :
# ---------------------------------------------------------------- 
our $VERSION = '0.15';

# Subroutine for Error Handling MySQL Connection :
# ------------------------------------------------------------------------
=head1 SUBROUTINE errconn()
    
    Deskripsi subroutine errcon() :
    ----------------------------------------  
    Subroutine yang berfungsi untuk Handel Error Connection MySQL.

    Parameter subroutine errcon() :
    ----------------------------------------
    No Parameter Subroutine.
    
=cut
sub errconn {

	# Define parameter subroutine :
	# ----------------------------------------------------------------
	my $self = shift;

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
# End of Subroutine for Error Handling MySQL Connection.
# ===========================================================================================================

# Subroutine for Error Handling data MySQL Connection :
# ------------------------------------------------------------------------
=head1 SUBROUTINE errdata()
    
    Deskripsi subroutine errdata() :
    ----------------------------------------
    Subroutine yang berfungsi untuk menampilkan error saat proses koneksi Data MySQL.

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
# End of Subroutine for Error Handling data MySQL Connection.
# ===========================================================================================================
                  
1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk database mysql.
=cut