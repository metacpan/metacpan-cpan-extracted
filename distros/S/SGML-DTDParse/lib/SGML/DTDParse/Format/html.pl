# dtdformat module for HTML

# $Id: html.pl,v 2.1 2005/07/02 23:51:18 ehood Exp $

use SGML::DTDParse::Util qw(entify);

$fileext = ".html";

$config{'home'} = 'index' . $fileext;
$config{'expanded-element-index'} = "elements" . $fileext;
$config{'unexpanded-element-index'} = "dtdelem" . $fileext;
$config{'expanded-entity-index'} = "entities" . $fileext;
$config{'unexpanded-entity-index'} = "dtdent" . $fileext;
$config{'notation-index'} = 'notations' . $fileext;

# ======================================================================

my $dtdparseHomepage = "http://sourceforge.net/projects/dtdparse/";

# ======================================================================

sub formatElement {
    my $count   = shift;
    my $html    = "";

    my $name    = $elements[$count];
    my $element = $elements{$name};

    my $cmex    = undef;
    my $cmunx   = undef;
    my $incl    = undef;
    my $excl    = undef;

    my $node = $element->getFirstChild();
    while ($node) {
	if ($node->getNodeType() == XML::DOM::ELEMENT_NODE) {
	    $cmex = $node if $node->getTagName() eq 'content-model-expanded';
	    $cmunx = $node if $node->getTagName() eq 'content-model';
	    $incl = $node if $node->getTagName() eq 'inclusions';
	    $excl = $node if $node->getTagName() eq 'exclusions';
	}
	$node = $node->getNextSibling();
    }

    $html .= &formatElementHeader($count);

    $html .= &formatElementTitle($count);

    if ($option{'synopsis'}) {
	if ($expanded eq 'expanded' || !$option{'unexpanded'}) {
	    $html .= &formatElementSynopsis($count, $cmex, $cmex);
	} else {
	    $html .= &formatElementSynopsis($count, $cmunx, $cmex);
	} 
    }

    $html .= &formatInclusions($count, $incl) 
        if $incl && $option{'inclusions'};

    $html .= &formatExclusions($count, $excl) 
        if $excl && $option{'exclusions'};

    $html .= &formatAttributeList($count) if $option{'attributes'};

    $html .= &formatTagMinimization($count) if $option{'tag-minimization'};

    $html .= &formatElementAppearsIn($count) if $option{'appears-in'};

    $html .= &formatElementDescription($count) 
        if $option{'description'};

    $html .= &formatParents($count) if $option{'parents'};

    $html .= &formatChildren($count) if $option{'children'};

    $html .= &formatElementExamples($count) if $option{'examples'};

    $html .= &formatElementFooter($count);
}

