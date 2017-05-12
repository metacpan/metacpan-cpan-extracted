package Parse::Stata::DtaReader;

=head1 NAME

Parse::Stata::DtaReader - read Stata 8 and Stata 10 .dta files

=head1 OVERVIEW

This module reads Stata 8 and Stata 10 .dta files.

The API is object oriented: create a new instance of
Parse::Stata::DtaReader by providing a handle to the .dta file, and then
use attributes and methods of that object to obtain the data.

=head1 SYNOPSIS

Look at the source code of dta2csv and dta2sql for working code examples.

=head2 Open a .dta file

    open my $fileHandle, '<', 'test.dta';
    
    my $dta = new Parse::Stata::DtaReader($fileHandle);

=head2 Retrieve general information

Number of variables and observations:

    print "$dta->{nvar} variables; $dta->{nobs} observations\n";

Variable names and types:

    print join( ',', @{ $dta->{varlist} } ) . "\n";
    
    for (my $i = 0; $i < $dta->{nvar}; ++$i) {
        print "$dta->{varlist}[$i] has SQL type " .
            $dta->sqlType($i) . "\n";
    }

=head2 Retrieve data

    while ( my @a = $dta->readRow ) {
        print join( ',', @a ) . "\n";
    }

=head1 SOURCES

Stata .dta format specification from:
    http://www.stata.com/help.cgi?dta_114
    http://www.stata.com/help.cgi?dta_113

=head1 BUGS

It works for me, but has not been fully tested.

All Stata missing values will be converted into a perl undef,
losing the information about the type of missing value.

=head1 NO WARRANTY

This code comes with ABSOLUTELY NO WARRANTY of any kind.

=head1 AUTHOR

Copyright 2007, 2008, 2014 Reckon LLP and Franck Latrémolière.
L<http://www.reckon.co.uk/staff/franck/>

=head1 LICENCE

This is free software; you can redistribute it and/or modify it under the same terms as Perl.

=cut

use warnings;
use strict;
use Carp;

BEGIN {

    $Parse::Stata::DtaReader::VERSION = '0.711';

# test for float endianness using little-endian 33 33 3b f3, which is a float code for 1.4

    my $testFloat = unpack( 'f', pack( 'h*', 'f33b3333' ) );
    $Parse::Stata::DtaReader::byteOrder = 1    # big-endian
      if ( 2.0 * $testFloat > 2.7 && 2.0 * $testFloat < 2.9 );
    $testFloat = unpack( 'f', pack( 'h*', '33333bf3' ) );
    $Parse::Stata::DtaReader::byteOrder = 2    # little-endian
      if ( 2.0 * $testFloat > 2.7 && 2.0 * $testFloat < 2.9 );
    warn "Unable to detect endianness of float storage on your machine"
      unless $Parse::Stata::DtaReader::byteOrder;

}

sub new($$) {
    my $className  = shift;
    my $fileHandle = shift;
    my $self       = { fh => $fileHandle };
    bless $self, $className;
    $self->readHeader;
    if (    $self->{ds_format}
        and $self->{ds_format} == 114 || $self->{ds_format} == 113 )
    {
        $self->readDescriptors;
        $self->readVariableLabels;
        $self->discardExpansionFields;
        $self->prepareDataReader;
    }
    return $self;
}

sub readHeader($) {
    my $self = shift;
    local $_;
    unless ( read $self->{fh}, $_, 4 ) {
        carp "Cannot read any data";
        return;
    }
    ( $self->{ds_format}, $self->{byteorder}, $self->{filetype}, $_ ) =
      unpack( 'CCCC', $_ );
    read $self->{fh}, $_, 105;
    ( $self->{nvar}, $self->{nobs}, $self->{data_label}, $self->{time_stamp} )
      = unpack( ( $self->{byteorder} == 2 ? 'vV' : 'nN' ) . 'A81A18', $_ );
    $self->{data_label} =~ s/\x00.*$//s;
    $self->{time_stamp} =~ s/\x00.*$//s;
}

