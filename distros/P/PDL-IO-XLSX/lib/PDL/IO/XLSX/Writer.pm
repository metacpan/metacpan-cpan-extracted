package PDL::IO::XLSX::Writer::Base;
use 5.010;
use strict;
use warnings;
use Carp;

use File::Path 'mkpath';
use File::Basename 'dirname';

my %XML = (
  '&'  => '&amp;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '"'  => '&quot;',
  '\'' => '&#39;',
  "\n" => '&#xA;',
);

sub _xml_escape {
  my $str = shift // '';
  $str =~ s/([&<>"'\n])/$XML{$1}/ge;
  return $str;
}

sub _xml_excape_data {
  my $str = shift // '';
  $str =~ s/([&<>])/$XML{$1}/ge;
  return $str;
}

sub new {
  my ($class, %args) = @_;
  $args{excel_version} //= '2007';
  croak "undefined parent" unless ref $args{parent};
  bless \%args, $class;
}

sub sheets  { shift->{parent}{sheets} }
sub strings { shift->{parent}{strings} }
sub styles  { shift->{parent}{styles} }
sub tmpdir  { shift->{parent}{tmpdir} }

sub open_xml {
  my ($self, $file) = @_;
  my $fullname = $self->tmpdir . "/$file";
  croak if -f $fullname || -d $fullname;
  my $dirname = dirname($fullname);
  mkpath($dirname) unless -d $dirname;
  open my $fh, '>:encoding(UTF-8)', $fullname or croak "cannot open '$fullname': $!";
  print $fh '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' . "\n";
  return $fh;
}

sub write_xml_start_tag {
  my $self = shift;
  my $fh   = shift;
  my $tag  = shift;
  while (@_) {
    my $key   = shift @_;
    my $value = shift @_;
    $value = _xml_escape($value);
    $tag .= qq( $key="$value");
  }
  print $fh "<$tag>";
  return $self;
}

sub write_xml_end_tag {
  my $self = shift;
  my $fh   = shift;
  my $tag  = shift;
  print $fh "</$tag>";
}

sub write_xml_empty_tag {
  my $self = shift;
  my $fh   = shift;
  my $tag  = shift;
  while (@_) {
    my $key   = shift @_;
    my $value = shift @_;
    $value = _xml_escape($value);
    $tag .= qq( $key="$value");
  }
  print $fh "<$tag/>";
  return $self;
}

sub write_xml_data_element {
  my $self = shift;
  my $fh   = shift;
  my $tag  = shift;
  my $data = shift;
  my $closetag = "</$tag>";
  while (@_) {
    my $key   = shift @_;
    my $value = shift @_;
    $value = _xml_escape($value);
    $tag .= qq( $key="$value");
  }
  $data //= '';
  if ($data ne '') {
    print $fh "<$tag>" . _xml_excape_data($data) . $closetag;
  }
  else {
    print $fh "<$tag/>";
  }
  return $self;
}

package PDL::IO::XLSX::Writer::SharedStrings;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub count {
  my $self = shift;
  return scalar keys %{$self->{_ss_hash}};
}

sub get_sstring_id {
  my $self = shift;
  my $string = shift;
  croak "get_sstring_id: undefined string" unless defined $string;
  if (!defined $self->{_ss_hash}{$string}) {
    $self->{_ss_hash}{$string} = keys %{$self->{_ss_hash}}; # 0-based index
  }
  return $self->{_ss_hash}{$string};
}

sub save {
  my $self = shift;
  my @sorted_ss = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, $self->{_ss_hash}{$_}] } keys %{$self->{_ss_hash}};
  return unless @sorted_ss > 0;
  my $fh  = $self->open_xml('xl/sharedStrings.xml');
  my $count = @sorted_ss;
  $self->write_xml_start_tag($fh, 'sst',
    'xmlns' => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    'count' => $count,
    'uniqueCount' => $count,
  );
  for (@sorted_ss) {
    $self->write_xml_start_tag($fh, 'si');
    $self->write_xml_data_element($fh, 't', $_);
    $self->write_xml_end_tag($fh, 'si');
  }
  $self->write_xml_end_tag($fh, 'sst');
  close $fh;
}

package PDL::IO::XLSX::Writer::RelRoot;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $fh  = $self->open_xml('_rels/.rels');
  $self->write_xml_start_tag($fh, 'Relationships',
    'xmlns' => "http://schemas.openxmlformats.org/package/2006/relationships",
  );
  $self->write_xml_empty_tag($fh, 'Relationship',
    Id     => "rId1",
    Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" ,
    Target => "xl/workbook.xml",
  );
  $self->write_xml_empty_tag($fh, 'Relationship',
    Id     => "rId2",
    Type   => "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties",
    Target => "docProps/core.xml",
  );
  $self->write_xml_empty_tag($fh, 'Relationship',
    Id     => "rId3",
    Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties",
    Target => "docProps/app.xml",
  );
  $self->write_xml_end_tag($fh, 'Relationships');
  close $fh;
}

