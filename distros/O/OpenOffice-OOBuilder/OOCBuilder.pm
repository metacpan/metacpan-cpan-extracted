package OpenOffice::OOCBuilder;

# Copyright 2004, 2007 Stefan Loones
# More info can be found at http://www.maygill.com/oobuilder
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use 5.008;                   # lower versions not tested
use strict;
use warnings;
no warnings 'uninitialized';  # don't want this, because we use strict
use OpenOffice::OOBuilder;
our (@ISA);
@ISA=qw(OpenOffice::OOBuilder);

my $VERSION=sprintf("%d.%02d", q$Revision: 0.9 $ =~ /(\d+)\.(\d+)/);

my ($MAXC, $MAXR, $MAXSHEETS, @TYPES);
$MAXC=256;     # is column IV
$MAXR=32000;
$MAXSHEETS=64;
# - possible types ($TYPES[0] is default type)
@TYPES=('standard', 'text', 'float', 'formula');

# TODO push & pop cell locations (incl sheetnb) - to make formulas easier to construct
#      create tags for cell locations
#      cell-format ? (seems with numeric styles, not possible in cell directly)

# - Object constructor
#
sub new {
  my ($class, $self);
  $class=shift;
  $self=$class->SUPER::new('sxc');

  # - active data
  $self->{actsheet}=1;
  $self->{act}{1}{c}=1;       # {act}{sheetnb}{c}=
  $self->{act}{1}{r}=1;

  # - general data (parameters)
  $self->{cpars}{sheets}=1;
  $self->{cpars}{autoc}=0;
  $self->{cpars}{autor}=0;

  # - data
  $self->{cdata}    = undef;    # {cdata}{sheetnb}{}{}
  $self->{sheetname}= undef;    # {sheetname}{sheetnb}=name
  $self->{cstyle}   = undef;    # {cstyle}{sheetnb}{}{}
  $self->{colwidth} = undef;    # {colwidth}{sheetnb}{c}
  $self->{rowheight}= undef;    # {rowheight}{sheetnb}{r}

  # - defaults (specific ooc - see other defaults in parent class oooBuilder.pm)
  $self->{defcolwidth} = '0.8925inch';
# **  $self->{defrowheight} = '0.8925inch';

  return $self;
}   # - - End new (Object constructor)


sub add_sheet {
  my ($self);
  $self=shift;
  if ($self->{cpars}{sheets}<$MAXSHEETS) {
    ++$self->{cpars}{sheets};
  }
  1;
}

sub goto_sheet {
  my ($self, $sheet)=@_;
  if ($sheet > $self->{cpars}{sheets}) {
    $self->{actsheet}=$self->{cpars}{sheets};
  } elsif ($sheet < 1) {
    $self->{actsheet}=1;
  } else {
    $self->{actsheet}=$sheet;
  }
  1;
}

sub set_sheet_name {
  my ($self, $name, $sheet)=@_;
# TODO process name: check valid characters and length ?!
  if ($name) {
    $sheet=$self->{actsheet} if (! $sheet);
    if ($sheet>0 && $sheet <=$self->{cpars}{sheets}) {
      $self->{sheetname}{$sheet}=$name;
    }
  }
  1;
}

sub set_colwidth {
  my ($self, $c, $width)=@_;
  $c=$self->_check_column ($c);
# TODO do we need to check $width ?
  $self->{colwidth}{$self->{actsheet}}{$c}=$width;
  1;
}

sub set_rowheight {
  my ($self, $r, $height)=@_;
  $r=$self->_check_row ($r);
  $self->{rowheight}{$self->{actsheet}}{$r}=$height;
  1;
}

sub goto_xy {
  my ($self, $c, $r)=@_;
  $c=$self->_check_column ($c);
  $self->{act}{$self->{actsheet}}{c}=$c;
  $r=$self->_check_row ($r);
  $self->{act}{$self->{actsheet}}{r}=$r;
  1;
}

