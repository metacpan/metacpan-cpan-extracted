package Parse::USDA::NNDB;
{
    $Parse::USDA::NNDB::VERSION = '0.1';
}

# ABSTRACT: download and parse the latest USDA National Nutrient Database

use v5.10;
use strict;
use warnings;

use Text::CSV_XS;
use Archive::Zip qw/ :ERROR_CODES :CONSTANTS /;
use File::HomeDir;
use File::Spec;
use URI;
use File::Fetch;
use Log::Any;

# XXX file encoding
# TODO use the updates rather than a whole new db
# XXX option to download old releases?
# TODO progress bars... hardcode lines per file as they will only change once per year...

sub new {
    my ( $this, $base_dir ) = @_;
    my $class = ref( $this ) || $this;

    # TODO better cross-platform defaults
    if ( !defined $base_dir ) {
        $base_dir = File::Spec->catdir( File::HomeDir->my_home, '.cache/usda_nndb' );
    }

    # TODO set up base dir
    my $self = {
        base_dir => $base_dir,
        data_dir => File::Spec->catdir( $base_dir, 'sr24' ),
        data_uri => URI->new( 'http://www.ars.usda.gov/SP2UserFiles/Place/12354500/Data/SR24/dnload/sr24.ZIP' ),
        zip_file => File::Spec->catfile( $base_dir, 'sr24.ZIP' ),
        logger   => Log::Any->get_logger( category => __PACKAGE__ ),
    };

    bless $self, $class;
    return $self;
}

sub _get_file_path_for {
    my ( $self, $table ) = @_;

    my $file_path = File::Spec->catfile( $self->{data_dir}, $table . ".txt" );
    $self->{logger}->debug( "Using path [$file_path] for '$table'" );
    return $file_path;
}

sub tables {
    return qw/DATSRCLN FD_GROUP LANGUAL LANGDESC FOOTNOTE NUTR_DEF SRC_CD DATA_SRC DERIV_CD FOOD_DES NUT_DATA WEIGHT/;
}

sub get_columns_for {
    my ( $self, $table ) = @_;

    given ( $table ) {
        when ( /^FOOD_DES$/i ) {
            return [
                qw/NDB_No FdGrp_Cd Long_Desc Shrt_Desc ComName ManufacName Survey Ref_desc Refuse SciName N_Factor Pro_Factor Fat_Factor CHO_Factor/
            ];
        }
        when ( /^FD_GROUP$/i ) {
            return [qw/FdGrp_Cd FdGrp_Desc/];
        }
        when ( /^LANGUAL$/i ) {
            return [qw/NDB_No Factor_Code/];
        }
        when ( /^LANGDESC$/i ) {
            return [qw/Factor_Code Description/];
        }
        when ( /^NUT_DATA$/i ) {
            return [
                qw/NDB_No Nutr_No Nutr_Val Num_Data_Pts Std_Error Src_Cd Deriv_Cd Ref_NDB_No Add_Nutr_Mark Num_Studies Min Max DF Low_EB Up_EB Stat_cmt CC/
            ];

        }
        when ( /^NUTR_DEF$/i ) {
            return [qw(Nutr_No Units Tagname NutrDesc Num_Dec SR_Order)];
        }
        when ( /^SRC_CD$/i ) {
            return [qw(Src_Cd SrcCd_Desc)];
        }
        when ( /^DERIV_CD$/i ) {
            return [qw(Deriv_Cd Deriv_Desc)];
        }
        when ( /^WEIGHT$/i ) {
            return [qw(NDB_No Seq Amount Msre_Desc Gm_Wgt Num_Data_Pts Std_Dev)];
        }
        when ( /^FOOTNOTE$/i ) {
            return [qw(NDB_No Footnt_No Footnt_Typ Nutr_No Footnt_Txt)];
        }
        when ( /^DATSRCLN$/i ) {
            return [qw(NDB_No Nutr_No DataSrc_ID)];
        }
        when ( /^DATA_SRC$/i ) {
            return [qw(DataSrc_ID Authors Title Year Journal Vol_City Issue_State Start_Page End_Page)];
        }

#when ( /^ABBREV$/i ) {
#    return [
#        qw(NDB_No Shrt_Desc Water Energ_Kcal Protein Lipit_Tot Ash Carbonhydrt Fiber_TD Sugar_Tot Calcium Iron Magnesium Phosphorus Potassium Sodium Zinc Copper Manganese Selenium Vit_C Thiamin Riboflavin Niacin Panto_acid Vit_B6 Folate_Tot Folic_acid Food_Folate Folate_DFE Choline_total Vit_B12 Vit_A_IU Vit_A_RAE Retinol Alpha_Carot Beta_Carot Beta_Crypt Lycopene Lut_and_Zea Vit_E Vit_K FA_Sat FA_Mono FA_Poly Cholestrl GmWt_1 GmWt_Desc1 GmWt_2 GmWt_Desc2 Refuse_Pct)
#      ];
#}
        default {
            warn "Unknown table [$table] requested\n";
            return;
        }
    }
}

