package SIL::Shoe::Backend::openoffice;
use OpenOffice::OODoc;
use Image::Size;

use encoding "utf8", STDERR => "utf8";

$VERSION="0.3";     # VER       06-DEC-2006     renamed and added backend properties, single or double column, documentation
# $VERSION="0.2";   # VER       20-JUN-2006     splits files, allows section styles with a stylesheet document
# $VERSION="0.1";   # VER       09-JUN-2006     Original

sub new
{
    # perhaps need to open an output file here?
    # also may need configuration for css
    my ($class, $outfile, $css, $props) = @_;
    my ($self) = {};
    my ($doc,$varstyle,$filename,$suffix);


    $self->{'props'} = $props;

	print STDERR "\nnew" if ($self->{'props'}{'debug'});
	print STDERR "\n   class: $class" if ($self->{'props'}{'debug'});
	print STDERR "\n   outfile: $outfile" if ($self->{'props'}{'debug'});
	print STDERR "\n   css: $css" if ($self->{'props'}{'debug'});

	if ( $self->{'props'}{'debug'} ) {
		print STDERR "\n   props: ";
		for $k (keys %{$props}) {
			print STDERR "\n        $k:  $props->{$k}";
		}
	}

	if ($props->{'styles_as_variable'}) {
		foreach $varstyle ( split(',',$props->{'styles_as_variable'}) ) {
			$self->{'styles_as_variable'}{$varstyle} = 1;
		}
	}

	if ($props->{'styles_as_reference'}) {
		foreach $varstyle ( split(',',$props->{'styles_as_reference'}) ) {
			$self->{'styles_as_reference'}{$varstyle} = 1;
		}
	}

	# split up the input filename:
	if ($outfile) {
		if ($outfile =~ /^(.*)\.([^.]{0,4})$/ ) { 
			$filename = $1;
			$suffix = $2;
		} else {
			$filename = $outfile;
		}
		$suffix = "odt" if (not $suffix) ;
		$self->{'filename'} = $filename;
		$self->{'suffix'} = $suffix;
	} else {
    	die "Openoffice file name is required.\n"; 
	}

	if (not $self->{'props'}{'split_files'}) {
		$self->{'doc'} = open_document($filename.".".$suffix);
	}

	if ($css) {
		$self->{'css'} = open_document($css);

	}

	print STDERR "\n/new" if ($self->{'props'}{'debug'});
    return bless $self, $class;
}

sub open_document
{
	my ($outfile) = @_;
	my ($doc);

    if ($outfile) {
    	if (-f $outfile) {
    		$doc = ooDocument( file => $outfile, local_encoding => '' )
			|| die "Can't open $outfile";
		} else {
    		$doc = ooDocument( file => $outfile, create => 'text' ,local_encoding => '' )
			|| die "Can't open $outfile";
		}
	}

	if (not $doc) {
		die "Could not open File $outfile\n";
	}

	return $doc;

}



sub start_section
{
    my ($self, $type, $name) = @_;
	my ($doc, $first, $last, $node, $nextnode, $sec_name);


	print STDERR "\nstart_section type: $type name: $name" if ($self->{'props'}{'debug'});

	$bookmark=$type . "_" . $name;
	print STDERR "\n  Bookmark name is : $bookmark" if ($self->{'props'}{'debug'});

	if ($self->{'props'}{'split_files'}) {
		$self->{'doc'} = open_document($self->{'filename'} . "-" . $bookmark . "." . $self->{'suffix'});
	}

	$doc = $self->{'doc'};

	# this is a really messy way of finding the highest level section or paragraph bounding the bookmarked area.
	# and ancestor:: selects ALL the ancestors, not just the highest one.  I don't know enough about xpath
	# to figure out exactly what to do here.  It seems sometimes we have text:p/text:section/text:p/text:bookmark
	# so I may not be getting the top one, which is the one I want.

	$first = $doc->getElement("//text:bookmark-start[\@text:name=\"$bookmark\"]/ancestor::text:section",0);
	if (not $first) {$first = $doc->getElement("//text:bookmark-start[\@text:name=\"$bookmark\"]/ancestor::text:p",0);}
	if (not $first) {$first = $doc->getElement("//text:bookmark[\@text:name=\"$bookmark\"]/ancestor::text:p",0);}
	if (not $first) {$first = $doc->getElement("//text:bookmark[\@text:name=\"$bookmark\"]/ancestor::text:section",0);}

	$last = $doc->getElement("//text:bookmark-end[\@text:name=\"$bookmark\"]/ancestor::text:section",0);
	if (not $last) {$last = $doc->getElement("//text:bookmark-end[\@text:name=\"$bookmark\"]/ancestor::text:p",0);}
	# if there is not last, treat it as if they are the same.  This will keep them from deleting.
	if (not $last) {$last = $first};

	if ($first) {
		#if last == first then keep it for now.
		if ($last ne $first) {
			for ($node=$first->{'next_sibling'}; $node ne $last; ) {
				$nextnode = $node->{'next_sibling'};
				print STDERR "\n  deleting node " . $node if ($self->{'props'}{'debug'} > 1);
				$doc->removeElement($node);
				$node = $nextnode;
			}
			$doc-> removeElement($last);
		}
	} else {
		# if the bookmark does not exist, append to the end of the document;
		print STDERR "\nappending paragraph" if ($self->{'props'}{'debug'});
		$first = $doc->appendParagraph(text => "APPENDED PARAGRAPH");
	}
	
	$sec_name = "section_".$bookmark;
	$self->{'styles'}->{$sec_name} = 'section';
	$self->{'sec_name'} = $sec_name;

	# keep first around as a starting point to insert the XML
	$self->{'first'} = $first;
	$self->{'cur'} = $first;
	$self->{'xml'} = '';
	$self->{'curr_bookmark'} = $bookmark;
	$self->{'secnum'} = 0;
	# setting the first node for bookmarking
	$self->{'first_node'} = 1;

	print STDERR "\n/start_section" if ($self->{'props'}{'debug'});

}

