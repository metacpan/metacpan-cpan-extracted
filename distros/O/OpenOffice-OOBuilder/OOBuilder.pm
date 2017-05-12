package OpenOffice::OOBuilder;

# Copyright 2004, 2007 Stefan Loones
# More info can be found at http://www.maygill.com/oobuilder
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use 5.008;                   # lower versions not tested
use strict;
use warnings;
no warnings 'uninitialized';  # don't want this, because we use strict
use Archive::Zip;

my ($VERSION, %COLORS, $MINFONTSIZE, $MAXFONTSIZE);
$VERSION=sprintf("%d.%02d", q$Revision: 0.9 $ =~ /(\d+)\.(\d+)/);
%COLORS=('red' => 'ff0000', 'green' => '00ff00', 'blue' => '0000ff',
         'white' => 'ffffff', 'black' => '000000');
$MINFONTSIZE=6;
$MAXFONTSIZE=96;

# - Object constructor
#
sub new {
  my ($proto, $class, $self, $doctype);
  $proto=shift;
  $class=ref($proto) || $proto;
  $doctype=shift;
  $doctype='sxw' if (! $doctype);
  $self={};
  $self->{oooType}    = $doctype;
  $self->{contentxml} = undef;
  $self->{builddir}   = '.';
  $self->{tgt_file}   = 'oo_doc';
  $self->{meta}       = undef;
  $self->{log}        = 0;

  # - Init available fonts
  $self->{availfonts}{Arial}=q{<style:font-decl style:name="Arial" fo:font-family="Arial" style:font-family-generic="swiss" style:font-pitch="variable"/>};
  $self->{availfonts}{'Bitstream Vera Sans'}=q{<style:font-decl style:name="Bitstream Vera Sans" fo:font-family="\&apos;Bitstream Vera Sans\&apos;" style:font-pitch="variable"/>};
  $self->{availfonts}{'Bitstream Vera Serif'}=q{<style:font-decl style:name="Bitstream Vera Serif" fo:font-family="\&apos;Bitstream Vera Serif\&apos;" style:font-family-generic="roman" style:font-pitch="variable"/>};
  $self->{availfonts}{Bookman}=q{<style:font-decl style:name="Bookman" fo:font-family="Bookman" style:font-pitch="variable"/>};
  $self->{availfonts}{Courier}=q{<style:font-decl style:name="Courier" fo:font-family="Courier" style:font-family-generic="modern" style:font-pitch="fixed"/>};
  $self->{availfonts}{'Courier 10 Pitch'}=q{<style:font-decl style:name="Courier 10 Pitch" fo:font-family="\&apos;Courier 10 Pitch\&apos;" style:font-pitch="fixed"/>};
  $self->{availfonts}{Helvetica}=q{<style:font-decl style:name="Helvetica" fo:font-family="Helvetica" style:font-family-generic="swiss" style:font-pitch="variable"/>};
  $self->{availfonts}{Lucidabright}=q{<style:font-decl style:name="Lucidabright" fo:font-family="Lucidabright" style:font-pitch="variable"/>};
  $self->{availfonts}{Lucidasans}=q{<style:font-decl style:name="Lucidasans" fo:font-family="Lucidasans" style:font-pitch="variable"/>};
  $self->{availfonts}{'Lucida Sans Unicode'}=q{<style:font-decl style:name="Lucida Sans Unicode" fo:font-family="\&apos;Lucida Sans Unicode\&apos;" style:font-pitch="variable"/>};
  $self->{availfonts}{Lucidatypewriter}=q{<style:font-decl style:name="Lucidatypewriter" fo:font-family="Lucidatypewriter" style:font-pitch="fixed"/>};
  $self->{availfonts}{'Luxi Mono'}=q{<style:font-decl style:name="Luxi Mono" fo:font-family="\&apos;Luxi Mono\&apos;" style:font-pitch="fixed" style:font-charset="x-symbol"/>};
  $self->{availfonts}{'Luxi Sans'}=q{<style:font-decl style:name="Luxi Sans" fo:font-family="\&apos;Luxi Sans\&apos;" style:font-pitch="variable" style:font-charset="x-symbol"/>};
  $self->{availfonts}{'Luxi Serif'}=q{<style:font-decl style:name="Luxi Serif" fo:font-family="\&apos;Luxi Serif\&apos;" style:font-pitch="variable" style:font-charset="x-symbol"/>};
  $self->{availfonts}{Symbol}=q{<style:font-decl style:name="Symbol" fo:font-family="Symbol" style:font-pitch="variable" style:font-charset="x-symbol"/>};
  $self->{availfonts}{Tahoma}=q{<style:font-decl style:name="Tahoma" fo:font-family="Tahoma" style:font-pitch="variable"/>};
  $self->{availfonts}{Times}=q{<style:font-decl style:name="Times" fo:font-family="Times" style:font-family-generic="roman" style:font-pitch="variable"/>};
  $self->{availfonts}{'Times New Roman'}=q{<style:font-decl style:name="Times New Roman" fo:font-family="\&apos;Times New Roman\&apos;" style:font-family-generic="roman" style:font-pitch="variable"/>};
  $self->{availfonts}{Utopia}=q{<style:font-decl style:name="Utopia" fo:font-family="Utopia" style:font-family-generic="roman" style:font-pitch="variable"/>};
  $self->{availfonts}{'Zapf Chancery'}=q{<style:font-decl style:name="Zapf Chancery" fo:font-family="\&apos;Zapf Chancery\&apos;" style:font-pitch="variable"/>};
  $self->{availfonts}{'Zapf Dingbats'}=q{<style:font-decl style:name="Zapf Dingbats" fo:font-family="\&apos;Zapf Dingbats\&apos;" style:font-pitch="variable" style:font-charset="x-symbol"/>};

  $self->{style}{bold}     = 0;
  $self->{style}{italic}   = 0;
  $self->{style}{underline}= 0;
  $self->{style}{align}    = 'left';
  $self->{style}{txtcolor} = '000000';
  $self->{style}{bgcolor}  = 'ffffff';
  $self->{style}{font}     = 'Luxi Sans';
  $self->{style}{size}     = '10';

  $self->{actstyle}=join('#',($self->{style}{bold}, $self->{style}{italic},
                         $self->{style}{underline},$self->{style}{align},
                         $self->{style}{txtcolor},$self->{style}{bgcolor},
                         $self->{style}{font},$self->{style}{size}));
  $self->{defstyle}=$self->{actstyle};

  bless ($self, $class);
  return $self;
}   # - - End new (Object constructor)