package PDL::IO::XLSX::Writer::RelWorkbook;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $fh = $self->open_xml('xl/_rels/workbook.xml.rels');
  $self->write_xml_start_tag($fh, 'Relationships',
    'xmlns' => "http://schemas.openxmlformats.org/package/2006/relationships",
  );
  my $i = 1;
  for my $id ($self->sheets->list_id) {
    croak "inconsistent sheets i=$i id=$id" if $i != $id;
    $self->write_xml_empty_tag($fh, 'Relationship',
      Id     => "rId$i",
      Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet",
      Target => "worksheets/sheet$i.xml",
    );
    $i++;
  }
  $self->write_xml_empty_tag($fh, 'Relationship',
    Id     => "rId" . $i++,
    Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" ,
    Target => "theme/theme1.xml",
  );
  $self->write_xml_empty_tag($fh, 'Relationship',
    Id     => "rId" . $i++,
    Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles",
    Target => "styles.xml",
  );
  if ($self->strings->count > 0) {
    $self->write_xml_empty_tag($fh, 'Relationship',
      Id     => "rId" . $i++,
      Type   => "http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings",
      Target => "sharedStrings.xml",
    );
  }
  $self->write_xml_end_tag($fh, 'Relationships');
  close $fh;
}

package PDL::IO::XLSX::Writer::PropsCore;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

use Time::Moment;

sub save {
  my $self = shift;
  my $fh = $self->open_xml('docProps/core.xml');
  $self->write_xml_start_tag($fh, 'cp:coreProperties',
    'xmlns:cp'       => "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
    'xmlns:dc'       => "http://purl.org/dc/elements/1.1/",
    'xmlns:dcterms'  => "http://purl.org/dc/terms/",
    'xmlns:dcmitype' => "http://purl.org/dc/dcmitype/",
    'xmlns:xsi'      => "http://www.w3.org/2001/XMLSchema-instance",
  );
  my $now = Time::Moment->now_utc->strftime("%Y-%m-%dT%H:%M:%SZ"); # 2016-12-05T13:54:42Z
  $self->write_xml_data_element($fh, 'dc:title', $self->{title});
  $self->write_xml_data_element($fh, 'dc:subject', $self->{subject});
  $self->write_xml_data_element($fh, 'dc:creator', $self->{author});
  $self->write_xml_data_element($fh, 'cp:lastModifiedBy', $self->{author});
  $self->write_xml_data_element($fh, 'dcterms:created', $now, 'xsi:type' => "dcterms:W3CDTF");
  $self->write_xml_data_element($fh, 'dcterms:modified', $now, 'xsi:type' => "dcterms:W3CDTF");
  $self->write_xml_end_tag($fh, 'cp:coreProperties');
  close $fh;
}

package PDL::IO::XLSX::Writer::PropsApp;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $sheets = $self->sheets->count;
  my $fh = $self->open_xml('docProps/app.xml');
  $self->write_xml_start_tag($fh, 'Properties',
    'xmlns'    => "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties",
    'xmlns:vt' => "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes",
  );
  $self->write_xml_data_element($fh, 'Application', 'Microsoft Excel');
  $self->write_xml_data_element($fh, 'DocSecurity', '0');
  $self->write_xml_data_element($fh, 'ScaleCrop', 'false');
  $self->write_xml_start_tag($fh, 'HeadingPairs');
  $self->write_xml_start_tag($fh, 'vt:vector', size => 2, baseType => "variant");
  $self->write_xml_start_tag($fh, 'vt:variant');
  $self->write_xml_data_element($fh, 'vt:lpstr', 'Worksheets');
  $self->write_xml_end_tag($fh, 'vt:variant');
  $self->write_xml_start_tag($fh, 'vt:variant');
  $self->write_xml_data_element($fh, 'vt:i4', $sheets);
  $self->write_xml_end_tag($fh, 'vt:variant');
  $self->write_xml_end_tag($fh, 'vt:vector');
  $self->write_xml_end_tag($fh, 'HeadingPairs');
  $self->write_xml_start_tag($fh, 'TitlesOfParts');
  $self->write_xml_start_tag($fh, 'vt:vector', size => $sheets, baseType => "lpstr");
  for my $name ($self->sheets->list_name) {
    $self->write_xml_data_element($fh, 'vt:lpstr', $name);
  }
  $self->write_xml_end_tag($fh, 'vt:vector');
  $self->write_xml_end_tag($fh, 'TitlesOfParts');
  $self->write_xml_data_element($fh, 'Company', $self->{company});
  $self->write_xml_data_element($fh, 'LinksUpToDate', 'false');
  $self->write_xml_data_element($fh, 'SharedDoc', 'false');
  $self->write_xml_data_element($fh, 'HyperlinksChanged', 'false');
  #Excel 2007 (v12.0), Excel 2010 (v14.0), Excel 2013 (v15.0),  Excel 2016 (v16.0)
  my $ver = $self->{excel_version} eq '2010' ? '14.0000' : '12.0000';
  $self->write_xml_data_element($fh, 'AppVersion', $ver);
  $self->write_xml_end_tag($fh, 'Properties');
  close $fh;
}