sub open_file {
    my ( $self, $table ) = @_;

    my $csv = Text::CSV_XS->new( {
            quote_char          => '~',
            sep_char            => '^',
            allow_loose_escapes => 1,
            empty_is_undef      => 1,
            binary              => 1,
    } );
    my $file_path = $self->_get_file_path_for( $table );

    if ( !-e $file_path ) {
        $self->_fetch_data
          or return 0;
    }

    open my $fh, '<:encoding(iso-8859-1)', $file_path;

    # TODO better error handling!
    if ( !$fh ) {
        my $err = $self->{logger}->crit( "Could not open [$file_path]: $!" );
        die;
    }

    my $column_names = $self->get_columns_for( $table )
      or return 0;

    $csv->column_names( $column_names );
    $self->{fh}  = $fh;
    $self->{csv} = $csv;

    return 1;
}

sub get_line {
    my $self = shift;

    if ( !defined $self->{fh} ) {
        die "No active filehandle. Did you call open_file first?\n";
    }
    if ( !defined $self->{csv} ) {
        die "No csv object. Did you call open_file first?\n";
    }

    my $row = $self->{csv}->getline_hr( $self->{fh} );

    if ( $self->{csv}->eof ) {
        $self->{logger}->debug( 'Closing file' );
        $self->{fh}->close;
        $self->{fh} = undef;
    }

    my ( $code, $str, $pos ) = $self->{csv}->error_diag;
    if ( $str && !$self->{csv}->eof ) {
        $self->{logger}->critf( "CSV parse error at pos %s: %s [%s]", $pos, $str, $self->{csv}->error_input );
        return;
    }

    return $row;
}

sub _fetch_data {
    my $self = shift;

    # does zip already exist?
    if ( -e $self->{zip_file} ) {
        if ( !$self->_extract_data ) {

            # failed to extract, file is corrupt? User should try again
            unlink $self->{zip_file}
              or die sprintf "Failed to remove cached file '%s': %s\n", $self->{zip_file}, $!;
        } else {
            return 1;
        }

    }

    my $ff = File::Fetch->new( uri => $self->{data_uri} );

    $self->{logger}->info( "Downloading " . $self->{data_uri} . " to " . $self->{base_dir} );
    my $file = $ff->fetch( to => $self->{base_dir} )
      or $self->{logger}->warn( $ff->error );

    $self->{zip_file} = $file;    # should have been the same anyway
    $self->{logger}->info( "Saved data to $file" );
    $self->_extract_data;

    return 1;
}

sub _extract_data {
    my $self = shift;

    my $zip = Archive::Zip->new;

    unless ( $zip->read( $self->{zip_file} ) == AZ_OK ) {
        $self->{logger}->error( 'Read error' );
        return 0;
    }

    $zip->extractTree( undef, $self->{data_dir} . "/" );

    return 1;
}

1;

=pod

=head1 NAME

Parse::USDA::NNDB - download and parse the latest USDA National Nutrient Database

=head1 VERSION

version 0.1

=head1 SYNOPSIS

  use Parse::USDA::NNDB;
  my $usda = Parse::USDA::NNDB->new($optional_cache_dir);
  $usda->open_file( 'FD_GROUP' );
  while (my $fg = $usda->getline) {
      printf "ID: %s  DESC: %s\n", $fg->{NDB_No}, $fg->{Shrt_Desc};
  }

=head1 DESCRIPTION

Parse::USDA::NNDB is for parsing the nutrient data files made available by the
USDA in ASCII format. If the files are not available, they will be automatically 
retrieved and extracted for you.

=head1 METHODS

=over

=item new($basedir)

Creates a new Parse::USDA::NNDB object. Takes one optional argument, a path
to the dir which contains the datafiles to be parsed.

=item B<open_file($table)>

Call with the case-insensitive name of the file, without extension, to open.
You must call this before B<get_line>.

Returns true on success.

=item B<get_line>

After B<open_file>, keep calling this to get the next line. Each line is a
hashref (see USDA docs for their meanings).

Returns undef when the file is finished or if something goes wrong.

=item B<tables>

Returns a list of all the known tables/filenames.

=item B<get_columns_for($table)>

Returns a list of the keys used in this file.

=back

=head1 SEE ALSO

L<USDA documentation|http://www.ars.usda.gov/Services/docs.htm?docid=8964>

=head1 AUTHOR

Ioan Rogers <ioan.rogers@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__
