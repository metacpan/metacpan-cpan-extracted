package SimpleXlsx;

use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES );
use XML::Simple;
use File::Basename;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = ( 'parse' );

our $VERSION = '0.05';

our $zip;

# Preloaded methods go here.

sub new {
  my $package = shift;
  
  $zip = Archive::Zip->new();
  return bless({}, $package);
}

sub getValues {
  my(@zStrings) = $zip->membersMatching('^xl/sharedStrings');
  
  if ($#zStrings > 0) {
    warn "Error: Multiple shared strings are not [yet] supported\n";
  }
  
  my($xml) = new XML::Simple;
  my($sstrings) = $zStrings[0];
  $sstrings = $sstrings->contents();
  my($tstrings) = $xml->XMLin($sstrings);
  
  my(@strings);
  for my $idx (0 .. $#{$tstrings->{'si'}}) {
    push @strings, $tstrings->{'si'}->[$idx]->{'t'};
  }
  
  return @strings;
}

sub getWorksheets {
  return $zip->membersMatching('^xl/worksheets');
}

sub getStyles {
  my(@zStyles) = $zip->membersMatching('^xl/styles');
  my($data) = $zStyles[0]->contents();
  
  my($xml) = new XML::Simple;
  $data = $xml->XMLin($data);
  
  my(@cellFormats);
  my(%fonts);
  my(%borders);
  
  my($xcellFormats) = $data->{'cellXfs'}->{'xf'};
  my($xfonts) = $data->{'fonts'}->{'font'};
  my($xborders) = $data->{'borders'}->{'border'};
  
  my($idx) = 0;
  if (ref($xfonts)) {
    for my $ind (0 .. $#{$xfonts}) {
      $fonts{$idx} = {
        'Name'    => $xfonts->[$ind]->{'name'}->{'val'},
        'Size'    => $xfonts->[$ind]->{'sz'}->{'val'},
        'Bold'    => defined $xfonts->[$ind]->{'b'} ? '1' : '0'
      };
    
      $idx++;
    }
  }
  
  $idx = 0;
  for my $ind (0 .. $#{$xborders}) {
    $borders{$idx} = {
      'Left'      => {
        'Color' => defined $xborders->[$ind]->{'left'}->{'color'}->{'indexed'} ? $xborders->[$ind]->{'left'}->{'color'}->{'indexed'} : '',
        'Style' => defined $xborders->[$ind]->{'left'}->{'style'} ? $xborders->[$ind]->{'left'}->{'style'} : ''
      },
      'Right'     => {
        'Color' => defined $xborders->[$ind]->{'right'}->{'color'}->{'indexed'} ? $xborders->[$ind]->{'right'}->{'color'}->{'indexed'} : '',
        'Style' => defined $xborders->[$ind]->{'right'}->{'style'} ? $xborders->[$ind]->{'right'}->{'style'} : ''
      },
      'Top'       => {
        'Color' => defined $xborders->[$ind]->{'top'}->{'color'}->{'indexed'} ? $xborders->[$ind]->{'top'}->{'color'}->{'indexed'} : '',
        'Style' => defined $xborders->[$ind]->{'top'}->{'style'} ? $xborders->[$ind]->{'left'}->{'top'} : ''
      },
      'Bottom'    => {
        'Color' => defined $xborders->[$ind]->{'bottom'}->{'color'}->{'indexed'} ? $xborders->[$ind]->{'bottom'}->{'color'}->{'indexed'} : '',
        'Style' => defined $xborders->[$ind]->{'bottom'}->{'style'} ? $xborders->[$ind]->{'bottom'}->{'style'} : ''
      },
      'Diagonal'  => {
        'Color' => defined $xborders->[$ind]->{'diagonal'}->{'color'}->{'indexed'} ? $xborders->[$ind]->{'diagonal'}->{'color'}->{'indexed'} : '',
        'Style' => defined $xborders->[$ind]->{'diagonal'}->{'style'} ? $xborders->[$ind]->{'diagonal'}->{'style'} : ''
      }
    };
    
    $idx++;
  }
  
  $idx = 0;
  for my $ind (0 .. $#{$xcellFormats}) {
    my($bix) = $xcellFormats->[$ind]->{'borderId'};
    push @cellFormats, {
      'fillId'    => $xcellFormats->[$ind]->{'fillId'},
      'Font'      => $fonts{$xcellFormats->[$ind]->{'fontId'}},
      'xfId'      => $xcellFormats->[$ind]->{'xfId'},
      'numFmtId'  => $xcellFormats->[$ind]->{'numFmtId'},
      'Border'    => $borders{$bix}
    };
    
    $idx++;
  }
  
  return \@cellFormats;
}