# - * - Setters/Getters Meta.xml data

sub set_title {
  my $self=shift;
  $self->{meta}{title}=$self->encode_data (shift);
  1;
}

sub get_title {
  my $self=shift;
  return $self->{meta}{title};
}

sub set_author {
  my $self=shift;
  $self->{meta}{author}=$self->encode_data (shift);
  1;
}

sub get_author {
  my $self=shift;
  return $self->{meta}{author};
}

sub set_subject {
  my $self=shift;
  $self->{meta}{subject}=$self->encode_data (shift);
  1;
}

sub get_subject {
  my $self=shift;
  return $self->{meta}{subject};
}

sub set_comments {
  my $self=shift;
  $self->{meta}{comments}=$self->encode_data (shift);
  1;
}

sub get_comments {
  my $self=shift;
  return $self->{meta}{comments};
}

sub set_keywords {
  my ($self, @keywords)=@_;
  @{$self->{meta}{keywords}}=map $self->encode_data($_), @keywords;
  1;
}

sub push_keywords {
  my ($self, @keywords)=@_;
  push @{$self->{meta}{keywords}}, map $self->encode_data($_), @keywords;
  1;
}

sub get_keywords {
  my $self=shift;
  return @{$self->{meta}{keywords}};
}

sub set_meta {
  my ($self, $nb, $name, $value)=@_;
  if ($nb < 1 || $nb > 4 || ! $name) {
    return 0;
  } else {
    delete $self->{meta}{"data$nb"} if (exists ($self->{meta}{"data$nb"}));
    $name=$self->encode_data ($name);
    $name="meta$nb" if (! $name);
    $self->{meta}{"data$nb"}{$name}=$self->encode_data($value);
    1;
  }
}

# ** TODO get_meta : best way to return it: array, hash or ?

# - Setters for active style

# ** TODO getters for active style
# not yet implemented because in the future we will probably add
# ways to get the style of a specifique cell or location
# maybe we also add the possibility to read an existing document, and make
# changes to it. This all makes that we have to be careful about this.

sub set_bold {
  my ($self, $bold)=@_;
  if (! $bold) {
    $self->{style}{bold}=0;
  } else {
    $self->{style}{bold}=1;
  }
  $self->_set_active_style;
  1;
}

