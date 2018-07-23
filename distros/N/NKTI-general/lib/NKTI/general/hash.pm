package NKTI::general::hash;

use strict;
use warnings;

# Subroutine for union :
# ------------------------------------------------------------------------
=head1 SUBROUTINE union()

    Deskripsi subroutine union() :
    ----------------------------------------
    Subroutine yang berfungsi untuk menggabungkan dua hashref, jika
    sudah memenuhi persyaratan dari Subroutine "merger".

    Parameter subroutine union() :
    ----------------------------------------
    $hashref1           =>  Berisi Hashref yang akan digabungkan dengan
                            hashref yang lain.
    $hashref2           =>  Berisi hashref yang digunakan untuk digabungkan
                            key hashref1.

=cut
sub union {
    # ----------------------------------------------------------------
	# Define parameter Subroutine :
	# ----------------------------------------------------------------
	my ($self, $hashref1, $hashref2) = @_;
    # ----------------------------------------------------------------
    # Define hash for data :
	# ----------------------------------------------------------------
    my %hashref_first = %{$hashref1};
    my %hashref_seconds = %{$hashref2};
    my %data = ();
    # ----------------------------------------------------------------
    # While for get key and value $hashref_utama :
    # ----------------------------------------------------------------
    while (my ($key, $value) = each %hashref_first) {
        # ----------------------------------------------------------------
        # Place data hash :
        # ----------------------------------------------------------------
        $data{$key} = $value;
        # ----------------------------------------------------------------
        # While for get key and value $hashref1 :
        # ----------------------------------------------------------------
        while (my ($key1, $value1) = each %hashref_seconds) {
            $data{$key1} = $value1;
        }
    }
    
    # Return result :
	# ----------------------------------------------------------------
	return \%data; 
}
# End of Subroutine for union
# ===========================================================================================================

# Subroutine for Merger Hash :
# ------------------------------------------------------------------------
=head1 SUBROUTINE merger()

    Deskripsi subroutine merger() :
    ----------------------------------------
    Subroutine yang berfungsi untuk menggabungkan 2 Hash

    Parameter subroutine merger() :
    ----------------------------------------
    $hashref_utama      =>  Berisi hashref yang akan digabungkan
                            dengan yang lainnya.
    $hashref1           =>  Berisi Hash ref untuk digabungkan dengan hashref utama.

=cut
sub merger {
	
    # Define parameter Subroutine :
	# ----------------------------------------------------------------
	my ($self, $hashref_utama, $hashref1) = @_;
    
    # Define hash for data :
	# ---------------------------------------------------------------- 
    my %hashref_first = %{$hashref_utama};
    my %hashref_seconds = %{$hashref1};
    my %data = ();
    my $union_data = undef;
    
    # ------------------------------------------------------------------------
	# Check IF not null hash $hashref_utama :
	# ------------------------------------------------------------------------
	if (keys(%hashref_first)) {
        # ------------------------------------------------------------------------
        # Check IF not null hash $hashref_seconds :
        # ------------------------------------------------------------------------
        if (keys(%hashref_seconds)) {
            # ----------------------------------------------------------------
            # Action Union :
            # ----------------------------------------------------------------
            $union_data = $self->union($hashref_utama, $hashref1);
        }
        # ------------------------------------------------------------------------
        # Check IF is null hash $hashref_seconds :
        # ------------------------------------------------------------------------
        else {
            $union_data = $hashref_utama;
        }
        # ------------------------------------------------------------------------
        # End of check IF is null hash $hashref_seconds.
        # ========================================================================
	}
	# ------------------------------------------------------------------------
	# Check IF null hash $hashref1 :
	# ------------------------------------------------------------------------
	else {
        # ----------------------------------------------------------------
		# Action Union :
		# ----------------------------------------------------------------
		$union_data = $hashref1;
	}
	# ------------------------------------------------------------------------
	# End of check IF .
	# ========================================================================
    
    # Place result :
	# ----------------------------------------------------------------
	%data = %{$union_data};
    # ----------------------------------------------------------------
    # Return result :
	# ----------------------------------------------------------------
	return \%data; 
}
# End of Subroutine for Merger Hash
# ===========================================================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berisi Function untuk manajemen Hash.
=cut