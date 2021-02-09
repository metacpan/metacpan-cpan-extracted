package Pod::WordML::AddisonWesley;
use strict;
use base 'Pod::WordML';

use warnings;
no warnings;

our $VERSION = '0.165';

=encoding utf8

=head1 NAME

Pod::WordML::AddisonWesley - Turn Pod into Microsoft Word's WordML using Addison Wesley's styles

=head1 SYNOPSIS

	use Pod::WordML::AddisonWesley;

=head1 DESCRIPTION

***THIS IS ALPHA SOFTWARE. MAJOR PARTS WILL CHANGE***

I wrote just enough of this module to get my job done, and I skipped every
part of the specification I didn't need while still making it flexible enough
to handle stuff later.

=head2 The style information

I don't handle all of the complexities of styles, defining styles, and
all that other stuff. There are methods to return style names, and you
can override those in a subclass.

=cut

=over 4

=item document_header

This is the start of the document that defines all of the styles. You'll need
to override this. You can take this directly from

=cut

sub fonts
	{
	<<'XML';
<w:fonts>
  <w:defaultFonts w:ascii="Times New Roman" w:fareast="Times New Roman" w:h-ansi="Times New Roman" w:cs="Times New Roman" />
  <w:font w:name="Times New Roman">
    <w:panose-1 w:val="02020603050405020304" />
    <w:charset w:val="00" />
    <w:family w:val="auto" />
    <w:pitch w:val="variable" />
    <w:sig w:usb-0="00000003" w:usb-1="00000000" w:usb-2="00000000" w:usb-3="00000000" w:csb-0="00000001" w:csb-1="00000000" />
  </w:font>
  <w:font w:name="Arial">
    <w:panose-1 w:val="020B0604020202020204" />
    <w:charset w:val="00" />
    <w:family w:val="auto" />
    <w:pitch w:val="variable" />
    <w:sig w:usb-0="00000003" w:usb-1="00000000" w:usb-2="00000000" w:usb-3="00000000" w:csb-0="00000001" w:csb-1="00000000" />
  </w:font>
  <w:font w:name="Courier New">
    <w:panose-1 w:val="02070309020205020404" />
    <w:charset w:val="4D" />
    <w:family w:val="Modern" />
    <w:notTrueType />
    <w:pitch w:val="fixed" />
    <w:sig w:usb-0="00000003" w:usb-1="00000000" w:usb-2="00000000" w:usb-3="00000000" w:csb-0="00000001" w:csb-1="00000000" />
  </w:font>
  <w:font w:name="Times">
    <w:panose-1 w:val="02000500000000000000" />
    <w:charset w:val="4D" />
    <w:family w:val="Roman" />
    <w:notTrueType />
    <w:pitch w:val="variable" />
    <w:sig w:usb-0="00000003" w:usb-1="00000000" w:usb-2="00000000" w:usb-3="00000000" w:csb-0="00000001" w:csb-1="00000000" />
  </w:font>
</w:fonts>
XML
	}

sub lists
	{
	<<'XML';
<w:lists>
  <w:listDef w:listDefId="0">
    <w:lsid w:val="FFFFFFFB" />
    <w:plt w:val="Multilevel" />
    <w:tmpl w:val="FFFFFFFF" />
    <w:lvl w:ilvl="0">
      <w:start w:val="1" />
      <w:pStyle w:val="Heading1" />
      <w:lvlText w:val="Chapter %1" />
      <w:legacy w:legacy="on" w:legacySpace="120" w:legacyIndent="360" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="1">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading2" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="2">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading3" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="3">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading4" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="4">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading5" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="5">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading6" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="6">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading7" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="7">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading8" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
    <w:lvl w:ilvl="8">
      <w:start w:val="1" />
      <w:nfc w:val="255" />
      <w:pStyle w:val="Heading9" />
      <w:suff w:val="Nothing" />
      <w:lvlText w:val="" />
      <w:lvlJc w:val="left" />
    </w:lvl>
  </w:listDef>
  <w:list w:ilfo="1">
    <w:ilst w:val="0" />
  </w:list>
</w:lists>
XML
	}