sub set_italic {
  my ($self, $italic)=@_;
  if (! $italic) {
    $self->{style}{italic}=0;
  } else {
    $self->{style}{italic}=1;
  }
  $self->_set_active_style;
  1;
}

sub set_underline {
  my ($self, $underline)=@_;
  if (! $underline) {
    $self->{style}{underline}=0;
  } else {
    $self->{style}{underline}=1;
  }
  $self->_set_active_style;
  1;
}

sub set_align {
  my ($self, $align)=@_;
  $align=lc($align);
  if ($align eq 'right' || $align eq 'center' || $align eq 'justify' ||
      $align eq 'left') {
    $self->{style}{align}=$align;
    $self->_set_active_style;
    return 1;
  } else {
    return 0;
  }
}

sub set_txtcolor {
  my ($self, $txtcolor)=@_;
  $txtcolor=$self->_check_color($txtcolor);
  return 0 unless ($txtcolor);
  $self->{style}{txtcolor}=$txtcolor;
  $self->_set_active_style;
  1;
}

sub set_bgcolor {
  my ($self, $bgcolor)=@_;
  $bgcolor=$self->_check_color($bgcolor);
  return 0 unless ($bgcolor);
  $self->{style}{bgcolor}=$bgcolor;
  $self->_set_active_style;
  1;
}

sub set_font {
  my ($self, $font)=@_;
  return 0 unless (exists($self->{availfonts}{$font}));
  $self->{style}{font}=$font;
  $self->_set_active_style;
  1;
}

sub set_fontsize {
  my ($self, $size)=@_;
  $size=~ s/[^0-9]//g;
  return 0 if ($size<$MINFONTSIZE || $size>$MAXFONTSIZE);
  $self->{style}{size}=$size;
  $self->_set_active_style;
  1;
}

 # - * - Build-directory

sub set_builddir {
  my ($self, $builddir)=@_;
  if (-d $builddir) {
    $self->{builddir}=$builddir;
    return 1;
  } else {
    return 0;
  }
}

sub get_builddir {
  my $self=shift;
  return $self->{builddir};
}

# - * - PrivateMethods
sub generate {
  my ($self, $tgtfile)=@_;

  # - check workdirectory & filename
  $self->{builddir}='.' unless (-d $self->{builddir});
  $tgtfile='oo_doc' unless ($tgtfile);
  $tgtfile.=qq{.$self->{oooType}};

  # - Available Document types and their mime types
  my (%mimetype);
  # Text - oowriter - sxw - OOWBuilder
  $mimetype{sxw}='application/vnd.sun.xml.writer';
  # Spreadsheet - oocalc - sxc - OOCBuilder
  $mimetype{sxc}='application/vnd.sun.xml.calc';
  # Drawing - oodraw - sxd - OODBuilder
  $mimetype{sxd}='application/vnd.sun.xml.draw';
  # Presentation - ooimpress - sxi - OOIBuilder
  $mimetype{sxi}='application/vnd.sun.xml.impress';
  # Formula - oomath - OOMBuilder
  $mimetype{sxm}='application/vnd.sun.xml.math';
# ** TODO
  # Chart            application/vnd.sun.xml.chart
  # Master Document  application/vnd.sun.xml.writer.global

  # - Generate mimetype.xml
  open TGT, qq{>$self->{builddir}/mimetype};
  print TGT $mimetype{$self->{oooType}};
  close TGT;

  # - Generate content.xml
  #   (must be build by the derived class and put into $self->{contentxml})
  open TGT, qq{>$self->{builddir}/content.xml};
  print TGT $self->{contentxml};
  close TGT;

  # - Generate meta.xml, styles.xml, settings.xml
  $self->_generate_meta;
  $self->_generate_styles;
  $self->_generate_settings;

  # - Generate Manifest
  mkdir(qq{$self->{builddir}/META-INF}) unless (-d qq{$self->{builddir}/META-INF});
  open TGT, qq{>$self->{builddir}/META-INF/manifest.xml};
  print TGT qq{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE manifest:manifest PUBLIC "-//OpenOffice.org//DTD Manifest 1.0//EN" "Manifest.dtd">
<manifest:manifest xmlns:manifest="http://openoffice.org/2001/manifest">
 <manifest:file-entry manifest:media-type="$mimetype{$self->{oooType}}" manifest:full-path="/" />
 <manifest:file-entry manifest:media-type="" manifest:full-path="Pictures/" />
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml" />
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml" />
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="meta.xml" />
 <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="settings.xml" />
</manifest:manifest>};
  close (TGT);

  # - Build compressed target file
  # windows support added by using Archive::Zip
  # thanks to Magnus Nufer
  my $zip = Archive::Zip->new();
  $zip->addFile(qq{$self->{builddir}/mimetype}, 'mimetype');
  $zip->addFile(qq{$self->{builddir}/content.xml}, 'content.xml');
  $zip->addFile(qq{$self->{builddir}/styles.xml}, 'styles.xml');
  $zip->addFile(qq{$self->{builddir}/meta.xml}, 'meta.xml');
  $zip->addFile(qq{$self->{builddir}/settings.xml}, 'settings.xml');
  $zip->addFile(qq{$self->{builddir}/META-INF/manifest.xml}, 'META-INF/manifest.xml');
  my $status = $zip->overwriteAs($tgtfile);
# if you are on a Linux system with zip available and you don't want to
# use Archive::Zip, you could use the following 6 lines, and comment out the
# above 8 lines and of course the 'use Archive::Zip' statement at the top
#   system("cd $self->{builddir}; zip -r '$tgtfile' mimetype &> /dev/null");
#   system("cd $self->{builddir}; zip -r '$tgtfile' content.xml &> /dev/null");
#   system("cd $self->{builddir}; zip -r '$tgtfile' styles.xml &> /dev/null");
#   system("cd $self->{builddir}; zip -r '$tgtfile' meta.xml &> /dev/null");
#   system("cd $self->{builddir}; zip -r '$tgtfile' settings.xml &> /dev/null");
#   system("cd $self->{builddir}; zip -r '$tgtfile' META-INF/manifest.xml &> /dev/null");

  # - remove workfiles & directory
  unlink("$self->{builddir}/mimetype");
  unlink("$self->{builddir}/content.xml");
  unlink("$self->{builddir}/styles.xml");
  unlink("$self->{builddir}/meta.xml");
  unlink("$self->{builddir}/settings.xml");
  unlink("$self->{builddir}/META-INF/manifest.xml");
  rmdir("$self->{builddir}/META-INF");

  1;
}