sub readDescriptors($) {
    my $self = shift;
    my $nv   = $self->{nvar};
    local $_;
    read $self->{fh}, $_, $nv;
    $self->{typlist} = [ unpack( 'C' x $nv, $_ ) ];
    read $self->{fh}, $_, $nv * 33;
    $self->{varlist} = [ map { s/\x00.*$//s; $_ } unpack( 'A33' x $nv, $_ ) ];
    read $self->{fh}, $_, $nv * 2 + 2;
    $self->{srtlist} =
      [ unpack( ( $self->{byteorder} == 2 ? 'v' : 'n' ) x ( 1 + $nv ), $_ ) ];
    my $fmtSize = $self->{ds_format} == 113 ? 12 : 49;
    read $self->{fh}, $_, $nv * $fmtSize;
    $self->{fmtlist} =
      [ map { s/\x00.*$//s; $_ } unpack( ( 'A' . $fmtSize ) x $nv, $_ ) ];
    read $self->{fh}, $_, $nv * 33;
    $self->{lbllist} = [ map { s/\x00.*$//s; $_ } unpack( 'A33' x $nv, $_ ) ];
}

sub readVariableLabels($) {
    my $self = shift;
    my $nv   = $self->{nvar};
    local $_;
    read $self->{fh}, $_, $nv * 81;
    $self->{variableLabelList} =
      [ map { s/\x00.*$//s; $_ } unpack( 'A81' x $nv, $_ ) ];
}

sub discardExpansionFields($) {
    my $self = shift;
    local $_;
    my $size = -1;
    while ($size) {
        read $self->{fh}, $_, 5;
        $size =
          unpack( $self->{byteorder} == 2 ? 'V' : 'N', substr( $_, 1, 4 ) );
        read $self->{fh}, $_, $size if $size > 0;
    }
}

sub prepareDataReader($) {
    my $self = shift;
    $self->{nextRow}    = 1;
    $self->{rowPattern} = '';
    $self->{rowSize}    = 0;
    for my $vt ( @{ $self->{typlist} } ) {
        if ( $vt == 255 ) {
            $self->{rowSize} += 8;
            $self->{rowPattern} .=
              $self->{byteorder} == $Parse::Stata::DtaReader::byteOrder
              ? 'd'
              : 'H16';
        }
        elsif ( $vt == 254 ) {
            $self->{rowSize} += 4;
            $self->{rowPattern} .=
              $self->{byteorder} == $Parse::Stata::DtaReader::byteOrder
              ? 'f'
              : 'H8';
        }
        elsif ( $vt == 253 ) {
            $self->{rowSize} += 4;
            $self->{rowPattern} .= $self->{byteorder} == 2 ? 'V' : 'N';
        }
        elsif ( $vt == 252 ) {
            $self->{rowSize} += 2;
            $self->{rowPattern} .= $self->{byteorder} == 2 ? 'v' : 'n';
        }
        elsif ( $vt == 251 ) {
            $self->{rowSize} += 1;
            $self->{rowPattern} .= 'c';
        }
        elsif ( $vt < 245 ) {
            $self->{rowSize} += $vt;
            $self->{rowPattern} .= 'A' . $vt;
        }
    }
}

sub hasNext($) {
    my $self = shift;
    return $self->{nextRow} > $self->{nobs} ? undef : $self->{nextRow};
}

sub readRow($) {
    my $self = shift;
    local $_;
    return () unless $self->{rowSize} == read $self->{fh}, $_, $self->{rowSize};
    $self->{nextRow}++;
    my @a = unpack( $self->{rowPattern}, $_ );
    for ( my $i = 0 ; $i < @a ; $i++ ) {
        my $t = $self->{typlist}->[$i];
        if ( defined $a[$i] ) {
            if ( $self->{byteorder} != $Parse::Stata::DtaReader::byteOrder ) {
                if ( $t == 254 ) {
                    $a[$i] =
                      unpack( 'f',
                        pack( 'N', ( unpack( 'V', pack( 'H8', $a[$i] ) ) ) ) );
                }
                elsif ( $t == 255 ) {
                    $a[$i] = unpack(
                        'd',
                        pack( 'NN',
                            reverse( unpack( 'VV', pack( 'H16', $a[$i] ) ) ) )
                    );
                }
            }
            if ( $t < 245 ) {
                $a[$i] =~ s/\x00.*$//s;
            }
            elsif ( $t == 251 ) {
                undef $a[$i] if $a[$i] > 100 && $a[$i] < 128;
            }
            elsif ( $t == 252 ) {
                $a[$i] = unpack 's', pack 'S', $a[$i];
                undef $a[$i] if $a[$i] > 32740 && $a[$i] < 32768;
            }
            elsif ( $t == 253 ) {
                $a[$i] = unpack 'l', pack 'L', $a[$i];
                undef $a[$i] if $a[$i] > 2147483620 && $a[$i] < 2147483648;
            }
            elsif ( $t == 254 ) {
                undef $a[$i]
                  if defined $a[$i] and $a[$i] > 1.701e38 || $a[$i] < -1.701e38;
            }
            elsif ( $t == 255 ) {
                undef $a[$i]
                  if defined $a[$i]
                  and $a[$i] > 8.988e307 || $a[$i] < -1.798e308;
            }
        }
    }
    return @a;
}

sub _sqlType($) {
    return 'DOUBLE'      if $_[0] == 255;
    return 'FLOAT'       if $_[0] == 254;
    return 'INT'         if $_[0] == 253;
    return 'SMALLINT'    if $_[0] == 252;
    return 'TINYINT'     if $_[0] == 251;
    return "CHAR($_[0])" if $_[0] > 0 && $_[0] < 245;
    return undef;
}

sub sqlType($$) {
    my ( $self, $varNumber ) = @_;
    return _sqlType( $self->{typlist}[$varNumber] ) if defined $varNumber;
    return map { _sqlType($_); } @{ $self->{typlist} };
}

1;