sub styles
	{
	<<'XML';
<w:styles>
  <w:versionOfBuiltInStylenames w:val="2" />
  <w:latentStyles w:defLockedState="off" w:latentStyleCount="276">
    <w:lsdException w:name="Normal" />
    <w:lsdException w:name="heading 1" />
    <w:lsdException w:name="heading 2" />
    <w:lsdException w:name="heading 3" />
    <w:lsdException w:name="heading 4" />
    <w:lsdException w:name="heading 5" />
    <w:lsdException w:name="heading 6" />
    <w:lsdException w:name="heading 7" />
    <w:lsdException w:name="heading 8" />
    <w:lsdException w:name="heading 9" />
    <w:lsdException w:name="toc 1" />
    <w:lsdException w:name="toc 2" />
    <w:lsdException w:name="toc 3" />
    <w:lsdException w:name="toc 4" />
    <w:lsdException w:name="toc 5" />
    <w:lsdException w:name="toc 6" />
    <w:lsdException w:name="toc 7" />
    <w:lsdException w:name="toc 8" />
    <w:lsdException w:name="toc 9" />
    <w:lsdException w:name="caption" />
    <w:lsdException w:name="Title" />
    <w:lsdException w:name="Default Paragraph Font" />
    <w:lsdException w:name="Subtitle" />
    <w:lsdException w:name="Strong" />
    <w:lsdException w:name="Emphasis" />
    <w:lsdException w:name="Table Grid" />
    <w:lsdException w:name="Placeholder Text" />
    <w:lsdException w:name="No Spacing" />
    <w:lsdException w:name="Light Shading" />
    <w:lsdException w:name="Light List" />
    <w:lsdException w:name="Light Grid" />
    <w:lsdException w:name="Medium Shading 1" />
    <w:lsdException w:name="Medium Shading 2" />
    <w:lsdException w:name="Medium List 1" />
    <w:lsdException w:name="Medium List 2" />
    <w:lsdException w:name="Medium Grid 1" />
    <w:lsdException w:name="Medium Grid 2" />
    <w:lsdException w:name="Medium Grid 3" />
    <w:lsdException w:name="Dark List" />
    <w:lsdException w:name="Colorful Shading" />
    <w:lsdException w:name="Colorful List" />
    <w:lsdException w:name="Colorful Grid" />
    <w:lsdException w:name="Light Shading Accent 1" />
    <w:lsdException w:name="Light List Accent 1" />
    <w:lsdException w:name="Light Grid Accent 1" />
    <w:lsdException w:name="Medium Shading 1 Accent 1" />
    <w:lsdException w:name="Medium Shading 2 Accent 1" />
    <w:lsdException w:name="Medium List 1 Accent 1" />
    <w:lsdException w:name="Revision" />
    <w:lsdException w:name="List Paragraph" />
    <w:lsdException w:name="Quote" />
    <w:lsdException w:name="Intense Quote" />
    <w:lsdException w:name="Medium List 2 Accent 1" />
    <w:lsdException w:name="Medium Grid 1 Accent 1" />
    <w:lsdException w:name="Medium Grid 2 Accent 1" />
    <w:lsdException w:name="Medium Grid 3 Accent 1" />
    <w:lsdException w:name="Dark List Accent 1" />
    <w:lsdException w:name="Colorful Shading Accent 1" />
    <w:lsdException w:name="Colorful List Accent 1" />
    <w:lsdException w:name="Colorful Grid Accent 1" />
    <w:lsdException w:name="Light Shading Accent 2" />
    <w:lsdException w:name="Light List Accent 2" />
    <w:lsdException w:name="Light Grid Accent 2" />
    <w:lsdException w:name="Medium Shading 1 Accent 2" />
    <w:lsdException w:name="Medium Shading 2 Accent 2" />
    <w:lsdException w:name="Medium List 1 Accent 2" />
    <w:lsdException w:name="Medium List 2 Accent 2" />
    <w:lsdException w:name="Medium Grid 1 Accent 2" />
    <w:lsdException w:name="Medium Grid 2 Accent 2" />
    <w:lsdException w:name="Medium Grid 3 Accent 2" />
    <w:lsdException w:name="Dark List Accent 2" />
    <w:lsdException w:name="Colorful Shading Accent 2" />
    <w:lsdException w:name="Colorful List Accent 2" />
    <w:lsdException w:name="Colorful Grid Accent 2" />
    <w:lsdException w:name="Light Shading Accent 3" />
    <w:lsdException w:name="Light List Accent 3" />
    <w:lsdException w:name="Light Grid Accent 3" />
    <w:lsdException w:name="Medium Shading 1 Accent 3" />
    <w:lsdException w:name="Medium Shading 2 Accent 3" />
    <w:lsdException w:name="Medium List 1 Accent 3" />
    <w:lsdException w:name="Medium List 2 Accent 3" />
    <w:lsdException w:name="Medium Grid 1 Accent 3" />
    <w:lsdException w:name="Medium Grid 2 Accent 3" />
    <w:lsdException w:name="Medium Grid 3 Accent 3" />
    <w:lsdException w:name="Dark List Accent 3" />
    <w:lsdException w:name="Colorful Shading Accent 3" />
    <w:lsdException w:name="Colorful List Accent 3" />
    <w:lsdException w:name="Colorful Grid Accent 3" />
    <w:lsdException w:name="Light Shading Accent 4" />
    <w:lsdException w:name="Light List Accent 4" />
    <w:lsdException w:name="Light Grid Accent 4" />
    <w:lsdException w:name="Medium Shading 1 Accent 4" />
    <w:lsdException w:name="Medium Shading 2 Accent 4" />
    <w:lsdException w:name="Medium List 1 Accent 4" />
    <w:lsdException w:name="Medium List 2 Accent 4" />
    <w:lsdException w:name="Medium Grid 1 Accent 4" />
    <w:lsdException w:name="Medium Grid 2 Accent 4" />
    <w:lsdException w:name="Medium Grid 3 Accent 4" />
    <w:lsdException w:name="Dark List Accent 4" />
    <w:lsdException w:name="Colorful Shading Accent 4" />
    <w:lsdException w:name="Colorful List Accent 4" />
    <w:lsdException w:name="Colorful Grid Accent 4" />
    <w:lsdException w:name="Light Shading Accent 5" />
    <w:lsdException w:name="Light List Accent 5" />
    <w:lsdException w:name="Light Grid Accent 5" />
    <w:lsdException w:name="Medium Shading 1 Accent 5" />
    <w:lsdException w:name="Medium Shading 2 Accent 5" />
    <w:lsdException w:name="Medium List 1 Accent 5" />
    <w:lsdException w:name="Medium List 2 Accent 5" />
    <w:lsdException w:name="Medium Grid 1 Accent 5" />
    <w:lsdException w:name="Medium Grid 2 Accent 5" />
    <w:lsdException w:name="Medium Grid 3 Accent 5" />
    <w:lsdException w:name="Dark List Accent 5" />
    <w:lsdException w:name="Colorful Shading Accent 5" />
    <w:lsdException w:name="Colorful List Accent 5" />
    <w:lsdException w:name="Colorful Grid Accent 5" />
    <w:lsdException w:name="Light Shading Accent 6" />
    <w:lsdException w:name="Light List Accent 6" />
    <w:lsdException w:name="Light Grid Accent 6" />
    <w:lsdException w:name="Medium Shading 1 Accent 6" />
    <w:lsdException w:name="Medium Shading 2 Accent 6" />
    <w:lsdException w:name="Medium List 1 Accent 6" />
    <w:lsdException w:name="Medium List 2 Accent 6" />
    <w:lsdException w:name="Medium Grid 1 Accent 6" />
    <w:lsdException w:name="Medium Grid 2 Accent 6" />
    <w:lsdException w:name="Medium Grid 3 Accent 6" />
    <w:lsdException w:name="Dark List Accent 6" />
    <w:lsdException w:name="Colorful Shading Accent 6" />
    <w:lsdException w:name="Colorful List Accent 6" />
    <w:lsdException w:name="Colorful Grid Accent 6" />
    <w:lsdException w:name="Subtle Emphasis" />
    <w:lsdException w:name="Intense Emphasis" />
    <w:lsdException w:name="Subtle Reference" />
    <w:lsdException w:name="Intense Reference" />
    <w:lsdException w:name="Book Title" />
    <w:lsdException w:name="Bibliography" />
    <w:lsdException w:name="TOC Heading" />
  </w:latentStyles>
  <w:style w:type="paragraph" w:default="on" w:styleId="Normal">
    <w:name w:val="Normal" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
      <w:lang w:val="EN-US" w:fareast="EN-US" w:bidi="AR-SA" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1" />
    <wx:uiName wx:val="Heading 1" />
    <w:basedOn w:val="HA" />
    <w:next w:val="HB" />
    <w:pPr>
      <w:listPr>
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="0" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2" />
    <wx:uiName wx:val="Heading 2" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="1" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="1" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3" />
    <wx:uiName wx:val="Heading 3" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="2" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="2" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading4">
    <w:name w:val="heading 4" />
    <wx:uiName wx:val="Heading 4" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="3" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="3" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading5">
    <w:name w:val="heading 5" />
    <wx:uiName wx:val="Heading 5" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="4" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="4" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading6">
    <w:name w:val="heading 6" />
    <wx:uiName wx:val="Heading 6" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="5" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="5" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading7">
    <w:name w:val="heading 7" />
    <wx:uiName wx:val="Heading 7" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="6" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="6" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading8">
    <w:name w:val="heading 8" />
    <wx:uiName wx:val="Heading 8" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="7" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="7" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading9">
    <w:name w:val="heading 9" />
    <wx:uiName wx:val="Heading 9" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:listPr>
        <w:ilvl w:val="8" />
        <w:ilfo w:val="1" />
      </w:listPr>
      <w:outlineLvl w:val="8" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:default="on" w:styleId="DefaultParagraphFont">
    <w:name w:val="Default Paragraph Font" />
  </w:style>
  <w:style w:type="table" w:default="on" w:styleId="TableNormal">
    <w:name w:val="Normal Table" />
    <wx:uiName wx:val="Table Normal" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
      <w:lang w:val="EN-US" w:fareast="EN-US" w:bidi="AR-SA" />
    </w:rPr>
    <w:tblPr>
      <w:tblInd w:w="0" w:type="dxa" />
      <w:tblCellMar>
        <w:top w:w="0" w:type="dxa" />
        <w:left w:w="108" w:type="dxa" />
        <w:bottom w:w="0" w:type="dxa" />
        <w:right w:w="108" w:type="dxa" />
      </w:tblCellMar>
    </w:tblPr>
  </w:style>
  <w:style w:type="list" w:default="on" w:styleId="NoList">
    <w:name w:val="No List" />
  </w:style>
  <w:style w:type="paragraph" w:styleId="HA">
    <w:name w:val="HA" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:tabs>
        <w:tab w:val="left" w:pos="2332" />
      </w:tabs>
      <w:spacing w:line="420" w:line-rule="at-least" />
      <w:ind w:right="2160" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="72" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Body">
    <w:name w:val="Body" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="60" w:line="220" w:line-rule="at-least" />
      <w:ind w:first-line="360" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HB">
    <w:name w:val="HB" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:tabs>
        <w:tab w:val="left" w:pos="2332" />
      </w:tabs>
      <w:spacing w:after="700" w:line="380" w:line-rule="at-least" />
      <w:ind w:right="720" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="56" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="AA">
    <w:name w:val="AA" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="AU">
    <w:name w:val="AU" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="26" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BB">
    <w:name w:val="BB" />
    <w:basedOn w:val="BL" />
    <w:pPr>
      <w:ind w:first-line="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BL">
    <w:name w:val="BL" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:widowControl w:val="off" />
      <w:tabs>
        <w:tab w:val="left" w:pos="720" />
      </w:tabs>
      <w:spacing w:after="60" w:line="220" w:line-rule="at-least" />
      <w:ind w:left="1200" w:right="720" w:hanging="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BH">
    <w:name w:val="BH" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="120" w:line="300" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BI">
    <w:name w:val="BI" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="60" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BIO">
    <w:name w:val="BIO" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BL1">
    <w:name w:val="BL1" />
    <w:basedOn w:val="BL" />
    <w:next w:val="BL" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BT">
    <w:name w:val="BT" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="480" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="60" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BX">
    <w:name w:val="BX" />
    <w:basedOn w:val="BL" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Callout">
    <w:name w:val="Callout" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="80" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Cdate">
    <w:name w:val="Cdate" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="60" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CDT">
    <w:name w:val="CDT" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="200" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CDT1">
    <w:name w:val="CDT1" />
    <w:basedOn w:val="CDT" />
    <w:next w:val="CDT" />
    <w:pPr>
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CDTX">
    <w:name w:val="CDTX" />
    <w:basedOn w:val="CDT" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:pBdr>
        <w:bottom w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CL">
    <w:name w:val="CL" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="720" />
      </w:tabs>
      <w:spacing w:before="80" w:line="260" w:line-rule="at-least" />
      <w:ind w:left="720" w:right="720" w:hanging="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CQ">
    <w:name w:val="CQ" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="EX" />
    <w:pPr>
      <w:spacing w:before="140" w:after="140" />
      <w:ind w:left="360" w:right="360" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EX">
    <w:name w:val="EX" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="140" w:after="140" />
      <w:ind w:left="360" w:right="360" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CR">
    <w:name w:val="CR" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="60" w:line="260" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="DED">
    <w:name w:val="DED" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="420" w:line-rule="at-least" />
      <w:jc w:val="center" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="24" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EH">
    <w:name w:val="EH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="ET" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="160" w:after="160" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="24" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ET">
    <w:name w:val="ET" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="120" />
      <w:ind w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EL">
    <w:name w:val="EL" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="172" />
        <w:tab w:val="left" w:pos="532" />
        <w:tab w:val="left" w:pos="892" />
        <w:tab w:val="left" w:pos="1252" />
        <w:tab w:val="left" w:pos="1612" />
        <w:tab w:val="left" w:pos="1972" />
        <w:tab w:val="left" w:pos="2332" />
      </w:tabs>
      <w:spacing w:before="240" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ELX">
    <w:name w:val="ELX" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="172" />
        <w:tab w:val="left" w:pos="532" />
        <w:tab w:val="left" w:pos="892" />
        <w:tab w:val="left" w:pos="1252" />
        <w:tab w:val="left" w:pos="1612" />
        <w:tab w:val="left" w:pos="1972" />
        <w:tab w:val="left" w:pos="2332" />
      </w:tabs>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EMH">
    <w:name w:val="EMH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="EMT" />
    <w:pPr>
      <w:keepNext />
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="680" w:after="160" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="28" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EMT">
    <w:name w:val="EMT" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="120" />
      <w:ind w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Equation">
    <w:name w:val="Equation" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="200" w:after="120" />
      <w:ind w:left="173" w:right="173" />
      <w:jc w:val="center" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="FC">
    <w:name w:val="FC" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
      </w:tabs>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NCPX">
    <w:name w:val="NCPX" />
    <w:basedOn w:val="NCP" />
    <w:next w:val="NO" />
    <w:pPr>
      <w:spacing w:after="60" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NCP">
    <w:name w:val="NCP" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="1800" />
      </w:tabs>
      <w:ind w:left="720" w:right="1440" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NO">
    <w:name w:val="NO" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
      </w:tabs>
      <w:spacing w:after="60" />
      <w:ind w:left="720" w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="FGFN">
    <w:name w:val="FGFN" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="120" />
      <w:ind w:left="360" w:right="360" />
      <w:jc w:val="both" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="FN">
    <w:name w:val="FN" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="FC" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="100" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="FTN">
    <w:name w:val="FTN" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="230" />
      </w:tabs>
      <w:spacing w:before="60" w:after="60" w:line="260" w:line-rule="at-least" />
      <w:ind w:left="230" w:hanging="230" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GlossDef">
    <w:name w:val="GlossDef" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="60" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GlossFT">
    <w:name w:val="GlossFT" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="60" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GlossHead">
    <w:name w:val="GlossHead" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="320" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="28" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GlossTerm">
    <w:name w:val="GlossTerm" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="60" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GlossTitle">
    <w:name w:val="GlossTitle" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:after="260" w:line="540" w:line-rule="at-least" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="48" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="GroupTitlesIX">
    <w:name w:val="GroupTitlesIX" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="200" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HC">
    <w:name w:val="HC" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="680" w:after="160" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="28" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HD">
    <w:name w:val="HD" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="360" w:after="80" w:line="300" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HE">
    <w:name w:val="HE" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="120" w:line="300" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HF">
    <w:name w:val="HF" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="80" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="HG">
    <w:name w:val="HG" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="120" w:line="300" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="IndexIX">
    <w:name w:val="IndexIX" />
    <w:basedOn w:val="Normal" />
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NumCDT">
    <w:name w:val="NumCDT" />
    <w:basedOn w:val="CDT" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="360" />
      </w:tabs>
      <w:ind w:left="360" w:hanging="360" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NCP1">
    <w:name w:val="NCP1" />
    <w:basedOn w:val="NCP" />
    <w:next w:val="NCP" />
    <w:pPr>
      <w:spacing w:before="60" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NumCDT1">
    <w:name w:val="NumCDT1" />
    <w:basedOn w:val="CDT1" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="360" />
      </w:tabs>
      <w:spacing w:before="120" />
      <w:ind w:left="360" w:hanging="360" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NumCDTX">
    <w:name w:val="NumCDTX" />
    <w:basedOn w:val="CDTX" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="360" />
      </w:tabs>
      <w:spacing w:after="120" />
      <w:ind w:left="360" w:hanging="360" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="CD4">
    <w:name w:val="CD4" />
    <w:basedOn w:val="DefaultParagraphFont" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="20" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="CD1">
    <w:name w:val="CD1" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <w:color w:val="000000" />
      <w:sz w:val="20" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="INH">
    <w:name w:val="INH" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="260" w:line-rule="at-least" />
      <w:ind w:left="720" w:hanging="720" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LC">
    <w:name w:val="LC" />
    <w:basedOn w:val="LC2" />
    <w:next w:val="LC2" />
    <w:pPr>
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LC2">
    <w:name w:val="LC2" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="200" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Level1">
    <w:name w:val="Level 1" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="260" w:line-rule="at-least" />
      <w:ind w:left="720" w:hanging="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Level2">
    <w:name w:val="Level 2" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="260" w:line-rule="at-least" />
      <w:ind w:left="532" w:hanging="360" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Level3">
    <w:name w:val="Level 3" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="260" w:line-rule="at-least" />
      <w:ind w:left="792" w:hanging="432" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LH">
    <w:name w:val="LH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="240" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="24" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LOC">
    <w:name w:val="LOC" />
    <w:basedOn w:val="ISBN" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ISBN">
    <w:name w:val="ISBN" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BodyNoIndent">
    <w:name w:val="BodyNoIndent" />
    <w:basedOn w:val="Body" />
    <w:pPr>
      <w:spacing w:before="120" />
      <w:ind w:first-line="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LSH">
    <w:name w:val="LSH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="100" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LX">
    <w:name w:val="LX" />
    <w:basedOn w:val="LC2" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:pBdr>
        <w:bottom w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="MH">
    <w:name w:val="MH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="MN" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="100" />
      <w:ind w:left="1440" w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="MN">
    <w:name w:val="MN" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
      </w:tabs>
      <w:spacing w:after="100" />
      <w:ind w:left="1440" w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="CD3">
    <w:name w:val="CD3" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="20" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NL">
    <w:name w:val="NL" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="720" />
      </w:tabs>
      <w:spacing w:after="60" w:line="220" w:line-rule="at-least" />
      <w:ind w:left="720" w:right="720" w:hanging="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NL1">
    <w:name w:val="NL1" />
    <w:basedOn w:val="NL" />
    <w:next w:val="NL" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NLB">
    <w:name w:val="NLB" />
    <w:basedOn w:val="NL" />
    <w:pPr>
      <w:ind w:first-line="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NLC">
    <w:name w:val="NLC" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:line="200" w:line-rule="at-least" />
      <w:ind w:left="720" w:right="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NLCX">
    <w:name w:val="NLCX" />
    <w:basedOn w:val="NLC" />
    <w:next w:val="NLB" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NLX">
    <w:name w:val="NLX" />
    <w:basedOn w:val="NL" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NOX">
    <w:name w:val="NOX" />
    <w:basedOn w:val="NO" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="PD">
    <w:name w:val="PD" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="60" w:after="60" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="0000FF" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="PN">
    <w:name w:val="PN" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="PT" />
    <w:pPr>
      <w:keepNext />
      <w:tabs>
        <w:tab w:val="left" w:pos="1051" />
        <w:tab w:val="left" w:pos="2692" />
      </w:tabs>
      <w:spacing w:before="860" w:after="380" w:line="380" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
      <w:smallCaps />
      <w:color w:val="000000" />
      <w:sz w:val="72" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="PT">
    <w:name w:val="PT" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:tabs>
        <w:tab w:val="left" w:pos="2332" />
      </w:tabs>
      <w:spacing w:after="1800" w:line="420" w:line-rule="at-least" />
      <w:ind w:left="2332" w:right="2160" w:hanging="2332" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="72" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Preface">
    <w:name w:val="Preface" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="120" w:line="240" w:line-rule="at-least" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="PTFT">
    <w:name w:val="PTFT" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Quotation">
    <w:name w:val="Quotation" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="EX" />
    <w:pPr>
      <w:spacing w:before="140" w:after="140" />
      <w:ind w:left="360" w:right="360" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="RHR">
    <w:name w:val="RHR" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="center" w:pos="3240" />
        <w:tab w:val="right" w:pos="6480" />
      </w:tabs>
      <w:jc w:val="right" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="16" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="RHV">
    <w:name w:val="RHV" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="center" w:pos="3240" />
        <w:tab w:val="right" w:pos="6480" />
      </w:tabs>
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="16" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SB">
    <w:name w:val="SB" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="120" />
      <w:ind w:right="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBX">
    <w:name w:val="SBX" />
    <w:basedOn w:val="SB" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:pBdr>
        <w:bottom w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SH">
    <w:name w:val="SH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="SB" />
    <w:pPr>
      <w:keepNext />
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="680" w:after="40" />
      <w:ind w:right="950" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="28" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TB">
    <w:name w:val="TB" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:after="80" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TB1">
    <w:name w:val="TB1" />
    <w:basedOn w:val="TB" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TBFN">
    <w:name w:val="TBFN" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="475" />
      </w:tabs>
      <w:spacing w:before="60" w:line="260" w:line-rule="at-least" />
      <w:ind w:left="475" w:hanging="245" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TBX">
    <w:name w:val="TBX" />
    <w:basedOn w:val="TB" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TCCP">
    <w:name w:val="TCCP" />
    <w:basedOn w:val="TB" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TCEM">
    <w:name w:val="TCEM" />
    <w:basedOn w:val="TB" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TCH">
    <w:name w:val="TCH" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:line="200" w:line-rule="exact" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="18" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TH">
    <w:name w:val="TH" />
    <w:basedOn w:val="Normal" />
    <w:next w:val="TS" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
      </w:tabs>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TS">
    <w:name w:val="TS" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
      </w:tabs>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TIH">
    <w:name w:val="TIH" />
    <w:basedOn w:val="NoteH" />
    <w:next w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:tabs>
        <w:tab w:val="left" w:pos="835" />
        <w:tab w:val="left" w:pos="1152" />
        <w:tab w:val="left" w:pos="1267" />
      </w:tabs>
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NoteH">
    <w:name w:val="NoteH" />
    <w:basedOn w:val="NO" />
    <w:next w:val="NO" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="clear" w:pos="835" />
        <w:tab w:val="clear" w:pos="1152" />
        <w:tab w:val="left" w:pos="1584" />
      </w:tabs>
      <w:spacing w:before="100" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TitleTOCIndex">
    <w:name w:val="TitleTOC/Index" />
    <w:basedOn w:val="Normal" />
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:i />
      <w:color w:val="000000" />
      <w:sz w:val="48" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SC2">
    <w:name w:val="SC2" />
    <w:basedOn w:val="NCP" />
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TN">
    <w:name w:val="TN" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:keepNext />
      <w:spacing w:before="100" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <wx:font wx:val="Times" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="UC">
    <w:name w:val="UC" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="273" />
      </w:tabs>
      <w:spacing w:before="60" w:after="60" />
      <w:ind w:left="273" w:right="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="UL">
    <w:name w:val="UL" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="left" w:pos="273" />
      </w:tabs>
      <w:spacing w:after="60" />
      <w:ind w:left="274" w:right="720" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="UL1">
    <w:name w:val="UL1" />
    <w:basedOn w:val="UL" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ULX">
    <w:name w:val="ULX" />
    <w:basedOn w:val="UL" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="XREF">
    <w:name w:val="XREF" />
    <w:basedOn w:val="Normal" />
    <w:pPr>
      <w:spacing w:before="120" w:after="120" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <wx:font wx:val="Times New Roman" />
      <w:color w:val="000000" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="CD2">
    <w:name w:val="CD2" />
    <w:rPr>
      <w:rFonts w:ascii="Courier New" w:h-ansi="Courier New" />
      <w:b />
      <w:color w:val="000000" />
      <w:sz w:val="20" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="E1">
    <w:name w:val="E1" />
    <w:rPr>
      <w:b />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="E2">
    <w:name w:val="E2" />
    <w:rPr>
      <w:i />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="C1">
    <w:name w:val="C1" />
    <w:basedOn w:val="CDT" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:before="240" w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="BT1">
    <w:name w:val="BT1" />
    <w:basedOn w:val="BT" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EN">
    <w:name w:val="EN" />
    <w:basedOn w:val="EH" />
    <w:pPr>
      <w:pBdr>
        <w:top w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:before="680" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i w:val="off" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="IXI">
    <w:name w:val="IXI" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="SUB1">
    <w:name w:val="SUB1" />
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <w:sz w:val="16" />
      <w:vertAlign w:val="subscript" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="SUP1">
    <w:name w:val="SUP1" />
    <w:rPr>
      <w:rFonts w:ascii="Times" w:h-ansi="Times" />
      <w:sz w:val="18" />
      <w:vertAlign w:val="superscript" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="XIND">
    <w:name w:val="XIND" />
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:h-ansi="Times New Roman" />
      <w:sz w:val="22" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EMX">
    <w:name w:val="EMX" />
    <w:basedOn w:val="EMT" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:pBdr>
        <w:bottom w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="FT">
    <w:name w:val="FT" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CO">
    <w:name w:val="CO" />
    <w:basedOn w:val="Body" />
    <w:pPr>
      <w:spacing w:after="120" />
      <w:ind w:first-line="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
      <w:i />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="QQ">
    <w:name w:val="QQ" />
    <w:basedOn w:val="PD" />
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:color w:val="FF0000" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NLC1">
    <w:name w:val="NLC1" />
    <w:basedOn w:val="NLC" />
    <w:pPr>
      <w:spacing w:before="60" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="character" w:styleId="E3">
    <w:name w:val="E3" />
    <w:rPr>
      <w:b />
      <w:i />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="WAH">
    <w:name w:val="WAH" />
    <w:basedOn w:val="TIH" />
    <w:next w:val="WA" />
    <w:pPr>
      <w:tabs>
        <w:tab w:val="clear" w:pos="1267" />
        <w:tab w:val="left" w:pos="1800" />
      </w:tabs>
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="WA">
    <w:name w:val="WA" />
    <w:basedOn w:val="NO" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETNL">
    <w:name w:val="ETNL" />
    <w:basedOn w:val="NL" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETNL1">
    <w:name w:val="ETNL1" />
    <w:basedOn w:val="ETNL" />
    <w:next w:val="ETNL" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETBL">
    <w:name w:val="ETBL" />
    <w:basedOn w:val="BL" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETBL1">
    <w:name w:val="ETBL1" />
    <w:basedOn w:val="ETBL" />
    <w:next w:val="ETBL" />
    <w:pPr>
      <w:spacing w:before="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETBX">
    <w:name w:val="ETBX" />
    <w:basedOn w:val="ETBL" />
    <w:next w:val="ET" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ESH">
    <w:name w:val="ESH" />
    <w:basedOn w:val="EH" />
    <w:next w:val="ET" />
    <w:pPr>
      <w:spacing w:before="240" w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b w:val="off" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETNB">
    <w:name w:val="ETNB" />
    <w:basedOn w:val="Normal" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="IT">
    <w:name w:val="IT" />
    <w:basedOn w:val="Body" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TIX">
    <w:name w:val="TIX" />
    <w:basedOn w:val="TI" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="WAX">
    <w:name w:val="WAX" />
    <w:basedOn w:val="NO" />
    <w:pPr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CT">
    <w:name w:val="CT" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:next w:val="Credits" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Credits">
    <w:name w:val="Credits" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:next w:val="CT" />
    <w:pPr>
      <w:spacing w:before="0" w:after="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Pubname">
    <w:name w:val="Pubname" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CTTOC">
    <w:name w:val="CTTOC" />
    <w:basedOn w:val="BodyNoIndent" />
    <w:pPr>
      <w:spacing w:before="0" />
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="PTTOC">
    <w:name w:val="PTTOC" />
    <w:basedOn w:val="CTTOC" />
    <w:pPr>
      <w:spacing w:before="60" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:b />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCPART">
    <w:name w:val="TOCPART" />
    <w:basedOn w:val="PTTOC" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHA">
    <w:name w:val="TOCHA" />
    <w:basedOn w:val="CTTOC" />
    <w:rPr>
      <wx:font wx:val="Arial" />
      <w:i />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHB">
    <w:name w:val="TOCHB" />
    <w:basedOn w:val="CTTOC" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHC">
    <w:name w:val="TOCHC" />
    <w:basedOn w:val="TOCHB" />
    <w:pPr>
      <w:ind w:left="144" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHD">
    <w:name w:val="TOCHD" />
    <w:basedOn w:val="TOCHC" />
    <w:pPr>
      <w:ind w:left="288" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHE">
    <w:name w:val="TOCHE" />
    <w:basedOn w:val="TOCHD" />
    <w:pPr>
      <w:ind w:left="432" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHF">
    <w:name w:val="TOCHF" />
    <w:basedOn w:val="TOCHE" />
    <w:pPr>
      <w:ind w:left="576" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOCHG">
    <w:name w:val="TOCHG" />
    <w:basedOn w:val="TOCHF" />
    <w:pPr>
      <w:ind w:left="720" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="EL2">
    <w:name w:val="EL2" />
    <w:basedOn w:val="EL" />
    <w:pPr>
      <w:spacing w:before="0" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LCX">
    <w:name w:val="LCX" />
    <w:basedOn w:val="LC2" />
    <w:next w:val="Body" />
    <w:pPr>
      <w:pBdr>
        <w:bottom w:val="single" w:sz="6" wx:bdrwidth="15" w:space="1" w:color="auto" />
      </w:pBdr>
      <w:spacing w:after="240" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="LN">
    <w:name w:val="LN" />
    <w:basedOn w:val="LH" />
    <w:pPr>
      <w:pBdr>
        <w:top w:val="single" w:sz="4" wx:bdrwidth="10" w:space="1" w:color="auto" />
      </w:pBdr>
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Times New Roman" />
      <w:i w:val="off" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETNLB">
    <w:name w:val="ETNLB" />
    <w:basedOn w:val="Normal" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SC">
    <w:name w:val="SC" />
    <w:basedOn w:val="NCP1" />
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SCX">
    <w:name w:val="SCX" />
    <w:basedOn w:val="NCPX" />
    <w:rPr>
      <wx:font wx:val="Courier New" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBBL">
    <w:name w:val="SBBL" />
    <w:basedOn w:val="BL" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBBL1">
    <w:name w:val="SBBL1" />
    <w:basedOn w:val="BL1" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBBX">
    <w:name w:val="SBBX" />
    <w:basedOn w:val="BX" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBNL">
    <w:name w:val="SBNL" />
    <w:basedOn w:val="NL" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBNL1">
    <w:name w:val="SBNL1" />
    <w:basedOn w:val="NL1" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="SBNLX">
    <w:name w:val="SBNLX" />
    <w:basedOn w:val="NLX" />
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:h-ansi="Arial" />
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TI">
    <w:name w:val="TI" />
    <w:basedOn w:val="NO" />
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ETNLX">
    <w:name w:val="ETNLX" />
    <w:basedOn w:val="ETNL" />
    <w:next w:val="ET" />
    <w:pPr>
      <w:spacing w:after="120" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="NI">
    <w:name w:val="NI" />
    <w:basedOn w:val="NO" />
    <w:pPr>
      <w:ind w:left="1440" />
    </w:pPr>
    <w:rPr>
      <wx:font wx:val="Arial" />
    </w:rPr>
  </w:style>
</w:styles>
XML
	}