package PDL::IO::XLSX::Writer::Styles;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

my %builtin = (
  '0'        => 1,  # 'int'
  '0.00'     => 2,  # 'float'
  '#,##0'    => 3,  # 'float'
  '#,##0.00' => 4,  # 'float'
  '0%'       => 9,  # 'int'
  '0.00%'    => 10, # 'float'
  '0.00E+00' => 11, # 'float'

);

sub get_style_attr {
  my $self  = shift;
  my $style = shift;
  return '' if ($style//'') eq '';

  if (defined $self->{_style_hash}{$style}) {
    return qq( s="$self->{_style_hash}{$style}{seqid}"); # must start with a space
  }
  $self->{_style_hash}{$style}{seqid} = 1 + keys %{$self->{_style_hash}}; # 1-based index
  if (defined $builtin{$style}) {
    $self->{_style_hash}{$style}{builtin} = 1;
    $self->{_style_hash}{$style}{fmtid} = $builtin{$style};
  }
  else {
    $self->{_style_next_custom_fmtid} //= 164; # numFmtId less than 164 are "built-in"
    $self->{_style_hash}{$style}{fmtid} = $self->{_style_next_custom_fmtid}++;
  }
  $self->{_style_hash}{$style}{format} = $style;
  return qq( s="$self->{_style_hash}{$style}{seqid}"); # must start with a space
}

sub save {
  my $self = shift;
  my @sorted_formats  = sort { $a->{seqid} <=> $b->{seqid} } values %{$self->{_style_hash}};
  my @custom_formats  = grep { !$_->{builtin} } @sorted_formats;
  my $fh = $self->open_xml('xl/styles.xml');
  $self->write_xml_start_tag($fh, 'styleSheet', xmlns => "http://schemas.openxmlformats.org/spreadsheetml/2006/main");
  if (@custom_formats > 0) {
    $self->write_xml_start_tag($fh, 'numFmts', count => scalar(@custom_formats));
    $self->write_xml_empty_tag($fh, 'numFmt', formatCode => $_->{format}, numFmtId => $_->{fmtid}) for (@custom_formats);
    $self->write_xml_end_tag($fh, 'numFmts');
  }
  $self->write_xml_start_tag($fh, 'fonts', count => 1);
  $self->write_xml_start_tag($fh, 'font');
  $self->write_xml_empty_tag($fh, 'sz',     val   => "11");
  $self->write_xml_empty_tag($fh, 'color',  theme => "1");
  $self->write_xml_empty_tag($fh, 'name',   val   => "Calibri");
  $self->write_xml_empty_tag($fh, 'family', val   => "2");
  $self->write_xml_empty_tag($fh, 'scheme', val   => "minor");
  $self->write_xml_end_tag($fh, 'font');
  $self->write_xml_end_tag($fh, 'fonts');
  $self->write_xml_start_tag($fh, 'fills', count => 2);
  $self->write_xml_start_tag($fh, 'fill');
  $self->write_xml_empty_tag($fh, 'patternFill', patternType => "none");
  $self->write_xml_end_tag($fh, 'fill');
  $self->write_xml_start_tag($fh, 'fill');
  $self->write_xml_empty_tag($fh, 'patternFill', patternType => "gray125");
  $self->write_xml_end_tag($fh, 'fill');

  ### header style - gray background XXX-TODO
  #$self->write_xml_start_tag($fh, 'fill');
  #$self->write_xml_start_tag($fh, 'patternFill', patternType => "solid");
  #$self->write_xml_empty_tag($fh, 'fgColor', theme => "0", tint => "-0.14999847407452621");
  #$self->write_xml_empty_tag($fh, 'bgColor', indexed => "64");
  #$self->write_xml_end_tag($fh, 'patternFill');
  #$self->write_xml_end_tag($fh, 'fill');

  $self->write_xml_end_tag($fh, 'fills');
  $self->write_xml_start_tag($fh, 'borders', count => 1);
  $self->write_xml_start_tag($fh, 'border');
  $self->write_xml_empty_tag($fh, 'left');
  $self->write_xml_empty_tag($fh, 'right');
  $self->write_xml_empty_tag($fh, 'top');
  $self->write_xml_empty_tag($fh, 'bottom');
  $self->write_xml_empty_tag($fh, 'diagonal');
  $self->write_xml_end_tag($fh, 'border');
  $self->write_xml_end_tag($fh, 'borders');
  $self->write_xml_start_tag($fh, 'cellStyleXfs', count => "1");
  $self->write_xml_empty_tag($fh, 'xf', numFmtId => "0", fontId => "0", fillId => "0", borderId => "0");
  $self->write_xml_end_tag($fh, 'cellStyleXfs');
  $self->write_xml_start_tag($fh, 'cellXfs', count => 1 + @sorted_formats);
  $self->write_xml_empty_tag($fh, 'xf', numFmtId => "0", fontId => "0", fillId => "0", borderId => "0", xfId => "0");
  for (@sorted_formats) {
    $self->write_xml_empty_tag($fh, 'xf', numFmtId => $_->{fmtid}, fontId => "0", fillId => "0", borderId => "0", xfId => "0", applyNumberFormat => "1");
  }
  $self->write_xml_end_tag($fh, 'cellXfs');
  $self->write_xml_start_tag($fh, 'cellStyles', count => "1");
  $self->write_xml_empty_tag($fh, 'cellStyle', name => "Normal", xfId => "0", builtinId => "0");
  $self->write_xml_end_tag($fh, 'cellStyles');
  $self->write_xml_empty_tag($fh, 'dxfs', count => "0");
  $self->write_xml_empty_tag($fh, 'tableStyles', count => "0", defaultTableStyle => "TableStyleMedium9", defaultPivotStyle => "PivotStyleLight16");
  $self->write_xml_end_tag($fh, 'styleSheet');
  close $fh;
}

package PDL::IO::XLSX::Writer::Theme;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $fh = $self->open_xml('xl/theme/theme1.xml');
  # hardcoded for now
  print $fh '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme"><a:themeElements><a:clrScheme name="Office"><a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1><a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="1F497D"/></a:dk2><a:lt2><a:srgbClr val="EEECE1"/></a:lt2><a:accent1><a:srgbClr val="4F81BD"/></a:accent1><a:accent2><a:srgbClr val="C0504D"/></a:accent2><a:accent3><a:srgbClr val="9BBB59"/></a:accent3><a:accent4><a:srgbClr val="8064A2"/></a:accent4><a:accent5><a:srgbClr val="4BACC6"/></a:accent5><a:accent6><a:srgbClr val="F79646"/></a:accent6><a:hlink><a:srgbClr val="0000FF"/></a:hlink><a:folHlink><a:srgbClr val="800080"/></a:folHlink></a:clrScheme><a:fontScheme name="Office"><a:majorFont><a:latin typeface="Cambria"/><a:ea typeface=""/><a:cs typeface=""/><a:font script="Jpan" typeface="MS P????"/><a:font script="Hang" typeface="?? ??"/><a:font script="Hans" typeface="??"/><a:font script="Hant" typeface="????"/><a:font script="Arab" typeface="Times New Roman"/><a:font script="Hebr" typeface="Times New Roman"/><a:font script="Thai" typeface="Tahoma"/><a:font script="Ethi" typeface="Nyala"/><a:font script="Beng" typeface="Vrinda"/><a:font script="Gujr" typeface="Shruti"/><a:font script="Khmr" typeface="MoolBoran"/><a:font script="Knda" typeface="Tunga"/><a:font script="Guru" typeface="Raavi"/><a:font script="Cans" typeface="Euphemia"/><a:font script="Cher" typeface="Plantagenet Cherokee"/><a:font script="Yiii" typeface="Microsoft Yi Baiti"/><a:font script="Tibt" typeface="Microsoft Himalaya"/><a:font script="Thaa" typeface="MV Boli"/><a:font script="Deva" typeface="Mangal"/><a:font script="Telu" typeface="Gautami"/><a:font script="Taml" typeface="Latha"/><a:font script="Syrc" typeface="Estrangelo Edessa"/><a:font script="Orya" typeface="Kalinga"/><a:font script="Mlym" typeface="Kartika"/><a:font script="Laoo" typeface="DokChampa"/><a:font script="Sinh" typeface="Iskoola Pota"/><a:font script="Mong" typeface="Mongolian Baiti"/><a:font script="Viet" typeface="Times New Roman"/><a:font script="Uigh" typeface="Microsoft Uighur"/></a:majorFont><a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/><a:font script="Jpan" typeface="MS P????"/><a:font script="Hang" typeface="?? ??"/><a:font script="Hans" typeface="??"/><a:font script="Hant" typeface="????"/><a:font script="Arab" typeface="Arial"/><a:font script="Hebr" typeface="Arial"/><a:font script="Thai" typeface="Tahoma"/><a:font script="Ethi" typeface="Nyala"/><a:font script="Beng" typeface="Vrinda"/><a:font script="Gujr" typeface="Shruti"/><a:font script="Khmr" typeface="DaunPenh"/><a:font script="Knda" typeface="Tunga"/><a:font script="Guru" typeface="Raavi"/><a:font script="Cans" typeface="Euphemia"/><a:font script="Cher" typeface="Plantagenet Cherokee"/><a:font script="Yiii" typeface="Microsoft Yi Baiti"/><a:font script="Tibt" typeface="Microsoft Himalaya"/><a:font script="Thaa" typeface="MV Boli"/><a:font script="Deva" typeface="Mangal"/><a:font script="Telu" typeface="Gautami"/><a:font script="Taml" typeface="Latha"/><a:font script="Syrc" typeface="Estrangelo Edessa"/><a:font script="Orya" typeface="Kalinga"/><a:font script="Mlym" typeface="Kartika"/><a:font script="Laoo" typeface="DokChampa"/><a:font script="Sinh" typeface="Iskoola Pota"/><a:font script="Mong" typeface="Mongolian Baiti"/><a:font script="Viet" typeface="Arial"/><a:font script="Uigh" typeface="Microsoft Uighur"/></a:minorFont></a:fontScheme><a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:tint val="50000"/><a:satMod val="300000"/></a:schemeClr></a:gs><a:gs pos="35000"><a:schemeClr val="phClr"><a:tint val="37000"/><a:satMod val="300000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:tint val="15000"/><a:satMod val="350000"/></a:schemeClr></a:gs></a:gsLst><a:lin ang="16200000" scaled="1"/></a:gradFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:shade val="51000"/><a:satMod val="130000"/></a:schemeClr></a:gs><a:gs pos="80000"><a:schemeClr val="phClr"><a:shade val="93000"/><a:satMod val="130000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:shade val="94000"/><a:satMod val="135000"/></a:schemeClr></a:gs></a:gsLst><a:lin ang="16200000" scaled="0"/></a:gradFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"><a:shade val="95000"/><a:satMod val="105000"/></a:schemeClr></a:solidFill><a:prstDash val="solid"/></a:ln><a:ln w="25400" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln><a:ln w="38100" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="20000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="38000"/></a:srgbClr></a:outerShdw></a:effectLst></a:effectStyle><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="35000"/></a:srgbClr></a:outerShdw></a:effectLst></a:effectStyle><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="35000"/></a:srgbClr></a:outerShdw></a:effectLst><a:scene3d><a:camera prst="orthographicFront"><a:rot lat="0" lon="0" rev="0"/></a:camera><a:lightRig rig="threePt" dir="t"><a:rot lat="0" lon="0" rev="1200000"/></a:lightRig></a:scene3d><a:sp3d><a:bevelT w="63500" h="25400"/></a:sp3d></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:tint val="40000"/><a:satMod val="350000"/></a:schemeClr></a:gs><a:gs pos="40000"><a:schemeClr val="phClr"><a:tint val="45000"/><a:shade val="99000"/><a:satMod val="350000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:shade val="20000"/><a:satMod val="255000"/></a:schemeClr></a:gs></a:gsLst><a:path path="circle"><a:fillToRect l="50000" t="-80000" r="50000" b="180000"/></a:path></a:gradFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:tint val="80000"/><a:satMod val="300000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:shade val="30000"/><a:satMod val="200000"/></a:schemeClr></a:gs></a:gsLst><a:path path="circle"><a:fillToRect l="50000" t="50000" r="50000" b="50000"/></a:path></a:gradFill></a:bgFillStyleLst></a:fmtScheme></a:themeElements><a:objectDefaults/><a:extraClrSchemeLst/></a:theme>';
  close $fh;
}