sub end_section
{
    my ($self, $type, $name) = @_;
	
	print STDERR "\nend_section type: $type name: $name" if ($self->{'props'}{'debug'});

	if ($self->{'curr_para'})
	{
		$self->{'xml'} .= "<text:bookmark-end text:name='" . $self->{'curr_bookmark'} . "' />";
	}

	$self->outputXML('close_section');

	$self->{'cur'} = '';

	$self->{'doc'}->removeElement($self->{'first'});

	if ($self->{'props'}{'split_files'}) {
		$self->close_document();
	}
	
	print STDERR "\n/end_section" if ($self->{'props'}{'debug'});
}

sub start_letter
{
    my ($self) = @_;

	print STDERR "\nstart_letter" if ($self->{'props'}{'debug'} > 1);

	$self->outputXML('close_section');

	print STDERR "\n/start_letter" if ($self->{'props'}{'debug'} > 1);

}

sub end_letter
{

	my ($self) = @_;
	my ($secnum);

	print STDERR "\nend_letter" if ($self->{'props'}{'debug'} > 1);

	$self->outputXML();

	$secnum = $self->{'secnum'}++;
	$self->{'xml'} .= "<text:section text:name='". $self->{'sec_name'} ."_" . $secnum . "' text:style-name='" . $self->{'sec_name'} . "' >";

	$self->{'curr_sect'} = 1;

	print STDERR "\n/end_letter" if ($self->{'props'}{'debug'} > 1);
}


sub new_para
{
    my ($self, $type) = @_;
	print STDERR "\new_para" if ($self->{'props'}{'debug'} > 1);
    
	$self->{'styles'}->{$type} = 'paragraph';

	$self->outputXML();

	$self->{'xml'} .= "<text:p text:style-name='$type' >";

	if ($self->{'first_node'}) {
		$self->{'xml'} .= "<text:bookmark-start text:name='" . $self->{'curr_bookmark'} . "' />";
		$self->{'first_node'} = 0;
	}

	$self->{'curr_para'} = 1;
	$self->{'start_para'} = 1;

	print STDERR "\n/new_para" if ($self->{'props'}{'debug'} > 1);
}

sub output_tab
{
    my ($self) = @_;
	$self->{'xml'} .= "<text:tab />" unless ($self->{'start_para'});
	print STDERR "\noutput_tab" if ($self->{'props'}{'debug'} > 1);
}

sub output_space
{    
    my ($self) = @_;
    
	$self->{'xml'} .= '<text:s text:c="1"/>' unless ($self->{'start_para'});
	print STDERR "\noutput_space" if ($self->{'props'}{'debug'} > 1);
}

sub output_newline
{
    my ($self) = @_;

    $self->{'xml'} .= '<text:line-break/>' unless ($self->{'start_para'});
    print STDERR "\noutput_newline" if ($self->{'props'}{'debug'} > 1);
}

sub output
{
    my ($self, $text) = @_;
    
	$self->{'xml'} .= xmlescape($text);
    $self->{'start_para'} = 0;

	print STDERR "\noutput" if ($self->{'props'}{'debug'} > 1);

}