=item document_footer

=cut

sub document_footer
	{
	<<'XML';
</w:body>
</w:wordDocument>
XML
	}

=item chapter_number_style

=item head1_style, head2_style, head3_style, head4_style

The paragraph styles to use with each heading level. By default these are
C<Head1Style>, and so on.

=cut

sub start_Document {
	$_[0]->{chapter_number} = 0;
	$_[0]->{item_number}    = 1;
	$_[0]->SUPER::start_Document;
	}

sub start_head0 {
	$_[0]->make_para( $_[0]->chapter_number_style, $_[0]->{chapter_number}++ );
	$_[0]->_header_start( $_[0]->head0_style, 0 );
	}

sub start_head1 {
	$_[0]->_header_start( $_[0]->head1_style, 1 );
	return unless $_[0]->{chapter_number} > 1;
	my $pad = $_[0]->get_pad;
	$_[0]->{$pad} .= 'Item ' . $_[0]->{item_number}++ . '. ';
	}

sub chapter_number_style { 'HA' }
sub head0_style          { 'HB' }
sub head1_style          { 'HC' }
sub head2_style          { 'HD' }
sub head3_style          { 'HE' }
sub head4_style          { 'HF' }

=item normal_para_style

The paragraph style for normal Pod paragraphs. You don't have to use this
for all normal paragraphs, but you'll have to override and extend more things
to get everything just how you like. You'll need to override C<start_Para> to
get more variety.