package PDL::IO::XLSX::Writer::ContentTypes;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $fh = $self->open_xml('[Content_Types].xml');
  $self->write_xml_start_tag($fh, 'Types',
    'xmlns' => "http://schemas.openxmlformats.org/package/2006/content-types",
  );
  $self->write_xml_empty_tag($fh, 'Default',
    Extension => "rels",
    ContentType => "application/vnd.openxmlformats-package.relationships+xml",
  );
  $self->write_xml_empty_tag($fh, 'Default',
    Extension => "xml",
    ContentType => "application/xml",
  );
  $self->write_xml_empty_tag($fh, 'Override',
    PartName => "/docProps/app.xml",
    ContentType => "application/vnd.openxmlformats-officedocument.extended-properties+xml",
  );
  $self->write_xml_empty_tag($fh, 'Override',
    PartName => "/docProps/core.xml",
    ContentType => "application/vnd.openxmlformats-package.core-properties+xml",
  );
  $self->write_xml_empty_tag($fh, 'Override',
    PartName => "/xl/styles.xml",
    ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml",
  );
  $self->write_xml_empty_tag($fh, 'Override',
    PartName => "/xl/theme/theme1.xml",
    ContentType => "application/vnd.openxmlformats-officedocument.theme+xml",
  );
  $self->write_xml_empty_tag($fh, 'Override',
    PartName => "/xl/workbook.xml",
    ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
  );
  for my $id ($self->sheets->list_id) {
    $self->write_xml_empty_tag($fh, 'Override',
      PartName => "/xl/worksheets/sheet$id.xml",
      ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml",
    );
  }
  if ($self->strings->count > 0) {
    $self->write_xml_empty_tag($fh, 'Override',
      PartName => "/xl/sharedStrings.xml",
      ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml",
    );
  }
  $self->write_xml_end_tag($fh, 'Types');
  close $fh;
}