sub parse {
  my($self, $file) = @_;
  
  my($ret) = $zip->read($file);
  unless ($ret == AZ_OK) {
    warn "Unable to read file \"$file\" ($!)\n";
    return undef;
  }
  
  # For now we are only interested in worksheets and the shared strings
  my(@zWorksheets) = $self->getWorksheets();
  my(@strings) = $self->getValues();
  my($styles) = $self->getStyles();
  my(%worksheets);
  my(@sheetNames);
  
  $worksheets{'Worksheets'} = [];
  
  $worksheets{'Total Worksheets'} = ($#zWorksheets + 1);
  for my $file (@zWorksheets) {
    my(%worksheet);
    my($contents) = $file->contents();
    my($name) = basename($file->fileName());
    $name =~ s/\.xml$//;
    
    my($xml) = new XML::Simple;
    my($data) = $xml->XMLin($contents);
    
    my($sData) = $data->{'sheetData'}->{'row'};
    my($sMerge) = $data->{'mergeCells'}->{'mergeCell'};
    
    my(%merge);
    for my $mc (@{$sMerge}) {
      my($from, $to) = split(':', $mc->{'ref'});
      
      $from =~ /([a-zA-Z]+)([0-9]+)/;
      my($col1, $row1) = ($1, $2);
      
      $to =~ /([a-zA-Z]+)([0-9]+)/;
      my($col2, $row2) = ($1, $2);
      
      $merge{$row1} = {
        'From' => { 'Row' => $row1, 'Column' => $col1 },
        'To' => { 'Row' => $row2, 'Column' => $col2 }
      };
    }
    
    my(@tcol);
    for my $col (0 .. $#{$sData->[0]->{'c'}}) {
      push @tcol, $sData->[0]->{'c'}->[$col]->{'r'};
    }
    $worksheet{'Columns'} = \@tcol;
    
    my(@trow);
    my(%tdata);
    for my $row (0 .. $#{$sData}) {
      my($cols) = $sData->[$row]->{'c'};
      
      my(@rdata);
      my(@sdata);
      for my $col (0 .. $#{$cols}) {
        if (!defined $cols->[$col]->{'v'}) {
          push @rdata, '';
        }
        else {
          if (defined $cols->[$col]->{'t'}) {
            push @rdata, ($cols->[$col]->{'t'} eq 's' ?  $strings[$cols->[$col]->{'v'}] : $cols->[$col]->{'v'});
          }
        }

        if (defined $styles->[$cols->[$col]->{'s'}]) {
          push @sdata, $styles->[$cols->[$col]->{'s'}];
        }
      }

      if (defined $sData->[$row]->{'r'}) {
        push @trow, $sData->[$row]->{'r'};
        $tdata{$sData->[$row]->{'r'}}{'Data'} = \@rdata;
        $tdata{$sData->[$row]->{'r'}}{'Style'} = \@sdata;
      }
    }
    
    $worksheet{'Rows'} = \@trow;
    $worksheet{'Data'} = \%tdata;
    $worksheet{'Merge'} = \%merge;
    
    $worksheets{$name} = \%worksheet;
    
    push @sheetNames, $name;
  }
  
  $worksheets{'Worksheets'} = \@sheetNames;
  
  return \%worksheets;
}

1;
__END__

=head1 NAME

SimpleXlsx - Perl extension to read data from a Microsoft Excel 2007 XLSX file

=head1 SYNOPSIS

  use SimpleXlsx;
  
  my($xlsx) = SimpleXlsx->new();
  my($worksheets) = $xlsx->parse('/path/to/workbook.xlsx');

=head1 DESCRIPTION

SimpleXlsx is a rudamentary extension to allow parsing information stored in
Microsoft Excel XLSX spreadsheets.

=head2 EXPORT

None by default.

=head1 SEE ALSO

This module is intended as a quick method of extracting the raw data from
the XLSX file format. This module uses Archive::Zip to extract the contents
of the XLSX file and XML::Simple for parsing the contents.

=head1 AUTHOR

Joe Estock, E<lt>jestock@blendernet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Joe Estock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