sub _generate_meta {
  my ($self);
  $self=shift;

  # - prepare data
  my ($timestamp, $keywords);
  $timestamp=$self->_oo_timestamp;
  $keywords=join('',map qq{<meta:keyword>$_</meta:keyword>}, @{$self->{meta}{keywords}});

  # - user defined vars
  my ($meta, $name, $value, @tmp);
  for (1 .. 4) {
    if ($self->{meta}{"data$_"}) {
      @tmp=keys(%{$self->{meta}{"data$_"}});
      $name=shift @tmp;
    } else {
      $name="meta$_";
    }
    $value=$self->{meta}{"data$_"}{$name};
    if ($value) {
      $meta.=qq{<meta:user-defined meta:name="$name">$value</meta:user-defined>};
    } else {
      $meta.=qq{<meta:user-defined meta:name="$name"/>};
    }
  }

  open (TGT, qq{>$self->{builddir}/meta.xml});
  print TGT
qq{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE office:document-meta PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "office.dtd">
<office:document-meta xmlns:office="http://openoffice.org/2000/office" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="http://openoffice.org/2000/meta" office:version="1.0">
<office:meta>
<meta:generator>oooBuilder $VERSION</meta:generator>
<dc:title>$self->{meta}{title}</dc:title>
<dc:description>$self->{meta}{comments}</dc:description>
<dc:subject>$self->{meta}{subject}</dc:subject>
<meta:initial-creator>$self->{meta}{author}</meta:initial-creator>
<meta:creation-date>$timestamp</meta:creation-date>
<dc:creator>$self->{meta}{author}</dc:creator>
<dc:date>$timestamp</dc:date>
<meta:keywords>$keywords</meta:keywords>
<dc:language>en-US</dc:language>
<meta:editing-cycles>1</meta:editing-cycles>
<meta:editing-duration>PT0S</meta:editing-duration>
$meta
</office:meta>
</office:document-meta>
};
  1;
}   # - - End _generate_meta


sub _generate_styles {
  my ($self);
  $self=shift;

# ** TODO

  1;
}   # - - End _generate_styles


sub _generate_settings {
  my ($self);
  $self=shift;

# ** TODO

  1;
}   # - - End _generate_settings


sub _set_active_style {
  my ($self);
  $self=shift;
  $self->{actstyle}=join('#',($self->{style}{bold}, $self->{style}{italic},
                         $self->{style}{underline},$self->{style}{align},
                         $self->{style}{txtcolor},$self->{style}{bgcolor},
                         $self->{style}{font},$self->{style}{size}));
  1;
}