package PDL::IO::XLSX::Writer::Workbook;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

sub save {
  my $self = shift;
  my $fh = $self->open_xml('xl/workbook.xml');
  ## <workbook>
  $self->write_xml_start_tag($fh, 'workbook',
        'xmlns'   => 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
        'xmlns:r' => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
  );
  ## <fileVersion ... />
  $self->write_xml_empty_tag($fh, 'fileVersion',
        'appName'      => 'xl',
        'lastEdited'   => 4,
        'lowestEdited' => 4,
        'rupBuild'     => 4505,
  );
  ## <workbookPr ... />
  $self->write_xml_empty_tag($fh, 'workbookPr',
        'defaultThemeVersion' => 124226,
  );
  ## <bookViews>
  $self->write_xml_start_tag($fh, 'bookViews');
  ## <workbookView ... />
  $self->write_xml_empty_tag($fh, 'workbookView',
        'xWindow'      => 384,
        'yWindow'      => 84,
        'windowWidth'  => 18180,
        'windowHeight' => 7176,
  );
  ## </bookViews>
  $self->write_xml_end_tag($fh, 'bookViews');
  ## <sheets>
  $self->write_xml_start_tag($fh, 'sheets' );
  for ($self->sheets->list_id_name) {
    my ($id, $name) = @$_;
    ## <sheet ... />
    $self->write_xml_empty_tag($fh, 'sheet',
        'r:id'    => "rId$id",
        'name'    => $name,
        'sheetId' => $id,
    );
  }
  ## </sheets>
  $self->write_xml_end_tag($fh, 'sheets');
  ## <calcPr ... />
  $self->write_xml_empty_tag($fh, 'calcPr',
        'calcId' => 124519,
        'fullCalcOnLoad' => 1,
  );
  # </workbook>
  $self->write_xml_end_tag($fh, 'workbook');
  close $fh;
}

