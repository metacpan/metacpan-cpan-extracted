package NKTI::general::file;

use strict;
use warnings;

# Create Subroutine for Clean Directory "/" Symbol :
# ------------------------------------------------------------------------
=head1 dir_symbol()
    
    Deskripsi Subroutine :
    ----------------------------------------
    Subroutine yang berfungsi untuk clean Symbol "/"
    dibagian depan dan akhir Lokasi Direktori.

    Parameter Subroutine :
    ----------------------------------------
    $locdir = [ Berisi ]

=cut
sub trim {
    
    # Define parameter subroutine :
    # ----------------------------------------------------------------
    my ($self, $locdir) = @_;
    
    # Action Trim White Space :
    # ----------------------------------------------------------------
    $locdir =~ s/^\s+//;
    $locdir =~ s/\s+$//;
    
    # Action Trim "/" :
    # ----------------------------------------------------------------
    $locdir =~ s/^\///;
    $locdir =~ s/\/$//;
    
    # Return REuslt :
    # ----------------------------------------------------------------
    return $locdir;
}
# End of Create Subroutine for Clean Directory "/" Symbol.
# ===========================================================================================================

# Create Subroutine for Convert Location File Or Dir into string regex :
# ------------------------------------------------------------------------
=head1 convert_regex_mode()
    
    Deskripsi Subroutine :
    ----------------------------------------

    Parameter Subroutine :
    ----------------------------------------
    describ_param

=cut
sub convert_regex_mode {
    
    # Define paremter Subroutin :
    # ----------------------------------------------------------------
    my ($elf, $location) = @_;
    
    # Action convert location of files into regex mode :
    # ----------------------------------------------------------------
    $location =~ s/\//\\\//g;
    
    # Return Result :
    # ----------------------------------------------------------------
    return $location; 
}
# End of Create Subroutine for Convert Location File Or Dir into string regex.
# ===========================================================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berisi Function untuk aktivitas terhadap file.
=cut