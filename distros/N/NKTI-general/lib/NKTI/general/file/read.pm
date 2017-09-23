package NKTI::general::file::read;

use strict;
use warnings;
use JSON;
use Data::Dumper;

# Define Version :
# ----------------------------------------------------------------
our $VERSION = '0.15';

# Create Constructor Module :
# ------------------------------------------------------------------------
#
=head1 CONSTRUCTOR MODULE new()

    Parameter Modul :
    ----------------------------------------
    _loc_file =>    Parameter yang berisi Lokasi File yang akan dibuka
    _type =>        Parameter yang berisi tipe pembacaan file.
                    Ex : just | dbconf.
=head2 OUTPUT :
    Output dari Constructor tergantung dari parameter _type yang dimasukkan.
    
=cut
sub new {

    # Define Parameter Module :
    # ----------------------------------------------------------------
    my $class = shift;
    my $self = {
        _loc_file => shift,
        _type => shift
    };
    bless $self, $class;

    # Declare scalr for parameter module :
    # ----------------------------------------------------------------
    my $loc_files = $self->{_loc_file};
    my $type = $self->{_type};
    my $data;

    # Check IF $type == 'just' :
    # ----------------------------------------------------------------
    if ($type eq 'just')
    {
        # Read Files :
        # ----------------------------------------------------------------
        $data = &read($loc_files);
    }
    # End of check IF $type == 'just'.
    # ----------------------------------------------------------------
    
    # for IF $type == 'json' :
    # ----------------------------------------------------------------
    elsif ($type eq 'json') {
        # ----------------------------------------------------------------
        # Read Files :
        # ----------------------------------------------------------------
        $data = json_berkas($loc_files);
    }

    # Check IF $type == 'dbconf' :
    # ----------------------------------------------------------------
    elsif ($type eq 'dbconf')
    {
        # Read Files :
        # ----------------------------------------------------------------
        $data = dbconf($loc_files);
    }
    # End of check IF $type == 'dbconf'.
    # ----------------------------------------------------------------

    # Check IF $type != 'dbconf' OR $type != 'just' :
    # ----------------------------------------------------------------
    else {
        # ----------------------------------------------------------------
        # Debug Files :
        # ----------------------------------------------------------------
        $data = 'Unsupported type file';
    }
    # Check IF $type != 'dbconf' OR $type != 'just'.
    # ================================================================
    
    # Return result :
    # ----------------------------------------------------------------
    return $data; 
}
# End of Create Constructor Module.
# ===========================================================================================================

# Create Subroutine for Just Read Files :
# ------------------------------------------------------------------------
=head1 SUBROUTINE read()

    Parameter Modul :
    ----------------------------------------
    _loc_file =>    Parameter yang berisi

=head2 OUTPUT :
    Output dari subroutine ini dalam bentuk String.

=cut
sub read {

    # Define parameter module :
    # ----------------------------------------------------------------
    my ($loc_files) = @_;

    # Define scalar for result :
    # ----------------------------------------------------------------
    my $data = '';

    # Open File :
    # ----------------------------------------------------------------
    open(FH, '<', $loc_files) or die $! . " - " . $loc_files;

    # While Loop for  :
    # ----------------------------------------------------------------------------------------
    while (my $lines = <FH>)
    {
        # CLean white space in first and end :
        # ----------------------------------------------------------------
        chomp $lines;

        # Placing fill file into scalar $pre_data :
        # ----------------------------------------------------------------
        $data .= $lines;
    }
    # End of While loop for .
    # ========================================================================================

    # CLose File :
    # ----------------------------------------------------------------
    close (FH);
    # ----------------------------------------------------------------
    # Return Result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Create Subroutine for Just Read Files.
# ===========================================================================================================

# Subroutine for read JSON File :
# ------------------------------------------------------------------------
=head1 json_berkas()
    
    Deskripsi subroutine json_berkas() :
    ----------------------------------------
    Subroutine yang berfungsi untuk membaca file JSON.

    Parameter subroutine json_berkas() :
    ----------------------------------------
    No Parameter Subroutine :
    
=head2 OUTPUT :
    Output dari subroutine ini yaitu dalam bentuk Hashref;

=cut
sub json_berkas {
    # ----------------------------------------------------------------
    # Define parameter subroutine :
    # ----------------------------------------------------------------
    my ($loc_file) = @_;
    # ----------------------------------------------------------------
    # Define scalar for place result :
    # ----------------------------------------------------------------
    my $pre_data = '';
    my $data = {};
    # ----------------------------------------------------------------
    # Action open files :
    # ----------------------------------------------------------------
    open(FH, "<", $loc_file) or die $!;
    # ----------------------------------------------------------------
    # While loop for get fill file :
    # ----------------------------------------------------------------
    while (my $lines = <FH>) {
        # ----------------------------------------------------------------
        # Clean First and End Space :
        # ----------------------------------------------------------------
        chomp ($lines);
        # ----------------------------------------------------------------
        # Placing result files into scalar $pre1_data :
        # ----------------------------------------------------------------
        $pre_data .= $lines;
    }
    # ----------------------------------------------------------------
    # Action close Files :
    # ----------------------------------------------------------------
    close (FH);
    # ----------------------------------------------------------------
    # Regex :
    # ----------------------------------------------------------------
    $pre_data =~ s/(\{)\s+/\{/g;
    $pre_data =~ s/(\})\s+/\}/g;
    $pre_data =~ s/(\[)\s+/\[/g;
    $pre_data =~ s/(\])\s+/\]/g;
    $pre_data =~ s/(\]\,)\s+/\]\,/g;
    $pre_data =~ s/^\s+//g;
    $pre_data =~ s/(\,)\s+/\,/g;
    $pre_data =~ s/\s+[\{]/\{/g;
    $pre_data =~ s/\s+[\}]/\}/g;
    $pre_data =~ s/\s+[\[]/\[/g;
    $pre_data =~ s/\s+[\]]/\]/g;
    $pre_data =~ s/(\,\])/\]/g;
    $pre_data =~ s/(\,\})/\}/g;
    # ----------------------------------------------------------------
    # decode JSON :
    # ----------------------------------------------------------------
    $data = decode_json $pre_data;
    #print $pre_data."\n";
    #print 'Lokasi File : '.$loc_file."\n";
    #print 'data';
    # ----------------------------------------------------------------
    # Return result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Subroutine for read JSON File