sub _check_color {
  my ($self, $color)=@_;
  $color=lc($color);
  $color=$COLORS{$color} if (! ($color =~ /^[0-9a-f]{6}$/));
  return $color
}

# OpenOffice TimeStamp (form = yyyy-mm-ddThh:mm:ss)
sub _oo_timestamp {
  my ($self);
  $self=shift;
  my ($sec,$min,$hour,$mday,$mon,$year,@rest) = gmtime(time);
  return (sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
                  $year+1900,$mon+1,$mday,$hour,$min,$sec));
}

sub encode_data {
  my ($self, $data)=@_;
  $data=~ s/\&/\&amp;/g;
  $data=~ s/</\&lt;/g;
  $data=~ s/>/\&gt;/g;
  $data=~ s/'/\&apos;/g;
  $data=~ s/"/\&quot;/g;
  $data=~ s/\t/<text:tab-stop\/>/g;
  return $data;
}

1;
__END__


=head1 NAME

OpenOffice::OOBuilder - Perl OO interface for creating OpenOffice
documents.

=head1 SYNOPSIS

See the documentation of the derived classes.

=head1 DESCRIPTION

OOBuilder is a Perl OO interface for creating OpenOffice documents.
OOBuilder is the base class for all OpenOffice documents. Depending
on the type of document you want to create you have to use a
derived class.

At this moment only spreadsheet (sxc) documents are supported. See
the documentation of the derived class OOCBuilder for more information.

=head1 METHODS

new

  Don't call this directly. Must be called through a derived class.

set_title ($title)

  Set $title as title of your document.

get_title

  Returns the title of your document

set_author ($author)

  Set $author as author of your document.

get_author

  Returns the author of your document.

set_subject ($subject)

  Set $subject as subject of your document.

get_subject

  Returns the subject of your document.

set_comments ($comments)

  Set $comments as comments of your document.

get_comments

  Returns the comments of your document.

set_keywords (@keywords)

  Set @keywords as all keywords of your document.

push_keywords (keywords)

  Add one (if scalar supplied) or more (if list supplied) new keywords
  to your document.

get_keywords

  Returns the keywords of your document in an array.

set_meta ($nb, $name, $value)

  Set meta data. $nb is the meta number (between 1 and 4).
  $name is the name of your meta data. If ommited we'll take "meta$nb".
  $value is the new value of your meta data.

get_meta

  not yet implemented

set_bold ($bold)

  Set active font: bold: 1 to active, 0 to deactivate.

set_italic ($italic)

  Set active font: italic: 1 to active, 0 to deactivate.

set_underline ($underline)

  Set active font: underline: 1 to active, 0 to deactivate.

set_align ($align)

  Set align: allowed values: right, center, justify or left
  Else returns 0.

set_txtcolor ($txtcolor)

  Set the text color. $txtcolor can be a predefined value like red,
  green, blue, white or black. Or it can be specified in RGB in the
  form ff0000 (ie. as red). This returns 0 if the color can't be
  set.

set_bgcolor ($bgcolor)

  Set the text color. $bgcolor can be a predefined value like red,
  green, blue, white or black. Or it can be specified in RGB in the
  form ff0000 (ie. as red). This returns 0 if the color can't be
  set.

set_font ($font)

  Available fonts are : Arial, Bitstream Vera Sans, Bitstream Vera Serif,
  Bookman, Courier, Courier 10 Pitch, Helvetica, Lucidabright, Lucidasans,
  Lucida Sans Unicode, Lucidatypewriter, Luxi Mono, Luxi Sans, Luxi Serif,
  Symbol, Tahoma, Times, Times New Roman, Utopia, Zapf Chancery,
  Zapf Dingbats.
  Returns 0 if the font isn't available.

set_fontsize ($size)

  Set font size. Returns 0 if not succeeded.

set_builddir ($builddir)

  Set build directory. The target file will be placed in this directory.
  This directory will also be used for creating the temporary files,
  needed for creating the target file. Builddir is '.' by default.
  Returns 0 if the $builddir doesn't exist.

get_builddir

  Returns the build directory.

generate ($tgtfile)

  Don't call this method directly. This method should be called from
  the derived class.

=head1 EXAMPLES

Look at the examples directory supplied together with this distribution.

=head1 SEE ALSO

L<OpenOffice::OOCBuilder> for creating spreadsheets.

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