=cut

sub normal_para_style   { 'BodyNoIndent' }

=item bullet_para_style

Like C<bullet_para_style>, but for paragraphs under C<=item>.

=cut

sub first_item_para_style     { 'BL1'          }
sub middle_item_para_style    { 'BL'           }
sub last_item_para_style      { 'BLX'          }
sub item_subpara_style        { 'BodyNoIndent' }

=item inline_code_style

The character style that goes with C<< CE<lt>> >>.

=cut

sub inline_code_style	{ 'CodeCharacterStyle' }

=item inline_url_style

The character style that goes with C<< UE<lt>E<gt> >>.

=cut

sub inline_url_style    { 'URLCharacterStyle'  }

=item inline_italic_style

The character style that goes with C<< IE<lt>> >>.

=cut

sub inline_italic_style { 'ItalicCharacterStyle' }

=item inline_bold_style

The character style that goes with C<< BE<lt>> >>.

=cut

sub inline_bold_style   { 'BoldCharacterStyle' }

sub single_code_line_style { 'C1' }
sub first_code_line_style  { 'CDT1' }
sub middle_code_line_style { 'CDT'  }
sub last_code_line_style   { 'CDTX' }

sub bold_char_style        { 'E1' }

sub inline_code_char_style { 'CD1' }

sub italic_char_style      { 'E2' }

=back

=head1 TO DO


=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This is an abandoned module. You can adopt it if you like:

	https://pause.perl.org/pause/authenquery?ACTION=pause_04about#takeover

This source is in Github:

	http://github.com/briandfoy/pod-wordml

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the Artistic License 2.0.

=cut

1;