package PDL::IO::XLSX::Writer::Sheets;
use 5.010;
use strict;
use warnings;
use Carp;

use base 'PDL::IO::XLSX::Writer::Base';

use Scalar::Util qw(looks_like_number);

my @row2letter = ( 'A' .. 'XFD' );

sub count {
  my $self = shift;
  return scalar @{$self->{_sheet_list}//[]};
}

sub list_id {
  my $self = shift;
  return map { $_->[0] } @{$self->{_sheet_list}//[]};
}

sub list_name {
  my $self = shift;
  return map { $_->[1] } @{$self->{_sheet_list}//[]};
}

sub list_id_name {
  my $self = shift;
  return map { [$_->[0], $_->[1]] } @{$self->{_sheet_list}//[]};
}

sub start {
  my ($self, $sheet_name, $width_hash, $format_array) = @_;
  croak "you must call save() before start()" if defined $self->{_sheet_fh} || defined $self->{_sheet_id};
  my $sheet_id = $self->count + 1;
  my $fh = $self->open_xml("xl/worksheets/sheet$sheet_id.xml");
  $self->{_sheet_id} = $sheet_id;
  $self->{_sheet_name} = $sheet_name;
  $self->{_sheet_rows} = 0;
  $self->{_sheet_cols} = 0;
  $self->{_sheet_fh} = $fh;
  $self->{_sheet_colfmt} = $format_array // [];
  my @ex2010 = (
    'xmlns:mc' => 'http://schemas.openxmlformats.org/markup-compatibility/2006',
    'xmlns:x14ac' => 'http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac',
    'mc:Ignorable' => 'x14ac',
  );
  $self->write_xml_start_tag($fh, 'worksheet',
    'xmlns'   => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    'xmlns:r' => "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    ( $self->{excel_version} eq '2010' ? (@ex2010) : () ),
  );
  $self->write_xml_empty_tag($fh, 'dimension',  ref => "A1");
  $self->write_xml_start_tag($fh, 'sheetViews');
  $self->write_xml_empty_tag($fh, 'sheetView', tabSelected => ($sheet_id == 1 ? 1 : 0), workbookViewId => 0);
  $self->write_xml_end_tag($fh, 'sheetViews');
  $self->write_xml_empty_tag($fh, 'sheetFormatPr',
    'defaultRowHeight' => 15,
    ( $self->{excel_version} eq '2010' ? ('x14ac:dyDescent' => '0.25') : () ),
  );
  # handle custom column width
  if (my @wkeys = (keys %$width_hash)) {
    my @tmp;
    for my $k (@wkeys) {
      my $width = $width_hash->{$k};
      my ($min,undef,$max) = $k =~ /^(\d+)(-(\d+))?$/; # accept "123" as well as "123-130"
      $max //= $min;
      croak "custom-width: invalid column definition '$k'" unless defined $min && defined $max;
      croak "custom-width: invalid width '$width'" unless looks_like_number($width);
      push @tmp, [ $min, $max, $width ];
    }
    @tmp = sort { $a->[0] <=> $b->[0] } @tmp; # sort by min
    $self->write_xml_start_tag($fh, 'cols');
    $self->write_xml_empty_tag($fh, 'col', min=>$_->[0], max=>$_->[1], width=>$_->[2], customWidth=>"1") for (@tmp);
    $self->write_xml_end_tag($fh, 'cols');
  }
  # open <sheetData> tag - it will be closed in save()
  $self->write_xml_start_tag($fh, 'sheetData');
}

sub add_row {
  my $self = shift;
  my $data = shift // [];
  my $format = shift // $self->{_sheet_colfmt} // [];

  my $cols = scalar @{$data};
  my $r = $self->{_sheet_rows} + 1;

  # Excel2010 limitations - https://support.office.com/en-us/article/Excel-specifications-and-limits-1672b34d-7043-467e-8e27-269d656771c3
  if ($r > 1048576) {
    carp "rows with index above 1048576 will be ignored" if !$self->{_warn_rows};
    $self->{_warn_rows} = 1;
    return;
  }
  if ($cols > 16384) {
    carp "columns with index above 16384 will be ignored" if !$self->{_warn_cols};
    $self->{_warn_cols} = 1;
    $cols = 16384;
  }

  $self->{_sheet_rows} = $r;
  $self->{_sheet_cols} = $cols if $self->{_sheet_cols} < $cols;
  my $xmlcells = $self->{excel_version} eq '2010' ? sprintf('<row r="%s" spans="%s:%s" x14ac:dyDescent="0.25">', $r, 1, $cols)
                                                  : sprintf('<row r="%s" spans="%s:%s">', $r, 1, $cols);
  my @s_attr = map { $self->styles->get_style_attr($_) } @$format;
  for(my $c = 1; $c <= $cols; $c++) {
    my $val = $data->[$c-1];
    if (looks_like_number($val)) {
      if ($s_attr[$c-1]) {
        # add format/style attribute s="?"
        $xmlcells .= sprintf('<c r="%s"%s><v>%s</v></c>', $row2letter[$c-1] . $r, $s_attr[$c-1], $val);
      }
      else {
        # no format/style attribute s="?"
        $xmlcells .= sprintf('<c r="%s"><v>%s</v></c>', $row2letter[$c-1] . $r, $val);
      }
    }
    elsif (($val//'') ne '') {
      my $id = $self->strings->get_sstring_id($val);
      $xmlcells .= sprintf('<c r="%s" t="s"><v>%s</v></c>', $row2letter[$c-1] . $r, $id);
    }
  }
  $xmlcells .= '</row>';
  print { $self->{_sheet_fh} } $xmlcells;
}

sub save {
  my $self = shift;
  croak "incomplete data" unless defined $self->{_sheet_id}   && defined $self->{_sheet_name} &&
                                 defined $self->{_sheet_rows} && defined $self->{_sheet_cols} &&
                                 defined $self->{_sheet_fh};
  my $fh = $self->{_sheet_fh};
  $self->write_xml_end_tag($fh, 'sheetData');
  $self->write_xml_empty_tag($fh, 'pageMargins', left => "0.7", right => "0.7", top => "0.75", bottom => "0.75", header => "0.3", footer => "0.3");
  $self->write_xml_end_tag($fh, 'worksheet');
  close $self->{_sheet_fh};
  push @{ $self->{_sheet_list} }, [ $self->{_sheet_id}, $self->{_sheet_name}, $self->{_sheet_rows}, $self->{_sheet_cols} ];
  $self->{_sheet_id}   = undef;
  $self->{_sheet_name} = undef;
  $self->{_sheet_rows} = undef;
  $self->{_sheet_cols} = undef;
  $self->{_sheet_colfmt} = undef;
  $self->{_sheet_colwidth} = undef;
  $self->{_sheet_fh}   = undef;
}

package PDL::IO::XLSX::Writer;
use 5.010;
use strict;
use warnings;
use Carp;

use File::Temp;
use Archive::Zip;
use Scalar::Util qw(openhandle looks_like_number);

sub new {
  my ($class, %args) = @_;
  my $tmp_dir        = delete $args{tmp_dir};
  my $tmp_cleanup    = delete $args{tmp_cleanup} // 1 ? 1 : 0;
  my $compression    = delete $args{compression};

  if (defined $compression) {
    croak "compression must be 0..9" unless looks_like_number($compression) && $compression >= 0 && $compression <= 9;
  }

  my $tmp = $tmp_dir && -d $tmp_dir ? File::Temp->newdir( "xlsx_writer_XXXXXX", DIR => $tmp_dir, CLEANUP => $tmp_cleanup )
                                    : File::Temp->newdir( "xlsx_writer_XXXXXX", TMPDIR => 1, CLEANUP => $tmp_cleanup );
  my $self = bless {
    extra_args    => \%args,
    compression   => $compression // 6, # 6 = default, 0 = none, 1 = fastest, 9 = best
    tmpdir        => $tmp,
  }, $class;
  $self->{styles}  = PDL::IO::XLSX::Writer::Styles->new(%{$self->{extra_args}}, parent => $self);
  $self->{strings} = PDL::IO::XLSX::Writer::SharedStrings->new(%{$self->{extra_args}}, parent => $self);
  $self->{sheets}  = PDL::IO::XLSX::Writer::Sheets->new(%{$self->{extra_args}}, parent => $self);
  return $self;
}

sub sheets  { shift->{sheets}  }
sub strings { shift->{strings} }
sub styles  { shift->{styles}  }

sub xlsx_save {
  my $self = shift;
  my $filename_or_fh = shift;

  croak "no sheets" if $self->sheets->count == 0;

  my $fh;
  if (!defined $filename_or_fh) {
    $fh = \*STDOUT;
  }
  elsif (openhandle($filename_or_fh)) {
    $fh = $filename_or_fh;
  }
  else {
    open $fh, ">", $filename_or_fh or croak "$filename_or_fh: $!";
  }

  #$self->sheets->save; #XXX-TODO detect unsaved sheets

  PDL::IO::XLSX::Writer::Workbook     ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::PropsApp     ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::PropsCore    ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::Theme        ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::ContentTypes ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::RelWorkbook  ->new(%{$self->{extra_args}}, parent => $self)->save;
  PDL::IO::XLSX::Writer::RelRoot      ->new(%{$self->{extra_args}}, parent => $self)->save;

  $self->styles->save;
  $self->strings->save;

  my $zip = Archive::Zip->new;
  my $dir_member = $zip->addTree($self->{tmpdir}, '', undef, $self->{compression});
  croak 'ZIP write error' unless $zip->writeToFileHandle($fh) == Archive::Zip::AZ_OK;
  return $self;
}

1;

__END__

  my $xw = PDL::IO::XLSX::Writer->new(
                tmp_dir => '.',              # optional: default = '/tmp'
                tmp_cleanup => 1,            # optional: default = 1
                excel_version => '2010',     # optional: default = '2007'
                compression => 6,            # optional: default = 6
                author  => 'žlutý kůň',      # optional: default = undef
                company => 'ŽLUTÝ KůŇ',      # optional: default = undef
                title   => 'ŽLUTÝ title',    # optional: default = undef
                subject => 'ŽLUTÝ subject',  # optional: default = undef
  );

  $xw->sheets->start("List1");
  $xw->sheets->add_row([ "R1", "R2", "R3", "R4" ]);
  $xw->sheets->add_row([ 1.12369, 2.12369, 3.12369, 4.12369 ], ['0.0','0.0','0.0','0.0']);
  $xw->sheets->add_row([ 1.12369, 2.12369, 3.12369, 4.12369 ], ['0.0','0.0','0.0','0.0']);
  $xw->sheets->save;

  $xw->sheets->start("List2");
  $xw->sheets->add_row([ "R11", "R22", "R33", "R44" ]);
  $xw->sheets->add_row([ 1.12369, 2.12369, 3.12369, 4.12369 ], ['0.0E+00','0.0E+00','0.0E+00','0.0E+00']);
  $xw->sheets->add_row([ 1.12369, 2.12369, 3.12369, 4.12369 ], ['0.0E+00','0.0E+00','0.0E+00','0.0E+00']);
  $xw->sheets->save("output.xlsx");

  $xw->xlsx_save;
