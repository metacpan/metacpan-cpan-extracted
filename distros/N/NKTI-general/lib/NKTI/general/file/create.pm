package NKTI::general::file::create;

use strict;
use warnings;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Malltronik::general::file::create ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# Define Version Application
# ----------------------------------------------------------------
our $VERSION = '0.14';

# Constructor
# ------------------------------------------------------------
=head1 MODULE new()

    Deskripsi :
    ----------------------------------------
    Module yang berfungsi sebagai konstruktor Module.

    Parameter Modul :
    ----------------------------------------
    _file_name =>   Parameter yang berisi nama file yang akan dibuat.
    _dir_loc =>     Parameter yang berisi lokasi tempat penyimpanan file yang dibuat
    _isi_file =>    Parameter yang berisi Isi file yang dibuat.

=cut
sub new {

    # Define scalar for arguments object :
    # ------------------------------------------------------------
    my $class = shift;
    my $self = {
        _file_name => shift,
        _dir_loc  => shift,
        _isi_file => shift
    };
    bless $self, $class;
    return $self;
}

# Module for Create New File :
# ------------------------------------------------------------
=head1 MODULE create()

    Parameter Modul :
    ----------------------------------------
    TIdak ada parameter module, namun aksi dalam module
    berdasakarkan parameter dari Constructor.

=cut
sub create {

    # Define arguments :
    # ------------------------------------------------------------
    my ($self) = @_;
    my $filename = $self->{_file_name};
    my $destination = $self->{_dir_loc};
    my $isi_file = $self->{_isi_file};

    # Define variable for FileHandle :
    # ------------------------------------------------------------no
    my $loc_files = $destination . $filename;

    # Declare Hash for placing result create new file :
    # ----------------------------------------------------------------
    my %data;

    # Create New Files :
    # ------------------------------------------------------------
    open(FILE, '>', $loc_files) or die "File : $loc_files is not exists $!";
    print FILE $isi_file;
    close(FILE);

    # Chcck IF $loc_files is exists :
    # ------------------------------------------------------------
    if (-e $loc_files)
    {
        # Placing success result into hash "%data" :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 1,
            'data' => {
                'dirloc' => $destination,
                'filename' => $filename,
                'fileloc' => $loc_files
            }
        };
    }
    # End of check IF $loc_files is exists.
    # ================================================================

    # Check IF $loc_files is not exists :
    # ------------------------------------------------------------
    else
    {
        # Placing error result into hash "$data" :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 0,
            'data' => {
                'dirloc' => $destination,
                'filename' => $filename,
                'fileloc' => $loc_files
            }
        };
    }
    # End of check IF $loc_files is not exists.
    # ================================================================
    
    # Return result :
    # ----------------------------------------------------------------
    return \%data;
}
# End of Module for Create New File.
# ================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk membuat file.

=cut