sub goto_cell {
  my ($self, $cell)=@_;
  $cell=uc($cell);
  $cell=~ s/^([A-Z]+)([0-9]+)/$1$2/;
  $self->goto_xy ($1, $2);
  1;
}

sub get_column {
  my $self=shift;
  return $self->_convert_column ($self->{act}{$self->{actsheet}}{c});
}

sub get_x {
  my $self=shift;
  return $self->{act}{$self->{actsheet}}{c};
}

sub get_row {
  my $self=shift;
  return $self->{act}{$self->{actsheet}}{r};
}

sub get_y {
  my $self=shift;
  return $self->{act}{$self->{actsheet}}{r};
}

sub get_xy {
  my $self=shift;
  return ($self->{act}{$self->{actsheet}}{c}, $self->{act}{$self->{actsheet}}{r});
}

sub get_cell_id {
  my $self=shift;
  my $cell=$self->_convert_column ($self->{act}{$self->{actsheet}}{c});
  return $cell . $self->{act}{$self->{actsheet}}{r};
}

# - PublicMethod: set_data : set_data in active sheet/cell, with active style
#     API: set_data ($data, $type, $format)
#                   $type && $format can be ommitted
#
sub set_data {
  my ($self, $data, $type, $format)=@_;
  return $self->set_data_sheet_xy($self->{actsheet},
                                  $self->{act}{$self->{actsheet}}{c},
                                  $self->{act}{$self->{actsheet}}{r},
                                  $data, $type, $format);
}

sub set_data_xy {
  my ($self, $c, $r, $data, $type, $format)=@_;
  return $self->set_data_sheet_xy($self->{actsheet}, $c, $r, $data, $type, $format);
}

sub set_data_sheet_xy {
  my ($self, $sheet, $c, $r, $data, $type, $format)=@_;

  # - check sheet
  if ($sheet != $self->{actsheet}) {
    $self->goto_sheet ($sheet);
    $sheet=$self->{actsheet};
  }

  # - check cell
  if ($c ne $self->{act}{$sheet}{c} || $r != $self->{act}{$sheet}{r}) {
    $self->goto_xy ($c, $r);
    $c=$self->{act}{$sheet}{c};
    $r=$self->{act}{$sheet}{r};
  }

  # - check type
  my ($ok);
  if ($type) {
    $type=lc($type);
    foreach (@TYPES) {
       if ($type eq $_) {
         $ok=1;
         last;
      }
    }
  }
  $type=$TYPES[0] if (! $ok);  # take $TYPES[0] as default type

  # - check format
# TODO

  # - check data
  $data=$self->encode_data ($data) if ($data);

  # - store (ATTENTION $r before $c because of the way we need to generate xml)
  $self->{cdata}{$sheet}{$r}{$c}{type}=$type;
  $self->{cdata}{$sheet}{$r}{$c}{format}=$format if ($format);
  $self->{cdata}{$sheet}{$r}{$c}{data}=$data;
  $self->{cdata}{$sheet}{$r}{$c}{style}=$self->{actstyle};
  $self->cell_update if ($self->{cpars}{autoc} || $self->{cpars}{autor});
  1;
}   # - - End set_data_sheet_xy

sub set_auto_xy {
  my ($self, $c, $r)=@_;
  $self->{cpars}{autoc}=$c;
  $self->{cpars}{autor}=$r;
  1;
}

sub get_auto_x {
  my $self=shift;
  return $self->{cpars}{autoc};
}

sub get_auto_y {
  my $self=shift;
  return $self->{cpars}{autor};
}

sub cell_update {
  my $self=shift;
  if ($self->{cpars}{autoc}) {
    if ($self->{cpars}{autoc}>0) {
      $self->move_cell('right',$self->{cpars}{autoc});
    } else {
      $self->move_cell('left',abs($self->{cpars}{autoc}));
    }
  }
  if ($self->{cpars}{autor}) {
    if ($self->{cpars}{autor}>0) {
      $self->move_cell('down',$self->{cpars}{autor});
    } else {
      $self->move_cell('up',abs($self->{cpars}{autor}));
    }
  }
  1;
}