sub char_style
{
    my ($self, $style, $text) = @_;
    
    return $self->output($text) unless ($style);
	$self->{'styles'}->{$style} = 'text';

	$self->{'xml'} .= "<text:span text:style-name='$style'>";

	if ($self->{'styles_as_variable'}{$style}) {
		$self->{'xml'} .= "<text:variable-set text:name='$style' office:value-type='string'>";
	}

	$self ->{'xml'} .= xmlescape($text);

	if ($self->{'styles_as_variable'}{$style}) {
		$self->{'xml'} .= "</text:variable-set>";
	}
	
	
	$self ->{'xml'} .= "</text:span>";

	if ($self->{'styles_as_reference'}{$style}) {
		$self->{'xml'} .= '<text:reference-mark text:name = "';
	        $self ->{'xml'} .= xmlescape($text);
		$self->{'xml'} .= '"/>';
	}

	$self->{'start_para'} = 0;

	print STDERR "\nchar_style" if ($self->{'props'}{'debug'} > 1);
}

sub picture
{
    my ($self, $style, $fname, $scale) = @_;
    my ($x, $y) = map {$_ * $scale} imgsize($fname);
    my ($image) = $self->{'doc'}->createImageElement(
        $fname,
        style => $style,
        size => "$x pt, $y pt",
        import => $fname);
    push (@{$self->{'images'}}, $image);

    print STDERR "\nPicture: $fname in $style" if ($self->{'props'}{'debug'} > 1);
}

sub finish
{
    my ($self) = @_;

	print STDERR "\nfinish" if ($self->{'props'}{'debug'});

	if (not $self->{'props'}{'split_files'}) {
		$self->close_document();
	}

	print STDERR "\n/finish\n" if ($self->{'props'}{'debug'});
}

sub get_csssection_style
{
	my ($self,$style) = @_;
	my ($css,$sec,$sse, $mysse);
	#find a section with the right name
	#find that section's style
	#pull that sections's style
	#change its name

	$css = $self->{'css'};
	return "" if not ($css);

	$ss = $css->sectionStyle($style);
	return "" if not ($ss);

	$sse = $css->getStyleElement($ss);
    $mysse = $sse->copy;

	$css->styleName($mysse,$style);
	return $css->exportXMLElement($mysse);
}

sub close_document
{
    my ($self) = @_;
	my ($doc,$styles,$docstyle,$element,$stylexml);
	print STDERR "\nclose_document" if ($self->{'props'}{'debug'});

	$doc = $self->{'doc'};
	$styles = $self->{'styles'};
	$docstyle = ooStyles( file => $doc );
    $docstyle->{'retrieve_by'} = 'display-name';

	foreach $style (keys %$styles) {
		print STDERR "\n  looking at style ". $style . " type " . $styles->{$style}  if ($self->{'props'}{'debug'});
		if ($styles->{$style} eq "section") {
			#automatic style in content.xml, so use $doc and not $docstyle.

			# FIRST if $css is used, look in that file for a section by the style name.
			# If not, add a default one.  Otherwise take one from the $css document.
			$stylexml = $self->get_csssection_style($style);

				# if stylxml then remove all existing styles. then use it
				# if not, then if existing style, use it
				# if not that, then create default style

			if ($stylexml ne "" ) {
				@conflictstyles = $doc->selectStyleElementsByName($style, family => 'section');
				for $s (@conflictstyles) {
					$doc->removeElement($s);
				}
				$element = $doc->createStyle($style, family => 'section');
				print STDERR "\n    using external style: $style" if ($self->{'props'}{'debug'});
				$doc->replaceElement($element, $doc->createElement($stylexml));
			}  else {

				$element = $doc->getStyleElement($style, family => 'section');
			
				# if there is no section style by that name, and if we are in double column mode,
				# create a double column section style
				if ((not $element) && ($self->{'props'}{'columns'} == 2)) {
					$element = $doc->createStyle($style, family => 'section');
					$stylexml = '<style:style style:name="'. $style .'" style:family="section">'.
						 '<style:section-properties text:dont-balance-text-columns="false" style:editable="false">'.
						  '<style:columns fo:column-count="2" fo:column-gap="0.1in">'.
						   '<style:column style:rel-width="4818*" fo:start-indent="0in" fo:end-indent="0in" /> '.
						   '<style:column style:rel-width="4819*" fo:start-indent="0in" fo:end-indent="0in" /> '.
						  '</style:columns>'.
						 '</style:section-properties>'.
						'</style:style>';
					$doc->replaceElement($element,$doc->createElement($stylexml));
				}
			}
		} else {
#			if (not $docstyle->getStyleElement($style)) {
            if (not $docstyle->getNodeByXPath("//style:style[\@style:display-name=\"$style\" or \@style:name=\"$style\"]")) {
				print STDERR "\n    adding style $style" if ($self->{'props'}{'debug'});
				$docstyle->createStyle($style, family => $styles->{$style});
			}
		}
	}

	$doc->save();
	print "\nSaved file: " . $doc->{file} . "\n";

	# clean up all the variables, styles, etc.
	$self->{'doc'} = "";
	$self->{'styles'} = {};
	$self->{'xml'} = "";
	$self->{'curr_para'} = 0;
	$self->{'curr_sect'} = 0;

	print STDERR "\n/close_document\n" if ($self->{'props'}{'debug'});
}