sub formatElementHeader {
    my $count     = shift;
    my $html      = "";
    my $name      = $elements[$count];
    my $element   = $elements{$name};
    my $basename  = $ELEMBASE{$name};
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my %subtitle  = ('expanded' => 'User Element View',
		     'unexpanded' => 'DTD Element View');
    my %otherview = ('expanded' => 'DTD Element View',
		     'unexpanded' => 'User Element View');
    my $otherpath = "";

    if ($expanded eq 'expanded') {
	$otherpath = "../" . $config{'unexpanded-element-dir'} . "/";
    } else {
	$otherpath = "../" . $config{'expanded-element-dir'} . "/";
    }

    $html .= "<HTML>\n<HEAD>\n<TITLE>$title: Element ";
    $html .= $element->getAttribute('name');
    $html .= "</TITLE>\n";
    $html .= "</HEAD>\n<BODY>\n";

    $html .= "<TABLE BORDER='0' WIDTH='100%'>\n";
    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>$title: " . $subtitle{$expanded} . "</TD>\n";

    $html .= "<TD ALIGN='right'>";
    if ($option{'unexpanded'} || ($expanded eq 'unexpanded')) {
	$html .= "[<A HREF=\"$otherpath$basename" . $fileext . "\">";
	$html .= $otherview{$expanded};
	$html .= "</A>]";
    } else {
	$html .= "&nbsp;";
    }
    $html .= "</TD>\n";
    $html .= "</TR>\n";

    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>\n";

    $html .= &headerLinks('none', 1);

    $html .= "</TD>\n";

    $html .= "<TD ALIGN='right'>\n";

    if ($count > 0) {
	my $href = $ELEMBASE{$elements[$count-1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Prev</A>]\n";
    }

    if ($count < $#elements) {
	my $href = $ELEMBASE{$elements[$count+1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Next</A>]\n";
    }

    $html .= "</TD>\n";
    $html .= "</TR>\n";
    $html .= "</TABLE>\n";
    $html .= "<HR>\n";
    
    return $html;
}

sub formatElementTitle {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html = "";

    $html .= "<H1>Element " . $element->getAttribute('name') . "</h1>\n";
}

sub formatElementSynopsis {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $cm      = shift;
    my $cmex    = shift;
    my $html = "";

    # What are the possibilities: mixed content, element content, or
    # declared content...
    my $mixed    = $element->getAttribute('content-type') eq 'mixed';
    my $declared = (!$mixed && 
		    $element->getAttribute('content-type') ne 'element');

    $html .= "<H2>Synopsis</h2>\n";

    if ($option{'content-model'}) {
	if ($mixed) {
	    $html .= "<H3>Mixed Content Model</H3>\n";
	} elsif ($declared) {
	    $html .= "<H3>Declared Content</H3>\n";
	} else {
	    $html .= "<H3>Content Model</H3>\n";
	}

	$html .= "<PRE>";
	$html .= &formatContentModel($count, $cm);
	$html .= "</PRE>\n";

	return $html;
    }
}

sub formatInclusions {
    my $count   = shift;
    my $cm      = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";

    $html .= "<H3>Inclusions</h3>\n";
    $html .= "<PRE>";

    $html .= &formatContentModel($count, $cm);

    $html .= "</PRE>\n";

    return $html;
}

sub formatExclusions {
    my $count   = shift;
    my $cm      = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";

    $html .= "<H3>Exclusions</h3>\n";
    $html .= "<PRE>";

    $html .= &formatContentModel($count, $cm);

    $html .= "</PRE>\n";

    return $html;
}

sub formatAttributeList {
    my $count   = shift;
    my $html    = "";

    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $attlist = $attlists{$name};

    $html .= "<H3>Attributes</H3>\n";

    if (defined($attlist)) {
	$html .= &formatAttributes($attlist);
    } else {
	$html .= "<P>None</P>\n";
    }

    return $html;
}

sub formatAttributes {
    my $attlist = shift;
    my $html    = "";
    my $attrs   = $attlist->getElementsByTagName("attribute");

    $html .= "<TABLE BORDER='1'>\n";
    $html .= "<TR>\n";
    $html .= "<TH>Name</TH>";
    $html .= "<TH>Type</TH>";
    $html .= "<TH>Default Value</TH>";
    $html .= "</TR>\n";

    for (my $count = 0; $count < $attrs->getLength(); $count++) {
	my $attr = $attrs->item($count);

	my $name     = $attr->getAttribute('name');
	my $type     = $attr->getAttribute('value');
	my $decltype = $attr->getAttribute('type');
	my $default = "";

	if ($decltype eq '#IMPLIED') {
	    $default = "<I>None</I>";
	} elsif ($decltype eq '#REQUIRED') {
	    $default = "<I>Required</I>";
	} elsif ($decltype eq '#CONREF') {
	    $default = "<I>Content reference</I>";
	} else {
	    $default = $attr->getAttribute('default');
	    if ($default =~ /\"/) {
		$default = "'" . $default . "'";
	    } else {
		$default = "\"" . $default . "\"";
	    }
	}

	if ($decltype eq '#FIXED') {
	    $default = $default . " <I>(fixed)</I>";
	}

	$html .= "<TR>\n";
	$html .= &formatCell($name);
	$html .= &formatValues($type, $attr);
	$html .= &formatCell($default);
	$html .= "</TR>\n";
    }

    $html .= "</TABLE>\n";

    return $html;
}

sub formatCell {
    my $value = shift;

    $value = "&nbsp;" if $value =~ /^\s*$/;

    return "<TD ALIGN=\"left\" VALIGN=\"top\">$value</TD>\n";
}

sub formatValues {
    my $values = shift;
    my $attr = shift;
    my $enum = $attr->getAttribute('enumeration');
    my $html = "";

    if ($enum eq 'no' || $enum eq '') {
	return &formatCell($values);
    }

    $html .= "<TD ALIGN=\"left\" VALIGN=\"top\">";
    if ($enum eq 'notation') {
	$html .= "<I>Enumerated notation:</I><BR>\n";
    } else {
	$html .= "<I>Enumeration:</I><BR>\n";
    }

    my $first = 1;
    foreach my $val (sort { uc($a) cmp uc($b) } 
		     split(/\s+/, $attr->getAttribute('value'))) {
	$html .= "<BR>\n" if !$first;
	$first = 0;
	$html .= "&nbsp;&nbsp;$val";
    }

    $html .= "</TD>";

    return $html;
}

sub formatTagMinimization {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";
    my $stagm   = $element->getAttribute('stagm') || "-";
    my $etagm   = $element->getAttribute('etagm') || "-";

    if ($element->getAttribute('stagm')
	|| $element->getAttribute('etagm')) {
	my (%min) = ('--' => "Both the start- and end-tags are required for this element.",
		     'OO' => "Both the start- and end-tags are optional for this element, if your SGML declaration allows tag minimization.",
		     'O-' => "The start-tag is optional for this element, if your SGML declaration allows tag minimization.  The end-tag is required.",
		     '-O' => "The start-tag is required for this element.  The end-tag is optional, if your SGML declaration allows minimization."
		    );
	$html .= "<H3>Tag Minimization</H3>\n";
	$html .= "<P>";
	$html .= $min{$stagm . $etagm};
	$html .= "</P>\n";
    }

    return $html;
}

sub formatElementAppearsIn {
    my $count = shift;
    my $html = "";
    my $elementname = $elements[$count];
    my $element = $elements{$elementname};
    my %appears = ();

    %appears = %{$APPEARSIN{$elementname}} if exists $APPEARSIN{$elementname};

    if (%appears) {
	my @ents = sort { uc($a) cmp uc($b) } keys %appears;
	my $href = $config{$expanded . "-entity-dir"};

	$html .= "<H3>Parameter Entities</H3>\n";
	$html .= "<P>The following parameter entities contain ";
	$html .= $element->getAttribute('name') . ":\n";

	my $first = 1;
	for (my $count = 0; $count <= $#ents; $count++) {
	    my $entity = $entities{$ents[$count]};
	    my $basename = $ENTBASE{$ents[$count]} . $fileext;
	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$href/$basename\">";
	    $html .= $entity->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>";
    }

    return $html;
}

sub formatElementDescription {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";

    $html .= "<H2>Description</H2>\n";

    return $html;
}

sub formatParents {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";

    if (exists $PARENTS{$name}) {
	$html .= "<H3>Parents</H3>\n";
	$html .= "<P>";

	my $first = 1;
	my $pname;
	foreach $pname (sort { uc($a) cmp uc($b) } keys %{$PARENTS{$name}}) {
	    my $child = $elements{$pname};
	    my $href = $ELEMBASE{$pname} . $fileext;
	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$href\">";
	    $html .= $child->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>\n";
    }

    return $html;
}

sub formatChildren {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};
    my $html    = "";
    my $mixed    = $element->getAttribute('content-type') eq 'mixed';
    my $declared = (!$mixed && 
		    $element->getAttribute('content-type') ne 'element');

    return "" if $declared; # can't be any children...

    if (exists $CHILDREN{$name}) {
	$html .= "<H3>Children</H3>\n";
	$html .= "<P>";
	
	my $first = 1;
	my $cname;
	foreach $cname (sort { uc($a) cmp uc($b) } keys %{$CHILDREN{$name}}) {
	    my $child = $elements{$cname};
	    my $href = $ELEMBASE{$cname} . $fileext;

	    die "Unexpected error (1): can't find element \"$cname\".\n" 
		if !$child;

	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$href\">";
	    $html .= $child->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>\n";
    }

    if (exists $POSSINCL{$name}) {
	$html .= "<P>In some contexts, the following elements are\n";
	$html .= "allowed anywhere: ";

	my $first = 1;
	my $cname;
	foreach $cname (sort { uc($a) cmp uc($b) } keys %{$POSSINCL{$name}}) {
	    my $child = $elements{$cname};
	    my $href = $ELEMBASE{$cname} . $fileext;

	    die "Unexpected error (2): can't find element \"$cname\".\n"
		if !$child;

	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$href\">";
	    $html .= $child->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>\n";
    }

    if (exists $POSSEXCL{$name}) {
	$html .= "<P>In some contexts, the following elements are\n";
	$html .= "excluded: ";

	my $first = 1;
	my $cname;
	foreach $cname (sort { uc($a) cmp uc($b) } keys %{$POSSEXCL{$name}}) {
	    my $element = $elements{$cname};
	    my $href = $ELEMBASE{$cname} . $fileext;
	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$href\">";
	    $html .= $element->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>\n";
    }

    return $html;
}

sub formatElementExamples {
    my $count   = shift;
    my $name    = $elements[$count];
    my $element = $elements{$name};

    return "";
}

sub formatElementFooter {
    my $count = shift;
    my $html = "";

    $html .= "<P></P>\n";
    $html .= "<HR>\n";
    $html .= "HTML Presentation of ";
    $html .= $dtd->getDocumentElement()->getAttribute('title');
    $html .= " by <A HREF=\"$dtdparseHomepage\">";
    $html .= "DTDParse</A> (version $main::VERSION).\n";
    $html .= "</BODY>\n";
    $html .= "</HTML>\n";

    return $html;
}

# ----------------------------------------------------------------------

my $state = 'NONE';
my $depth = 0;
my $col = 0;

sub formatContentModel {
    my $count = shift;
    my $cm = shift;
    my $node = $cm->getFirstChild();
    my $html = "";

    while ($node) {
	if ($node->getNodeType == XML::DOM::ELEMENT_NODE) {
	    $html .= formatContentModelElement($node);
	} 
	$node = $node->getNextSibling();
    }

    return $html;
}

sub formatContentModelElement {
    my $node = shift;
    my $html = "";

    if ($node->getNodeType == XML::DOM::ELEMENT_NODE) {
	if ($node->getTagName() eq 'sequence-group') {
	    $html .= &formatCMGroup($node, ",");
	} elsif ($node->getTagName() eq 'or-group') {
	    $html .= &formatCMGroup($node, "|");
	} elsif ($node->getTagName() eq 'and-group') {
	    $html .= &formatCMGroup($node, "&");
	} elsif ($node->getTagName() eq 'element-name') {
	    $html .= &formatCMElement($node);
	} elsif ($node->getTagName() eq 'parament-name') {
	    $html .= &formatCMParament($node);
	} elsif ($node->getTagName() eq 'pcdata') {
	    $html .= &formatCMPCDATA($node);
	} elsif ($node->getTagName() eq 'cdata') {
	    $html .= &formatCMCDATA($node);
	} elsif ($node->getTagName() eq 'rcdata') {
	    $html .= &formatCMRCDATA($node);
	} elsif ($node->getTagName() eq 'empty') {
	    $html .= &formatCMEMPTY($node);
	} elsif ($node->getTagName() eq 'any') {
	    $html .= &formatCMANY($node);
	} else {
	    die "Unexpected node: \"" . $node->getTagName() . "\"\n";
	}
	$node = $node->getNextSibling();
    } else {
	die "Unexpected node type.\n";
    }

    return $html;
}

sub formatCMGroup {
    my $group = shift;
    my $occur = $group->getAttribute('occurrence');
    my $sep = shift;
    my $first = 1;
    my $html = "";

    if ($state ne 'NONE' && $state ne 'OPEN') {
	$html .= "\n";
	$html .= " " x $depth if $depth > 0;
	$col = $depth;
	$state = 'NEWLINE';
    }

    $html .= "(";
    $state = 'OPEN';
    $depth++;
    $col++;
    
    my $node = $group->getFirstChild();
    while ($node) {
	if ($node->getNodeType == XML::DOM::ELEMENT_NODE) {
	    if (!$first) {
		$html .= $sep;
		$col++;

		if ($state ne 'NEWLINE' && ($col > 60)) {
		    $html .= "\n";
		    $html .= " " x $depth if $depth > 0;
		    $col = $depth;
		    $state = 'NEWLINE';
		}
	    }
	    $html .= &formatContentModelElement($node);
	    $first = 0;
	} 
	$node = $node->getNextSibling();
    }

    $html .= ")";
    $col++;

    if ($occur) {
	$html .= $occur;
	$col++;
    }

    $state = 'CLOSE';
    $depth--;

    return $html;
}

sub formatCMElement {
    my $element = shift;
    my $name = $element->getAttribute('name');
    my $occur = $element->getAttribute('occurrence');
    my $href = "";
    my $html = "";

    $name = lc($name) if !$option{'namecase-general'};

    $name = lc($name) if $option{'namecase-general'};

    $href = $ELEMBASE{$name} . $fileext;

    if ($state eq 'CLOSE') {
	$html .= "\n";
	$html .= " " x $depth if $depth > 0;
	$col = $depth;
	$state = 'NEWLINE';
    }

    $html .= "<A HREF=\"$href\">";
    $html .= $element->getAttribute('name');
    $html .= "</A>";
    $col += length($name);

    if ($occur) {
	$html .= $occur;
	$col++;
    }

    $state = 'ELEMENT';

    return $html;
}

sub formatCMParament {
    my $element = shift;
    my $name = $element->getAttribute('name');
    my $href = "";
    my $html = "";

    $href = "../" . $config{$expanded . '-entity-dir'};
    $href .= "/" . $ENTBASE{$name} . $fileext;

    if ($state eq 'CLOSE') {
	$html .= "\n";
	$html .= " " x $depth if $depth > 0;
	$col = $depth;
	$state = 'NEWLINE';
    }

    $html .= "<A HREF=\"$href\">";
    $html .= "\%" . $name . ";";
    $html .= "</A>";
    $col += length($name) + 2;

    $state = 'PARAMENT';

    return $html;
}

sub formatCMPCDATA {
    my $html = "";

    $html .= "#PCDATA";
    $col += 7;
    $state = 'PCDATA';

    return $html;
}

sub formatCMCDATA {
    my $html = "";

    $html .= "CDATA";
    $col += 5;
    $state = 'CDATA';

    return $html;
}

sub formatCMRCDATA {
    my $html = "";

    $html .= "RCDATA";
    $col += 5;
    $state = 'RCDATA';

    return $html;
}

sub formatCMEMPTY {
    my $html = "";

    $html .= "EMPTY";
    $col += 5;
    $state = 'EMPTY';

    return $html;
}

sub formatCMANY {
    my $html = "";

    $html .= "ANY";
    $col += 3;
    $state = 'ANY';

    return $html;
}

# ======================================================================

sub formatEntity {
    my $count   = shift;
    my $name    = $entities[$count];
    my $entity  = $entities{$name};
    my $html    = "";
    my $textnl;

    if ($expanded eq 'expanded') {
	$textnl = $entity->getElementsByTagName("text-expanded");
    } else {
	$textnl = $entity->getElementsByTagName("text");
    }

    $html .= &formatEntityHeader($count);

    $html .= &formatEntityTitle($count);

    $html .= &formatEntitySynopsis($count, $textnl)
	if $option{'synopsis'};

    $html .= &formatEntityAppearsIn($count) if $option{'appears-in'};

    $html .= &formatEntityDescription($count) if $option{'description'};

    $html .= &formatEntityExamples($count) if $option{'examples'};
    
    $html .= &formatEntityFooter($count);

    return $html;
}

sub formatEntityHeader {
    my $count     = shift;
    my $html      = "";
    my $name      = $entities[$count];
    my $entity    = $entities{$name};
    my $basename  = $ENTBASE{$name};
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my %subtitle  = ('expanded' => 'User Entity View',
		     'unexpanded' => 'DTD Entity View');
    my %otherview = ('expanded' => 'DTD Entity View',
		     'unexpanded' => 'User Entity View');
    my $otherpath = "";

    if ($expanded eq 'expanded') {
	$otherpath = "../" . $config{'unexpanded-entity-dir'} . "/";
    } else {
	$otherpath = "../" . $config{'expanded-entity-dir'} . "/";
    }

    $html .= "<HTML>\n<HEAD>\n<TITLE>$title: Entity ";
    $html .= $entity->getAttribute('name');
    $html .= "</TITLE>\n";
    $html .= "</HEAD>\n<BODY>\n";
    
    $html .= "<TABLE BORDER='0' WIDTH='100%'>\n";
    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>$title: " . $subtitle{$expanded} . "</TD>\n";
    $html .= "<TD ALIGN='right'>";
    if ($option{'unexpanded'} || ($expanded eq 'unexpanded')) {
	$html .= "[<A HREF=\"$otherpath$basename" . $fileext . "\">";
	$html .= $otherview{$expanded};
	$html .= "</A>]";
    } else {
	$html .= "&nbsp;";
    }
    $html .= "</TD>\n";
    $html .= "</TR>\n";

    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>\n";

    $html .= &headerLinks('none', 1);

    $html .= "</TD>\n";

    $html .= "<TD ALIGN='right'>\n";
    if ($count > 0) {
	my $href = $ENTBASE{$entities[$count-1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Prev</A>]\n";
    }
    if ($count < $#entities) {
	my $href = $ENTBASE{$entities[$count+1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Next</A>]\n";
    }
    $html .= "</TD>\n";
    $html .= "</TR>\n";
    $html .= "</TABLE>\n";
    $html .= "<HR>\n";
}

sub formatEntityTitle {
    my $count   = shift;
    my $name    = $entities[$count];
    my $element = $entities{$name};
    my $html = "";

    $html .= "<H1>Entity " . $element->getAttribute('name') . "</h1>\n";
}

sub formatEntitySynopsis {
    my $count   = shift;
    my $textnl  = shift;
    my $name    = $entities[$count];
    my $entity  = $entities{$name};
    my $html    = "";
    my $type    = $entity->getAttribute("type");
    my $public  = $entity->getAttribute("public");
    my $system  = $entity->getAttribute("system");
    my $text    = "";

    if ($textnl->getLength() > 0) {
	my $textnode = $textnl->item(0);
	my $content = $textnode->getFirstChild();
	if ($content) {
	    $text = $content->getData();
	} else {
	    $text = "";
	}
    }

    $html .= "<H2>Synopsis</h2>\n";

    if ($type eq 'gen') {
	if ($public || $system) {
	    $html .= "<H3>External General Entity</H3>\n";
	    $html .= "<P><B>Public identifier</B>: $public</P>\n" if $public;
	    $html .= "<P><B>System identifier</B>: $system</P>\n" if $system;
	} else {
	    $html .= "<H3>General Entity</H3>\n";
	    if ($text =~ /\"/) {
		$html .= "<P>'$text'</P>\n";
	    } else {
		$html .= "<P>\"$text\"</P>\n";
	    }
	}
    }

    if ($type eq 'param') {
	if ($public || $system) {
	    $html .= "<H3>External Parameter Entity</H3>\n";
	    $html .= "<P><B>Public identifier</B>: $public</P>\n" if $public;
	    $html .= "<P><B>System identifier</B>: $system</P>\n" if $system;
	} else {
	    $html .= "<H3>Parameter Entity</H3>\n";
	    $html .= "<PRE>";

	    # OK, it's a parameter entity. Now, does it look like a 
	    # content model fragment

	    my $cmfragment = &cmFragment($text);

	    while ($text =~ /\%?[-a-z0-9.:_]+;?/is) {
		my $pre = $`;
		my $match = $&;
		$text = $';

		$html .= $pre;

		if ($pre =~ /\#$/) {
		    # if it comes after a '#', it's a keyword...
		    $html .= $match;
		    next;
		}

		if ($match =~ /\%([^;]+);?/) {
		    $name = $1;
		    if (exists $entities{$name}) {
			my $href = $ENTBASE{$name} . $fileext;
			$html .= "<A HREF=\"$href\">$match</A>";
		    } else { 
			$html .= $match;
		    }
		} elsif ($cmfragment) {
		    $name = $match;
		    $name = lc($name) if !$option{'namecase-general'};
		    if (exists $elements{$name}) {
			my $href = $ELEMBASE{$name} . $fileext;
			my $dir = $config{$expanded . "-element-dir"};
			$html .= "<A HREF=\"../$dir/$href\">$match</A>";
		    } else {
			$html .= $match;
		    }
		} else {
		    $html .= $match;
		}
	    }
	    $html .= $text;
	    $html .= "</PRE>\n";
	}
    }

    if ($type eq 'sdata' || $type eq 'pi') {
	$html .= "<H3>" . uc($type) . " Entity</H3>\n";
	$text =~ s/\&/\&amp;/sg;
	if ($text =~ /\"/) {
	    $html .= "<P>'$text'</P>\n";
	} else {
	    $html .= "<P>\"$text\"</P>\n";
	}
    }

    if ($type eq 'ndata' || $type eq 'cdata') {
	my $notation = $entity->getAttribute("notation");

	$html .= "<H3>" . uc($type) . " Entity</H3>\n";
	$html .= "<P><B>Notation</B>: $notation</P>\n";
	$html .= "<P><B>Public identifier</B>: $public</P>\n" if $public;
	$html .= "<P><B>System identifier</B>: $system</P>\n" if $system;
    }

    return $html;
}

sub formatEntityAppearsIn {
    my $count = shift;
    my $html = "";
    my $entityname = $entities[$count];
    my $entity = $entities{$entityname};
    my %appears = ();
    my $key = "%$entityname";

    %appears = %{$APPEARSIN{$key}} if exists $APPEARSIN{$key};

    if (%appears) {
	my @ents = sort { uc($a) cmp uc($b) } keys %appears;

	$html .= "<H3>Parameter Entities</H3>\n";
	$html .= "<P>The following parameter entities contain ";
	$html .= $entity->getAttribute('name') . ":\n";

	my $first = 1;
	for (my $count = 0; $count <= $#ents; $count++) {
	    my $entity = $entities{$ents[$count]};
	    my $basename = $ENTBASE{$ents[$count]} . $fileext;
	    $html .= ",\n" if !$first;
	    $first = 0;
	    $html .= "<A HREF=\"$basename\">";
	    $html .= $entity->getAttribute('name');
	    $html .= "</A>";
	}

	$html .= "</P>";
    }

    return $html;
}

sub formatEntityDescription {
    my $count   = shift;
    my $name    = $entities[$count];
    my $entity  = $entities{$name};

    return "";
}

sub formatEntityExamples {
    my $count   = shift;
    my $name    = $entities[$count];
    my $entity  = $entities{$name};

    return "";
}

sub formatEntityFooter {
    my $count = shift;
    my $html = "";

    $html .= "<P></P>\n";
    $html .= "<HR>\n";
    $html .= "HTML Presentation of ";
    $html .= $dtd->getDocumentElement()->getAttribute('title');
    $html .= " by <A HREF=\"$dtdparseHomepage\">";
    $html .= "DTDParse</A> (version $main::VERSION).\n";
    $html .= "</BODY>\n";
    $html .= "</HTML>\n";

    return $html;
}

# ======================================================================

sub formatNotation {
    my $count   = shift;
    my $html    = "";

    my $name    = $notations[$count];
    my $element = $notations{$name};

    $html .= &formatNotationHeader($count);

    $html .= &formatNotationTitle($count);

    if ($option{'synopsis'}) {
	$html .= &formatNotationSynopsis($count);
    }

    $html .= &formatNotationDescription($count) 
        if $option{'description'};

    $html .= &formatNotationExamples($count) if $option{'examples'};

    $html .= &formatNotationFooter($count);
}

sub formatNotationHeader {
    my $count     = shift;
    my $html      = "";
    my $name      = $notations[$count];
    my $notation  = $notations{$name};
    my $basename  = $NOTBASE{$name};
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my $subtitle  = "Notation View";

    $html .= "<HTML>\n<HEAD>\n<TITLE>$title: Notation ";
    $html .= $notation->getAttribute('name');
    $html .= "</TITLE>\n";
    $html .= "</HEAD>\n<BODY>\n";
    
    $html .= "<TABLE BORDER='0' WIDTH='100%'>\n";
    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>$title: $subtitle</TD>\n";

    $html .= "<TD ALIGN='right'>";
    $html .= "&nbsp;";
    $html .= "</TD>\n";
    $html .= "</TR>\n";

    $html .= "<TR>\n";
    $html .= "<TD ALIGN='left'>\n";

    $html .= &headerLinks('none', 1);

    $html .= "</TD>\n";

    $html .= "<TD ALIGN='right'>\n";

    if ($count > 0) {
	my $href = $NOTBASE{$notations[$count-1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Prev</A>]\n";
    }

    if ($count < $#notations) {
	my $href = $NOTBASE{$notations[$count+1]} . $fileext;
	$html .= "[<A HREF=\"$href\">Next</A>]\n";
    }

    $html .= "</TD>\n";
    $html .= "</TR>\n";
    $html .= "</TABLE>\n";
    $html .= "<HR>\n";
    
    return $html;
}

sub formatNotationTitle {
    my $count    = shift;
    my $name     = $notations[$count];
    my $notation = $notations{$name};
    my $html = "";

    $html .= "<H1>Notation " . $notation->getAttribute('name') . "</h1>\n";
}

sub formatNotationSynopsis {
    my $count    = shift;
    my $name     = $notations[$count];
    my $notation = $notations{$name};
    my $html    = "";
    my $public  = $notation->getAttribute("public");
    my $system  = $notation->getAttribute("system");

    $html .= "<H2>Synopsis</h2>\n";

    $html .= "<P><B>Public identifier</B>: $public</P>\n" if $public;
    $html .= "<P><B>System identifier</B>: $system</P>\n" if $system;

    if (!$public && !$system) {
	$html .= "<P>SYSTEM specified without a system identifier.</P>\n";
    }

    return $html;
}

sub formatNotationDescription {
    my $count    = shift;
    my $name     = $notations[$count];
    my $notation = $notations{$name};
    my $html     = "";

    $html .= "<H2>Description</H2>\n";

    return $html;
}

sub formatNotationExamples {
    my $count   = shift;
    my $name    = $notations[$count];
    my $element = $notations{$name};

    return "";
}

sub formatNotationFooter {
    my $count = shift;
    my $html = "";

    $html .= "<P></P>\n";
    $html .= "<HR>\n";
    $html .= "HTML Presentation of ";
    $html .= $dtd->getDocumentElement()->getAttribute('title');
    $html .= " by <A HREF=\"$dtdparseHomepage\">";
    $html .= "DTDParse</A> (version $main::VERSION).\n";
    $html .= "</BODY>\n";
    $html .= "</HTML>\n";

    return $html;
}

# ======================================================================

sub headerLinks {
    my $skip = shift;
    my $up = shift;
    my $html = "";

    my $entfile   = ($up ? "../" : "") . $config{$expanded . "-entity-index"};
    my $elemfile  = ($up ? "../" : "") . $config{$expanded . "-element-index"};
    my $notfile   = ($up ? "../" : "") . $config{"notation-index"};
    my $home      = ($up ? "../" : "") . $config{"home"};
    my $elemcount = $#elements+1;
    my $entcount  = $#entities+1;
    my $notcount  = $#notations+1;

    if ($skip ne 'home') {
	$html .= "[<A HREF=\"$home\">Home</A>]\n";
    }

    if ($option{'elements'} && $skip ne 'elements' && $elemcount > 0) {
	$html .= "[<A HREF=\"$elemfile\">Elements</A>]\n";
    }

    if ($option{'entities'} && $skip ne 'entities' && $entcount > 0) {
	$html .= "[<A HREF=\"$entfile\">Entities</A>]\n";
    }

    if ($option{'notations'} && $skip ne 'notations' && $notcount > 0) {
	$html .= "[<A HREF=\"$notfile\">Notations</A>]\n";
    }

    return $html;
}

sub writeHeaderLinks {
    local *F = shift;
    my $skip = shift;
    my $up = shift;

    print F &headerLinks($skip, $up);
}    

sub writeElementIndexes {
    my $basedir   = shift;
    my %letters   = ();
    my $element   = "";
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my %subtitle  = ('expanded' => 'User Element View',
		     'unexpanded' => 'DTD Element View');
    my %otherview = ('expanded' => 'DTD Element View',
		     'unexpanded' => 'User Element View');
    my ($char, $lastchar, $first, $otherfile);
    local (*F, $_);

    if ($expanded eq 'expanded') {
	$otherfile = $config{'unexpanded-element-index'};
    } else {
	$otherfile = $config{'expanded-element-index'};
    }

    foreach $element (@elements) {
	$char = uc(substr($element, 0, 1));
	$letters{$char} = 1;
    }

    open (F, ">" . $basedir . "/" . $config{$expanded . "-element-index"});

    print F "<HTML>\n<HEAD>\n<TITLE>$title: Elements</TITLE>\n";
    print F "</HEAD>\n<BODY>\n";
    
    print F "<TABLE BORDER='0' WIDTH='100%'>\n";
    print F "<TR>\n";
    print F "<TD ALIGN='left'>$title: ", $subtitle{$expanded}, "</TD>\n";
    print F "<TD ALIGN='right'>";
    if ($option{'unexpanded'} || ($expanded eq 'unexpanded')) {
	print F "[<A HREF=\"$otherfile\">";
	print F $otherview{$expanded};
	print F "</A>]";
    } else {
	print F "&nbsp;";
    }
    print F "</TD>\n";
    print F "</TR>\n";

    print F "<TR>\n";
    print F "<TD ALIGN='left'>\n";

    writeHeaderLinks(*F, 'elements', 0);

    print F "</TD>\n";

    print F "<TD ALIGN='right'>\n";
    print F "&nbsp;";
    print F "</TD>\n";
    print F "</TR>\n";
    print F "</TABLE>\n";
    print F "<HR>\n";

    $first = 1;
    foreach $char (sort { uc($a) cmp uc($b) } keys %letters) {
	print F " | " if !$first;
	$first = 0;
	print F "<A HREF=\"#$char\">$char</A>";
    }
    print F "\n";

    my @roots = keys %ROOTS;
    if ($#roots > 0) {
	print F "<P>Top level elements: ";
    } else {
	print F "<P>Top level element: ";
    }

    $first = 1;
    foreach my $name (sort { uc($a) cmp uc($b) } @roots) {
	my $element = $ROOTS{$name};
	my $basedir = $config{$expanded . "-element-dir"};
	my $basename = $ELEMBASE{$name};
	my $href = "$basedir/$basename" . $fileext;

	print F ",\n" if !$first;
	$first = 0;
	print F "<A HREF=\"$href\">", $element->getAttribute('name'), "</A>";
    }
    print F ".\n";

    $lastchar = $char = "";
    foreach my $name (@elements) {
	my $element = $elements{$name};

	$char = uc(substr($name, 0, 1));
	if ($char ne $lastchar) {
	    print F "<H1><A NAME=\"$char\">$char</A></H1>\n";
	    $lastchar = $char;
	}

	my $basedir = $config{$expanded . "-element-dir"};
	my $basename = $ELEMBASE{$name};
	my $href = "$basedir/$basename" . $fileext;

	print F "<A HREF=\"$href\">", $element->getAttribute('name'), "</A><BR>\n";
    }

    print F "<P></P>\n";
    print F "<HR>\n";
    print F "HTML Presentation of ";
    print F $dtd->getDocumentElement()->getAttribute('title');
    print F " by <A HREF=\"$dtdparseHomepage\">";
    print F "DTDParse</A> (version $main::VERSION).\n";
    print F "</BODY>\n";
    print F "</HTML>\n";

    close (F);
}

sub writeEntityIndexes {
    my $basedir   = shift;
    my %letters   = ();
    my $entity    = "";
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my %subtitle  = ('expanded' => 'User Entity View',
		     'unexpanded' => 'DTD Entity View');
    my %otherview = ('expanded' => 'DTD Entity View',
		     'unexpanded' => 'User Entity View');
    my ($char, $lastchar, $first, $otherfile);
    local (*F, $_);

    if ($expanded eq 'expanded') {
	$otherfile = $config{'unexpanded-entity-index'};
    } else {
	$otherfile = $config{'expanded-entity-index'};
    }

    foreach $entity (@entities) {
	my $etype = &entityType($entities{$entity});

	if (($etype eq 'sdata' && $option{'include-sdata'})
	    || ($etype eq 'msparam' && $option{'include-ms'})
	    || ($etype eq 'charent' && $option{'include-charent'})
	    || ($etype ne 'sdata'
		&& $etype ne 'msparam'
		&& $etype ne 'charent')) {
	    $char = uc(substr($entity, 0, 1));
	    $letters{$char} = 1;
	}
    }

    open (F, ">" . $basedir . "/" . $config{$expanded . "-entity-index"});

    print F "<HTML>\n<HEAD>\n<TITLE>$title: Entities</TITLE>\n";
    print F "</HEAD>\n<BODY>\n";
    
    print F "<TABLE BORDER='0' WIDTH='100%'>\n";
    print F "<TR>\n";
    print F "<TD ALIGN='left'>$title: ", $subtitle{$expanded}, "</TD>\n";

    print F "<TD ALIGN='right'>";
    if ($option{'unexpanded'} || ($expanded eq 'unexpanded')) {
	print F "[<A HREF=\"$otherfile\">";
	print F $otherview{$expanded};
	print F "</A>]";
    } else {
	print F "&nbsp;";
    }
    print F "</TD>\n";
    print F "</TR>\n";

    print F "<TR>\n";
    print F "<TD ALIGN='left'>\n";

    &writeHeaderLinks(*F, 'entities', 0);

    print F "</TD>\n";

    print F "<TD ALIGN='right'>\n";
    print F "&nbsp;";
    print F "</TD>\n";
    print F "</TR>\n";
    print F "</TABLE>\n";
    print F "<HR>\n";

    $first = 1;
    foreach $char (sort { uc($a) cmp uc($b) } keys %letters) {
	print F " | " if !$first;
	$first = 0;
	print F "<A HREF=\"#$char\">$char</A>";
    }
    print F "\n";

    $lastchar = $char = "";
    foreach $entity (@entities) {
	my $etype = &entityType($entities{$entity});

	next if (($etype eq 'sdata' && !$option{'include-sdata'})
		 || ($etype eq 'msparam' && !$option{'include-ms'})
		 || ($etype eq 'charent' && !$option{'include-charent'}));

	$char = uc(substr($entity, 0, 1));
	if ($char ne $lastchar) {
	    print F "<H1><A NAME=\"$char\">$char</A></H1>\n";
	    $lastchar = $char;
	}

	my $basedir = $config{$expanded . "-entity-dir"};
	my $basename = $ENTBASE{$entity};
	my $href = "$basedir/$basename" . $fileext;

	print F "<A HREF=\"$href\">$entity</A>";

	if (0) {
	    print F "--";
	    my $etype = &entityType($entities{$entity});
	    if ($etype eq 'param') {
		print F "parameter entity";
	    } elsif ($etype eq 'paramext') {
		print F "external entity";
	    } elsif ($etype eq 'sdata') {
		print F "SDATA entity";
	    } elsif ($etype eq 'msparam') {
		print F "marked section entity";
	    } elsif ($etype eq 'gen') {
		print F "general entity";
	    } else {
		print F "uknown entity";
	    }
	}

	print F "<BR>\n";
    }

    print F "<P></P>\n";
    print F "<HR>\n";
    print F "HTML Presentation of ";
    print F $dtd->getDocumentElement()->getAttribute('title');
    print F " by <A HREF=\"$dtdparseHomepage\">";
    print F "DTDParse</A> (version $main::VERSION).\n";
    print F "</BODY>\n";
    print F "</HTML>\n";

    close (F);
}

sub writeNotationIndexes {
    my $basedir   = shift;
    my %letters   = ();
    my $notation  = "";
    my $title     = $dtd->getDocumentElement()->getAttribute('title');
    my $subtitle  = "Notation View";
    my $entfile   = $config{$expanded . "-entity-index"};
    my $elemfile  = $config{$expanded . "-element-index"};
    my ($char, $lastchar, $first);
    local (*F, $_);

    foreach $notation (@notations) {
	$char = uc(substr($notation, 0, 1));
	$letters{$char} = 1;
    }

    open (F, ">" . $basedir . "/" . $config{"notation-index"});

    print F "<HTML>\n<HEAD>\n<TITLE>$title: Notations</TITLE>\n";
    print F "</HEAD>\n<BODY>\n";
    
    print F "<TABLE BORDER='0' WIDTH='100%'>\n";
    print F "<TR>\n";
    print F "<TD ALIGN='left'>$title: $subtitle</TD>\n";
    print F "<TD ALIGN='right'>";
    print F "&nbsp;";
    print F "</TD>\n";
    print F "</TR>\n";

    print F "<TR>\n";
    print F "<TD ALIGN='left'>\n";

    &writeHeaderLinks(*F, 'notations', 0);

    print F "</TD>\n";

    print F "<TD ALIGN='right'>\n";
    print F "&nbsp;";
    print F "</TD>\n";
    print F "</TR>\n";
    print F "</TABLE>\n";
    print F "<HR>\n";

    $first = 1;
    foreach $char (sort { uc($a) cmp uc($b) } keys %letters) {
	print F " | " if !$first;
	$first = 0;
	print F "<A HREF=\"#$char\">$char</A>";
    }
    print F "\n";

    $lastchar = $char = "";
    foreach my $name (@notations) {
	my $notation = $notations{$name};

	$char = uc(substr($name, 0, 1));
	if ($char ne $lastchar) {
	    print F "<H1><A NAME=\"$char\">$char</A></H1>\n";
	    $lastchar = $char;
	}

	my $basedir = $config{"notation-dir"};
	my $basename = $NOTBASE{$name};
	my $href = "$basedir/$basename" . $fileext;

	print F "<A HREF=\"$href\">", $notation->getAttribute('name'), "</A><BR>\n";
    }

    print F "<P></P>\n";
    print F "<HR>\n";
    print F "HTML Presentation of ";
    print F $dtd->getDocumentElement()->getAttribute('title');
    print F " by <A HREF=\"$dtdparseHomepage\">";
    print F "DTDParse</A> (version $main::VERSION).\n";
    print F "</BODY>\n";
    print F "</HTML>\n";

    close (F);
}

sub writeIndex {
    my $basedir   = shift;
    my $root      = $dtd->getDocumentElement();
    my $title     = entify($root->getAttribute('title'));
    my $entfile   = $config{"expanded-entity-index"};
    my $elemfile  = $config{"expanded-element-index"};
    my $notfile   = $config{"notation-index"};
    my $elemcount = $#elements+1;
    my $entcount  = $#entities+1;
    my $notcount  = $#notations+1;
    local (*F, $_);

    open (F, ">" . $basedir . "/" . $config{'home'});

    print F "<HTML>\n<HEAD>\n<TITLE>$title</TITLE>\n";
    print F "</HEAD>\n<BODY>\n";

    print F "<H1>$title</h1>\n";

    &writeHeaderLinks(*F, 'home', 0);

    print F "<HR>\n";

    if ($root->getAttribute('public-id')
	|| $root->getAttribute('system-id')) {
	my ($pub) = entify($root->getAttribute('public-id'));
	my ($sys) = entify($root->getAttribute('system-id'));

	print F "<P>";
	print F "The $title ";
	print F "DTD " if $title !~ / DTD$/i;
	print F "is identified with:\n";
	print F "<UL>\n";

	if ($pub) {
	    print F "<LI>The public identifier: \"$pub\"";
	    print F ", and" if $sys;
	    print F "\n";
	}

	print F "<LI>The system identifier: \"$sys\"\n" if $sys;
	print F "</UL>\n";
	print F "<P>It is composed of\n";
    } else {
	print F "<P>";
	print F "The $title ";
	print F "DTD " if $title !~ / DTD$/i;
	print F "is composed of\n";
    }

    print F "$elemcount elements, ";

    if ($entcount == 0) {
	print F "no entities, ";
    } elsif ($entcount == 1) {
	print F "1 entity, ";
    } else {
	print F "$entcount entities, ";
    }

    print F "and ";

    if ($notcount == 0) {
	print F "no notations.\n";
    } elsif ($notcount == 1) {
	print F "1 notation.\n";
    } else {
	print F "$notcount notations.\n";
    }

    my %etypes = ();
    for (my $count = 0; $count < $entcount; $count++) {
	my $ent = $entities{$entities[$count]};
	my $type = &entityType($ent);
	$etypes{$type} = 0 if !exists($etypes{$type});
	$etypes{$type}++;
    }

    print F "<UL COMPACT>\n";
    print F "<LI>$elemcount elements\n";
    print F "<LI>$entcount ", $entcount == 1 ? "entity" : "entities\n";

    print F "<UL COMPACT>\n";
    print F ("<LI>", $etypes{'param'}, " parameter ", 
	     $etypes{'param'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'param'} > 0;
    print F ("<LI>", $etypes{'paramext'}, " external ", 
	     $etypes{'paramext'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'paramext'} > 0;
    print F ("<LI>", $etypes{'sdata'}, " SDATA ", 
	     $etypes{'sdata'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'sdata'} > 0;
    print F ("<LI>", $etypes{'ndata'}, " NDATA ", 
	     $etypes{'ndata'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'ndata'} > 0;
    print F ("<LI>", $etypes{'charent'}, " character ", 
	     $etypes{'charent'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'charent'} > 0;
    print F ("<LI>", $etypes{'msparam'}, " Marked section ", 
	     $etypes{'msparam'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'msparam'} > 0;
    print F ("<LI>", $etypes{'gen'}, " general ", 
	     $etypes{'gen'} == 1 ? "entity" : "entities", "\n")
	if $etypes{'gen'} > 0;
    print F "</UL>\n";

    print F "<LI>$notcount ", $notcount == 1 ? "notation" : "notations\n";
    print F "</UL>\n";

    print F "<P>It claims to be an ";
    if ($root->getAttribute('xml')) {
	print F "XML";
    } else {
	print F "SGML";
    } 
    print F " DTD. Element ";
    print F "and notation " if $notcount > 0;
    print F "names are ";
    print F "not " if $root->getAttribute('namecase-general');
    print F "case sensitive. Entity names are ";
    print F "not " if $root->getAttribute('namecase-entity');
    print F "case sensitive.\n";
    print F "</P>\n";

    print F "<HR>\n";
    print F "HTML Presentation of ";
    print F $dtd->getDocumentElement()->getAttribute('title');
    print F " by <A HREF=\"$dtdparseHomepage\">";
    print F "DTDParse</A> (version $main::VERSION).\n";
    print F "</BODY>\n";
    print F "</HTML>\n";

    close (F);
}

1;