sub move_cell {
  my ($self, $direction, $number)=@_;
  $number=1 if (! $number);
  $direction=lc($direction);
  if ($direction eq 'left') {
    $self->{act}{$self->{actsheet}}{c}-=$number;
  } elsif ($direction eq 'right') {
    $self->{act}{$self->{actsheet}}{c}+=$number;
  } elsif ($direction eq 'down') {
    $self->{act}{$self->{actsheet}}{r}+=$number;
  } elsif ($direction eq 'up') {
    $self->{act}{$self->{actsheet}}{r}-=$number;
  } else {
# TODO direction unknown

  }
  $self->_cell_check;
  1;
}

# - generate ooc specific, then call parent to complete generation
sub generate {
  my ($self, $tgtfile)=@_;

  my ($subGetMaxRange);
  $subGetMaxRange=sub {
    my ($hr, $max, @keys);
    $hr=shift;
    @keys=sort {$a <=> $b} (keys(%$hr));
    return (pop(@keys));
  };

  # - Build content.xml
  $self->{contentxml}=q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE office:document-content PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "office.dtd">
<office:document-content xmlns:office="http://openoffice.org/2000/office" xmlns:style="http://openoffice.org/2000/style" xmlns:text="http://openoffice.org/2000/text" xmlns:table="http://openoffice.org/2000/table" xmlns:draw="http://openoffice.org/2000/drawing" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:number="http://openoffice.org/2000/datastyle" xmlns:svg="http://www.w3.org/2000/svg" xmlns:chart="http://openoffice.org/2000/chart" xmlns:dr3d="http://openoffice.org/2000/dr3d" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="http://openoffice.org/2000/form" xmlns:script="http://openoffice.org/2000/script" office:class="spreadsheet" office:version="1.0">
<office:script/>
};

  # Styles will be done later, because they depend on the content