sub outputXML
{
    my ($self,$close_sect) = @_;

	print STDERR "\noutputXML: $close_sect" if ($self->{'props'}{'debug'} > 1);

	if ($self->{'curr_para'}) {
		$self->{'xml'} .= "</text:p>";
		$self->{'curr_para'} = 0;
	}

	if ($close_sect && $self->{'curr_sect'}) {
		$self->{'xml'} .= "</text:section>";
		$self->{'curr_sect'} = 0;
	}

	if (!$self->{'curr_sect'} && $self->{'xml'}) {
		print STDERR "\n  XML: " . $self->{'xml'} if ($self->{'props'}{'debug'} > 1);
		$self->{'cur'} = bless $self->{'doc'}->insertElement($self->{'cur'}, $self->{'xml'}, position => 'after'), OpenOffice::OODoc::Element;
		$self->{'xml'} = '';
	}

    if (scalar @{$self->{'images'}})
    {
        $self->{'doc'}->moveElements($self->{'cur'}, @{$self->{'images'}});
        delete $self->{'images'};
    }
}

%esc = (
    '&' => '&amp;',
    '>' => '&gt;',
    '<' => '&lt;',
    "'" => '&apos;',
    '"' => '&quot;'
    );
$esc = join("", keys %esc);

sub xmlescape
{
    my ($str) = @_;
    $str =~ s/([$esc])/$esc{$1}/oge;
    $str;
}


1;

__END__

=head1 TITLE

shlex openoffice backend - puts shlex output into opendocument 1.0 format

=head1 SYNOPSIS

  shlex -c config.xml [-o outfile] [-s style_info] -b openoffice infile

=head1 OPTIONS

  -o outfile     This is the base name on which the output filenames are based
  -s style_info  An Opendocument file that contains a specially named "section"
upon which the dictionary sections are based

=head1 DESCRIPTION

=head2 the <backend> section

In the config.xml file, you have have a <backend> tag.  This can contain 
several <property> tags with corresponding values.

The properties that the backend looks for are:

=over 4 

=item debug

a value of one will give verbose openoffice backend debugging information.

=item split_files

a value of one will cause the backend to create a separate file for each section
(eg. one for the main dictionary, and one for each index)

=item styles_as_variable

this will create the contents of the style as a variable of the same name.
The text will be visible.  This is useful for creating a first and last word in the header and
footer of a page.  The value is a list of styles, separated by commas.

=item styles_as_reference

this will create a reference where the reference name is the contents
of that style.  After the style is printed, the reference will be added immediate afterwards 
(but this reference will not be visible).  This can be used for page numbers
of a letter or particular word or place.  The value is a list of styles, separated by commas.

=item columns

if the value is 2, it will create double columns in each section for each letter.
Otherwise single columns will be used.
This will allow for a letter header that spans the whole page, but has all the entries in
double columns.  It is much better, however, to create a double column style and pass it in
as a style sheet using the -s flag.

=back

For example:

  <backend type="openoffice">
      <property name="debug" value="1"/>
      <property name="styles_as_variable" value="Lexeme,Letter,IndexEng" />
      <property name="styles_as_reference" value="IndexEng" />
      <property name="split_files" value="1" />
      <property name="columns" value="2" />
  </backend>

=head2 Section Styles

Because Openoffice does not allow you to edit a stylesheet used for sections,
a sample must be passed in, and that section's style will be used for all the sections
of that type.

To pass in a double column style, create a style document that is passed in
with the -s flag.  Here is how it works:

Each major section in the configuation file has a type and a name.
Each section will have a name of "section_" followed by the type followed
by the name, and then a number.

If a section is called
  <section type="dictionary" name="main" keys="lx hm" >

then the openoffice section names will be
  section_dictionary_main_0
  section_dictionary_main_1
  section_dictionary_main_2
etc. 

or for
  <section type="index" name="eng" keys="reEng" >

they would be named:
  section_index_eng_0
  section_index_eng_1
  section_index_eng_2

If you create a document that has a section named
C<section_dictionary_main>
and this is given as a stylesheet using the -s flag,
shlex will take the style from this section and use it for
all the sections (_0, _1, etc) with that name.

You can also just look at the section names in your openoffice document
(Choose Format then Sections from the Menu)
to know what they are called, and create a section without the _0 at the end
and it will use that style.

For exampel, you can put these sections
C<section_index_eng> and C<section_dictionary_main>
into a document such as SectionStyles.odt (having sample text and
entries in this document is fine - the content will be ignored), and then run
shlex with this document as the argument of the -s flag:

  shlex -c configure.xml -o MyDict -b openoffice -s SectionStyles.odt database.db