# ===========================================================================================================

# Create Subroutine for Read File DB Config and data db config :
# ------------------------------------------------------------------------
=head1 SUBROUTINE dbconf()

    Parameter Modul :
    ----------------------------------------
    Tidak ada parameter Subroutine, aksi dalam module berdasarkan input parameter dari Constructor.

=head2 OUTPUT :

    Output dari subroutine ini dalam bentuk String JSON.

=cut
sub dbconf {

    # Define parameter module :
    # ----------------------------------------------------------------
    my ($loc_file) = @_;
    
    # Define scalar for result files :
    # ----------------------------------------------------------------
    my $pre1_data = '';
    my @pre2_data;
    my %pre3_data;
    my $data = '';

    # Action open files :
    # ----------------------------------------------------------------
    open(FH, "<", $loc_file) or die $!;

    # While loop for get fill file :
    # ----------------------------------------------------------------
    while (my $lines = <FH>) {

        # Clean First and End Space :
        # ----------------------------------------------------------------
        chomp ($lines);

        # Placing result files into scalar $pre1_data :
        # ----------------------------------------------------------------
        $pre1_data .= $lines;
    }
    # End of while loop for get fill file.
    # ================================================================

    # Action close Files :
    # ----------------------------------------------------------------
    close (FH);

    # Clean Serveral String :
    # ----------------------------------------------------------------
    $pre1_data =~ s/(?:\<\?php)//g;
    $pre1_data =~ s/(?:\?\>)//g;
    $pre1_data =~ s/[\s+]//g;
    $pre1_data =~ s/\/\*([^*]|[\r\n]|(\*([^\/]|[\r\n])))*\*\///g;
    $pre1_data =~ s/(\;\$dbconfig_data=array)(.*)//g;
    $pre1_data =~ m/(\$.*)(\()(.*)(\))/;
    $pre1_data = $3;

    # Split Result Clean String and convert to array :
    # ----------------------------------------------------------------
    @pre2_data = split(/,/, $pre1_data);

    # Prepare To While loop for Filter result clean :
    # ----------------------------------------------------------------
    my $i = 0;
    my $key_pre2_data = keys (@pre2_data);
    my $until_loop = $key_pre2_data;

    # While Loop for Filter result clean :
    # ----------------------------------------------------------------------------------------
    while ($i < $until_loop) {

        # Define scalar for index array :
        # ----------------------------------------------------------------
        my $index = $pre2_data[$i];

        # Get data form result regex :
        # ----------------------------------------------------------------
        $index =~ m/(\')(\w+)(\'\=\>\')(.*)([\'])/g;

        # Placing result into hash %pre3_data :
        # ----------------------------------------------------------------
        $pre3_data{$2} = $4;

        # Auto Increment :
        # ----------------------------------------------------------------
        $i++;
    }
    # End of While loop for Filter result clean.
    # ========================================================================================

    # Placing result into hash %data :
    # ----------------------------------------------------------------
    $data = encode_json \%pre3_data;

    # Return Result :
    # ----------------------------------------------------------------
    return $data;
}
# End of Create Subroutine for Read File DB Config and data db config.
# ===========================================================================================================

1;
__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk membuka File.

=cut