# TODO  $self->{rowheight}{$self->{actsheet}}{c}=$height;  still to implement


  # Beginning of document content
  my ($content);
  $content=q{<office:body>};

  my ($sheet, $sheetname, $c, $columns, $r, $rows, $type, $format, $data);
  my ($style, $stylexml);
  my (%cellstyleids, $cellmaxid, %cellstylexml);
  my (%colstyleids, $colmaxid, %colstylexml, $colwidth);
  my ($colid, $prevcolid, $width, $t);
  my (%rowstyleids, $rowmaxid, %rowstylexml);
  $cellmaxid=0;
  $colmaxid=$rowmaxid=1;
  $colstyleids{$self->{defcolwidth}}='co1';

  for (1 .. $self->{cpars}{sheets}) {
    $sheet=$_;
    if ($self->{sheetname}{$sheet}) {
      $sheetname=$self->{sheetname}{$sheet};
    } else {
      $sheetname="Sheet$sheet";
    }
    $content.=qq{<table:table table:name="$sheetname" table:style-name="ta1">};
    foreach $c (sort {$a <=> $b} keys(%{$self->{colwidth}{$sheet}})) {
      $width=$self->{colwidth}{$sheet}{$c};
      if (! $colstyleids{$width} && $width) {
        ++$colmaxid;
        $colstyleids{$width}=qq{co$colmaxid};
      }
    }
    if ($self->{colwidth}{$sheet}{1}) {
      $prevcolid=$colstyleids{$self->{colwidth}{$sheet}{1}};
    } else {
      $prevcolid='co1';
    }
    $t=1;
    for ($c=2;$c<=256;++$c) {
      if ($self->{colwidth}{$sheet}{$c}) {
        $colid=$colstyleids{$self->{colwidth}{$sheet}{$c}};
      } else {
        $colid='co1';
      }
      if ($colid eq $prevcolid) {
        ++$t;
      } else {
        if ($t>1) {
          $content.=qq{<table:table-column table:style-name="$prevcolid" table:number-columns-repeated="$t" table:default-cell-style-name="Default"/>};
          $t=1;
        } else {
          $content.=qq{<table:table-column table:style-name="$prevcolid" table:default-cell-style-name="Default"/>};
        }
        $prevcolid=$colid
      }
    }
    if ($t>1) {
      $content.=qq{<table:table-column table:style-name="$prevcolid" table:number-columns-repeated="$t" table:default-cell-style-name="Default"/>};
    } else {
      $content.=qq{<table:table-column table:style-name="$prevcolid" table:default-cell-style-name="Default"/>};
    }
    $rows=&$subGetMaxRange ($self->{cdata}{$sheet});
    for (1 .. $rows) {
      $r=$_;
# TODO row style ?
      $content.=q{<table:table-row table:style-name="ro1">};
      $columns=&$subGetMaxRange ($self->{cdata}{$sheet}{$r});
      for (1 .. $columns) {
        $c=$_;
        $type=$self->{cdata}{$sheet}{$r}{$c}{type};
        $format=$self->{cdata}{$sheet}{$r}{$c}{format};
        $data=$self->{cdata}{$sheet}{$r}{$c}{data};
        $style=$self->{cdata}{$sheet}{$r}{$c}{style};
        if ($style eq $self->{defstyle} || ! $style) {
          $stylexml='';
        } else {
          if (! exists($cellstyleids{$style})) {
            ++$cellmaxid;
            $cellstyleids{$style}=qq{ce$cellmaxid};
            $cellstylexml{$cellstyleids{$style}}=qq{ table:style-name="$cellstyleids{$style}"};
          }
          $stylexml=$cellstylexml{$cellstyleids{$style}};
        }
        if ($type eq 'standard' || $type eq 'text') {
          $content.=qq{<table:table-cell$stylexml><text:p>$data</text:p></table:table-cell>};
        } elsif ($type eq 'float') {
          $content.=
qq{<table:table-cell$stylexml table:value-type="float" table:value="$data">
<text:p>$data</text:p></table:table-cell>};
        } elsif ($type eq 'formula') {
          $content.=
qq{<table:table-cell$stylexml table:value-type="float" table:formula="$data" table:value="">
<text:p></text:p></table:table-cell>};
        } elsif ($type eq 'others') {
# TODO
        } else {
          $content.=q{<table:table-cell/>};
        }
      }
      $content.=q{</table:table-row>};
    }
    $content.=q{</table:table>};
  }

  # - Process used fonts and used cell styles
  my ($bold, $italic, $underline, $align, $txtcolor, $bgcolor, $font, $size);
  my ($defbold, $defitalic, $defunderline, $defalign, $deftxtcolor, $defbgcolor);
  my ($deffont, $defsize, %usedfonts, $xml, %stylexml);
  ($defbold, $defitalic, $defunderline, $defalign, $deftxtcolor, $defbgcolor,
   $deffont, $defsize)=split(/#/, $self->{defstyle});
  foreach $style (keys(%cellstyleids)) {
    ($bold, $italic, $underline, $align, $txtcolor, $bgcolor, $font, $size)=
      split(/#/, $style);
    $xml=
qq{<style:style style:name="$cellstyleids{$style}" style:family="table-cell" style:parent-style-name="Default">
<style:properties};
    if ($bgcolor ne $defbgcolor) {
      $xml.=qq{ fo:background-color="#$bgcolor"};
    }
    if ($align ne $defalign) {
      $align='end' if ($align eq 'right');
      $xml.=qq{ fo:text-align="$align" style:text-align-source="fix" fo:margin-left="0inch"};
    }
    if ($txtcolor ne $deftxtcolor) {
      $xml.=qq{ fo:color="#$txtcolor"};
    }
    if ($font ne $deffont) {
      $usedfonts{$font}=1;
      $xml.=qq{ style:font-name="$font"};
    }
    if ($size ne $defsize) {
      $xml.=q{ fo:font-size="} . $size . q{pt"}
    }
    if ($italic ne $defitalic) {
      if ($italic) {
        $xml.=q{ fo:font-style="italic"};
      } else {
        $xml.=q{ fo:font-style="normal"};
      }
    }
    if ($underline ne $defunderline) {
      if ($underline) {
        $xml.=q{ style:text-underline="single" style:text-underline-color="font-color"};
      } else {
        $xml.=q{ style:text-underline="normal"};
      }
    }
    if ($bold ne $defbold) {
      if ($bold) {
        $xml.=q{ fo:font-weight="bold"};
      } else {
        $xml.=q{ fo:font-weight="normal"};
      }
    }
    $xml.=q{/></style:style>};
    $stylexml{$cellstyleids{$style}}=$xml;
  }

  # - Fonts
  $usedfonts{$deffont}=1;
  $self->{contentxml}.=q{<office:font-decls>};
  foreach $font (sort(keys(%usedfonts))) {
    $self->{contentxml}.=$self->{availfonts}{$font};
  }
  $self->{contentxml}.=q{</office:font-decls>};

  # - col styles
  $self->{contentxml}.=qq{<office:automatic-styles>};
  foreach $width (keys(%colstyleids)) {
    $colstylexml{$colstyleids{$width}}=
      qq{<style:style style:name="$colstyleids{$width}" style:family="table-column">
<style:properties fo:break-before="auto" style:column-width="$width"/></style:style>};
  }
  foreach $colid (sort(keys(%colstylexml))) {
    $self->{contentxml}.=$colstylexml{$colid};
  }

# TODO look at row styles ?
# qq{
# <style:style style:name="ro1" style:family="table-row">
# <style:properties fo:break-before="auto"/></style:style>
# <style:style style:name="ta1" style:family="table" style:master-page-name="Default">
# <style:properties table:display="true"/></style:style>};

  # - cell styles
  foreach $style (sort(keys(%stylexml))) {
    $self->{contentxml}.=$stylexml{$style};
  }
  $self->{contentxml}.=qq{</office:automatic-styles>$content</office:body></office:document-content>};

  $self->SUPER::generate ($tgtfile);
  1;
}

# - * - PrivateMethods

sub _check_column {
  my ($self, $c)=@_;
  if ($c =~ /[A-Za-z]/) {
    # - convert to number
    my (@char, $char, $multi, $newx);
    $c=~ s/[^A-Za-z]//g;   # we don't want anything else when using letters
    @char=split(//,uc($c));
    $multi=1;
    $newx=0;
    while (@char) {
      $char=pop(@char);
      $newx+=$multi*(ord($char)-64);
      $multi*=26;
    }
    $c=$newx;
  }
  $c=1 if ($c<1);
  $c=$MAXC if ($c>$MAXC);
  return $c;
}

sub _convert_column {
  my ($self, $col)=@_;
  my $cell;
  while ($col>26) {
    my $div=int($col/26);
    $cell.=chr($div+64);
    $col-=$div*26;
  }
  $cell.=chr($col+64) if ($col>0);
  return $cell;
}

sub _check_row {
  my ($self, $r)=@_;
  $r=1 if ($r<1);
  $r=$MAXR if ($r>$MAXR);
  return $r;
}

sub _cell_check {
  my ($self);
  $self=shift;

  $self->{actsheet}=1 if ($self->{actsheet}<1);
  $self->{actsheet}=$MAXSHEETS if ($self->{actsheet}>$MAXSHEETS);
  my $sheet=$self->{actsheet};  # only for readability
  $self->{act}{$sheet}{c}=1 if ($self->{act}{$sheet}{c}<1);
  $self->{act}{$sheet}{r}=1 if ($self->{act}{$sheet}{r}<1);
  $self->{act}{$sheet}{c}=$MAXC if ($self->{act}{$sheet}{c}>$MAXC);
  $self->{act}{$sheet}{r}=$MAXR if ($self->{act}{$sheet}{r}>$MAXR);
  1;
}

1;

__END__

=head1 NAME

OpenOffice::OOCBuilder - Perl OO interface for creating
                         OpenOffice Spreadsheets

=head1 SYNOPSIS

  use OpenOffice::OOCBuilder;
  $sheet=OpenOffice::OOCBuilder->new();

  This constructor will call the constructor of OOBuilder.

=head1 DESCRIPTION

OOCBuilder is a Perl OO interface to create OpenOffice spreadsheets.
Documents can be created with multiple sheets, different styles,
cell types, formulas, column widths and so on.

=head1 METHODS

new

  Create a new spreadsheet object

add_sheet

  Add a new sheet within the document. Active sheet is not changed.
  You need to call goto_sheet (sheetnumber) to change the active
  sheet.

goto_sheet ($sheetnumber)

  Set $sheetnumber as active sheet.

set_sheet_name ($name, $sheetnumber)

  Set the name of the sheet. If $sheetnumber is ommitted (or 0), the
  name of the active sheet is set.

set_colwidth ($c, $width)

  Set the column width for the specified column ($c). The column can
  be a number or letter(s).

set_rowheight ($r, $height)

  Set the row height for the specified row ($r).

goto_xy ($c, $r)

  Set the active cell to ($c, $r). The column can be specified by
  number or letter(s).

goto_cell ($cell_id)

  Set the active cell to ($cell_id). This way you can use spreadsheet
  notations (i.e. A5 or BA401 and so on)

get_column

  Returns the active column in letters.

get_x

  Returns the active column as a number (starting at 1).

get_row

  Returns the row as a number (starting at 1)

get_y

  Returns the row as a number (starting at 1). Same as get_row.

get_xy

  Returns the column and row as two numbers in a list.

get_cell_id

  Returns the cell id in the form A1, AB564, and so on. Especially handy
  to create formulas. When you are at the start position, memorise the
  cell_id. See example2.pl in the examples directory.

set_data ($data, $type, $format)

  Set data in the active cell within the active sheet. If type is ommitted
  the standard type is taken.

set_data_xy ($c, $r, $data, $type, $format)

  Same as set_data, but now with column and row to set the data in. The
  column can be specified as a number or with letter(s).

set_data_sheet_xy ($sheet, $c, $r, $data, $type, $format)

  Same as set_data, but now with sheet, column and row to set the data in.
  The column can be specified as a number or with letter(s).

set_auto_xy ($x, $y)

  When entering data in a cell, we move to another cell if auto_x or y
  is set.
   X value: 0: no movement, negative: move left, positive: move right.
   Y valye: 0: no movement, negative: move up, positive: move down.

get_auto_x

  Returns the auto_x value.

get_auto_y

  Returns the auto_y value.

cell_update

  This method is called always when entering data in a cell. If auto_x
  or auto_y is set, if will move to another active cell. You can also
  use this method to move to another cell without entering data in the
  previous cell.

move_cell ($direction, $number)

  Move to cell in $direction where $direction is 'left', 'right', 'up' or
  'down'. If you ommit $number, the move will be one row or column.

generate ($tgtfile)

  Generates the sxc file. $tgtfile is the name of the target file without
  extension. If no name is supplied, the default name will be used,
  which is oo_doc. The target directory is '.', you can set this by
  calling the OOBuilder method set_builddir ($builddir).

Setting the style and meta data

  See OpenOffice::OOBuilder, because these methods are directly
  inherited from the base class.

=head1 EXAMPLES

Look at the examples directory supplied together with this distribution.

=head1 SEE ALSO

L<OpenOffice::OOBuilder.pm> - the base class

http://www.maygill.com/oobuilder

Bug reports and questions can be sent to <oobuilder(at)maygill.com>.
Attention: make sure the word <oobuilder> is in the subject or
body of your e-mail. Otherwhise your e-mail will be taken as
spam and will not be read.

=head1 AUTHOR

Stefan Loones

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Stefan Loones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
