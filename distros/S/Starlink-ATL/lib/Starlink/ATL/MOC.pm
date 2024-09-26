=head1 NAME

Starlink::ATL::MOC - Tools for MOC using AST.

=head1 SYNOPSIS

    use Starlink::ATL::MOC qw/write_moc_fits/;

    my $moc = read_moc_fits($filename);
    write_moc_fits($moc, $new_filename);

=head1 DESCRIPTION

This module contains utility subroutines for working
with MOC information using AST.

=cut

package Starlink::ATL::MOC;

use strict;

use Exporter;
use Astro::FITS::CFITSIO;
use Starlink::AST;

our $VERSION = '0.06';
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/read_moc_fits write_moc_fits/;

=head1 SUBROUTINES

=over 4

=item B<read_moc_fits>

Read a MOC from a FITS file.

    my $moc = read_moc_fits($filename, %options);

Options:

=over 4

=item moc

Existing C<Starlink::AST::Moc> object into which to read.

=item max_order

If C<moc> not specified, the maximum order for the newly
constructed object.  Must be between 0 and 27.

=item mode

C<Starlink::AST::Region> combination mode.

=item negate

Whether to negate the addition to the MOC.

=back

=cut

sub read_moc_fits {
    my $filename = shift;
    my %opt = @_;

    my $mode = (exists $opt{'mode'}) ? $opt{'mode'} : Starlink::AST::Region::AST__OR();
    my $negate = (exists $opt{'negate'}) ? $opt{'negate'} : 0;

    my $moc;
    if (exists $opt{'moc'}) {
        $moc = $opt{'moc'};
    }
    else {
        my $options = '';
        if (exists $opt{'max_order'}) {
            my $max_order = $opt{'max_order'};
            die 'Maximum order must be between 0 and 27'
                if $max_order < 0 or $max_order > 27;
            $options = sprintf 'MaxOrder=%i', $max_order;
        }
        $moc = Starlink::AST::Moc->new($options);
    }

    # MOC FITS reading routine based on similar code in GAIA.

    my $status = 0;
    my $fptr = Astro::FITS::CFITSIO::open_file(
        $filename, Astro::FITS::CFITSIO::READONLY(), $status);
    die 'Error opening FITS file' if $status;

    $fptr->get_num_hdus(my $nhdu, $status);
    die 'Error getting number of HDUs' if $status;

    # Assume simple MOC file: only one extension which is the MOC.
    die 'Unexpected number of HDUs' unless $nhdu = 2;
    my $ihdu = 2;

    $fptr->movabs_hdu($ihdu, my $hdutype, $status);
    die 'Error selecting HDU' if $status;
    die 'HDU is not a binary table'
        unless $hdutype == Astro::FITS::CFITSIO::BINARY_TBL();

    $fptr->read_key(Astro::FITS::CFITSIO::TINT(),
        'MOCORDER', my $mocorder, my $mocorder_comment, $status);
    die 'Error reading MOCORDER' if $status;

    $fptr->read_key(Astro::FITS::CFITSIO::TINT(),
        'NAXIS2', my $moclen, my $moclen_comment, $status);
    die 'Error reading NAXIS2' if $status;

    $fptr->read_key(Astro::FITS::CFITSIO::TSTRING(),
        'TFORM1', my $tform1, my $tform1_comment, $status);
    die 'Error reading TFORM1' if $status;

    my @data;
    if ($tform1 =~ /^1?J$/) {
        $fptr->read_col_lng(1, 1, 1, $moclen, 0, \@data, my $anynull, $status);
    }
    elsif ($tform1 =~ /^1?K$/) {
        $fptr->read_col_lnglng(1, 1, 1, $moclen, 0, \@data, my $anynull, $status);
    }
    else {
        die 'Unrecognized TFORM1';
    }
    die 'Error reading MOC data' if $status;

    $moc->AddMocData($mode, $negate, $mocorder, \@data);

    $fptr->close_file($status);
    die 'Error closing FITS file' if $status;

    return $moc;
}

=item B<write_moc_fits>

Write a MOC to a FITS file.

    write_moc_fits($moc, $filename, %options);

Options:

=over 4

=item type

MOC type ("IMAGE" or "CATALOG").

=back

=cut

sub write_moc_fits {
    my $moc = shift;
    my $filename = shift;
    my %opt = @_;

    # MOC FITS writing routine based on "atl_mocft.f".

    my $data = $moc->GetMocData();
    my $fc = $moc->GetMocHeader();
    my $status = 0;
    my $fptr = Astro::FITS::CFITSIO::create_file($filename, $status);
    die 'Error opening FITS file' if $status;

    $fptr->insert_key_log('SIMPLE', 1, '', $status);
    $fptr->insert_key_lng('BITPIX', 8, '', $status);
    $fptr->insert_key_lng('NAXIS', 0, '', $status);
    $fptr->insert_key_log('EXTEND', 1, '', $status);
    die 'Error writing primary headers' if $status;

    $fptr->create_hdu($status);
    die 'Error creating HDU' if $status;

    $fc->Clear('Card');
    for (;;) {
        last unless $fc->FindFits('%f', my $card, 1);
        $fptr->write_record($card, $status);
    }
    die 'Error writing MOC headers' if $status;

    if ((exists $opt{'type'}) and (defined $opt{'type'})) {
        my $type = uc $opt{'type'};
        die 'MOC type must be IMAGE or CATALOG'
            unless (($type eq 'IMAGE') or ($type eq 'CATALOG'));
        $fptr->update_key_str(
            'MOCTYPE', $type, 'Source type (IMAGE or CATALOG)', $status);
        die 'Error writing MOCTYPE header' if $status;
    }

    my $type = $moc->GetI('MocType');
    if ($type == 4) {
        $fptr->write_col_lng(1, 1, 1, (scalar @$data), $data, $status);
    }
    elsif ($type == 8) {
        $fptr->write_col_lnglng(1, 1, 1, (scalar @$data), $data, $status);
    }
    else {
        die 'MOC type not recognized';
    }
    die 'Error writing MOC data' if $status;

    $fptr->close_file($status);
    die 'Error closing FITS file' if $status;
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2019-2022 East Asian Observatory
All Rights Reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
