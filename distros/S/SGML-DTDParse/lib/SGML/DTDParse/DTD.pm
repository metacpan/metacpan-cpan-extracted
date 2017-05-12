# -*- Perl -*-

package SGML::DTDParse::DTD;

use strict;
use vars qw($VERSION $CVS);

$VERSION = do { my @r=(q$Revision: 2.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
$CVS = '$Id: DTD.pm,v 2.2 2005/07/16 03:21:35 ehood Exp $ ';

use Text::DelimMatch;
use SGML::DTDParse;
use SGML::DTDParse::Catalog;
use SGML::DTDParse::Tokenizer;
use SGML::DTDParse::ContentModel;
use SGML::DTDParse::Util qw(entify);

my $DTDVERSION = "1.0";
my $DTDPUBID = "-//Norman Walsh//DTD DTDParse V2.0//EN";
my $DTDSYSID = "dtd.dtd";
my $debug = 0;

{
    package SGML::DTDParse::DTD::ENTITY;

    sub new {
	my($type, $dtd, $entity, $etype, $pub, $sys, $text) = @_;
	my $class = ref($type) || $type;
	my $self = {};

	$text = $dtd->fix_entityrefs($text);

	if ($dtd->{'XML'} && ($pub && !$sys)) {
	    $dtd->status("External entity declaration without system "
			 . "identifer found in XML DTD. "
			 . "This isn't an XML DTD.", 1);
	    $dtd->{'XML'} = 0;
	}

	$self->{'DTD'} = $dtd;
	$self->{'NAME'} = $entity;
	$self->{'TYPE'} = $etype;
	$self->{'NOTATION'} = "";
	$self->{'PUBLIC'} = $pub;
	$self->{'SYSTEM'} = $sys;
	$self->{'TEXT'} = $text;

	if ($etype =~ /^ndata (\S+)$/i) {
	    $self->{'TYPE'} = 'ndata';
	    $self->{'NOTATION'} = $1;
	}

	if ($etype =~ /^cdata (\S+)$/i) {
	    $self->{'TYPE'} = 'cdata';
	    $self->{'NOTATION'} = $1;
	}

	bless $self, $class;
    }

    sub name {
	my $self = shift;
	my $value = shift;
	$self->{'NAME'} = $value if defined($value);
	return $self->{'NAME'};
    }

    sub type {
	my $self = shift;
	my $value = shift;
	$self->{'TYPE'} = $value if defined($value);
	return $self->{'TYPE'};
    }

    sub notation {
	my $self = shift;
	my $value = shift;
	$self->{'NOTATION'} = $value if defined($value);
	return $self->{'NOTATION'};
    }

    sub public {
	my $self = shift;
	my $value = shift;
	$self->{'PUBLIC'} = $value if defined($value);
	return $self->{'PUBLIC'};
    }

    sub system {
	my $self = shift;
	my $value = shift;
	$self->{'SYSTEM'} = $value if defined($value);
	return $self->{'SYSTEM'};
    }

    sub text {
	my $self = shift;
	my $value = shift;
	$self->{'TEXT'} = $value if defined($value);
	return $self->{'TEXT'};
    }

    sub xml {
	my $self = shift;
	my $xml = "";

	$xml .= "<entity name=\"" . $self->name() . "\"\n";
	$xml .= "        type=\"" . $self->type() . "\"\n";
	$xml .= "        notation=\"" . $self->notation() . "\"\n"
	    if $self->notation();

	if ($self->public() || $self->system()) {
	    $xml .= "        public=\"" . $self->public() . "\"\n"
		if $self->public();
	    $xml .= "        system=\"" . $self->system() . "\"\n"
		if $self->system();
	    $xml .= "/>\n";
	} else {
	    my $text = $self->{'DTD'}->expand_entities($self->text());
	    $text =~ s/\&/\&amp;/sg;

	    $xml .= ">\n";
	    $xml .= "<text-expanded>$text</text-expanded>\n";

	    if ($self->{'DTD'}->{'UNEXPANDED_CONTENT'}) {
		$text = $self->text();
		$text =~ s/\&/\&amp;/sg;
		$xml .= "<text>$text</text>\n";
	    }

	    $xml .= "</entity>\n";
	}

	return $xml;
    }
}

{
    package SGML::DTDParse::DTD::ELEMENT;

    sub new {
	my($type, $dtd, $element, $stagm, $etagm, $cm, $incl, $excl) = @_;
	my $class = ref($type) || $type;
	my $self = {};

	$cm = $dtd->fix_entityrefs($cm);
	$incl = $dtd->fix_entityrefs($incl);
	$excl = $dtd->fix_entityrefs($excl);

	if ($dtd->{'XML'} && ($cm eq 'CDATA')) {
	    $dtd->status("CDATA declared element content found in XML DTD. "
			 . "This isn't an XML DTD.", 1);
	    $dtd->{'XML'} = 0;
	}

	if ($dtd->{'XML'} && ($stagm || $etagm)) {
	    $dtd->status("Tag minimization found in XML DTD. "
			 . "This isn't an XML DTD.", 1);
	    $dtd->{'XML'} = 0;
	}

	$self->{'DTD'} = $dtd;
	$self->{'NAME'} = $element;
	$self->{'STAGM'} = $stagm;
	$self->{'ETAGM'} = $etagm;
	$self->{'CONMDL'} = $cm;
	$self->{'INCL'} = $incl;
	$self->{'EXCL'} = $excl;

	bless $self, $class;
    }

    sub name {
	my $self = shift;
	my $value = shift;
	$self->{'NAME'} = $value if defined($value);
	return $self->{'NAME'};
    }

    sub type {
	return "element";
    }

    sub starttag_min {
	my $self = shift;
	my $value = shift;
	$self->{'STAGM'} = $value if defined($value);
	return $self->{'STAGM'};
    }

    sub endtag_min {
	my $self = shift;
	my $value = shift;
	$self->{'ETAGM'} = $value if defined($value);
	return $self->{'ETAGM'};
    }

    sub content_model {
	my $self = shift;
	my $value = shift;
	$self->{'CONMDL'} = $value if defined($value);
	return $self->{'CONMDL'};
    }

    sub inclusions {
	my $self = shift;
	my $value = shift;
	$self->{'INCL'} = $value if defined($value);
	return $self->{'INCL'};
    }

    sub exclusions {
	my $self = shift;
	my $value = shift;
	$self->{'EXCL'} = $value if defined($value);
	return $self->{'EXCL'};
    }

    sub xml_content_model {
	my $self = shift;
	my $wrapper = shift;
	my $model = shift;
	my $expand = shift;
	my $xml  = "";
	my ($text, $cmtok, $cm);

#	$text = $model;
#	$text =~ s/\%/\&/sg;
	# $xml = "<$wrapper text=\"$text\">\n";
	$xml = "<$wrapper>\n";

	$text = $expand ? $self->{'DTD'}->expand_entities($model) : $model;
	$cmtok = new SGML::DTDParse::Tokenizer $text;
	$cm = new SGML::DTDParse::ContentModel $cmtok;

	$xml .= $cm->xml();

	$xml .= "</$wrapper>\n";

	return $xml;
    }

    sub xml {
	my $self = shift;
	my $xml = "";
	my($text, $cmtok, $cm, $type);

	$text = $self->content_model();
	$text = $self->{'DTD'}->expand_entities($text);
	$cmtok = new SGML::DTDParse::Tokenizer $text;
	$cm = new SGML::DTDParse::ContentModel $cmtok;

	$type = $cm->type();

	$xml .= "<element name=\"" . $self->name() . "\"";
	$xml .= " stagm=\"" . $self->starttag_min() . "\""
	    if $self->starttag_min();
	$xml .= " etagm=\"" . $self->endtag_min() . "\""
	    if $self->endtag_min();
	$xml .= "\n";
	$xml .= "         content-type=\"$type\"";
	$xml .= ">\n";

	$xml .= $self->xml_content_model('content-model-expanded',
					 $self->content_model(), 1);

	if ($self->{'DTD'}->{'UNEXPANDED_CONTENT'}) {
	    $xml .= $self->xml_content_model('content-model',
					     $self->content_model(), 0);
	}

	if ($self->inclusions()) {
	    $xml .= $self->xml_content_model('inclusions',
					     $self->inclusions(), 1);
	}

	if ($self->exclusions()) {
	    $xml .= $self->xml_content_model('exclusions',
					     $self->exclusions(), 1);
	}

	$xml .= "</element>\n";

	return $xml;
    }
}

{
    package SGML::DTDParse::DTD::ATTLIST;

    sub new {
	my $type = shift;
	my $dtd = shift;
	my $attlist = shift;
	my $attdecl = shift;
	my(@attrs) = @_;
	my $class = ref($type) || $type;
	my $self = {};

	$self->{'DTD'} = $dtd;
	$self->{'NAME'} = $attlist;
	$self->{'TYPE'} = {};
	$self->{'VALS'} = {};
	$self->{'DEFV'} = {};
	$self->{'DECL'} = $attdecl;

	while (@attrs) {
	    my $name     = shift @attrs;
	    my $values   = shift @attrs;
	    my $attrtype = shift @attrs;
	    my $defval   = shift @attrs;

	    $self->{'TYPE'}->{$name} = $attrtype;
	    $self->{'VALS'}->{$name} = $values;
	    $self->{'DEFV'}->{$name} = $defval;
	}

	bless $self, $class;
    }

    sub append {
	my $self = shift;
	my $dtd = shift;
	my $attlist = shift;
	my $attdecl = shift;
	my(@attrs) = @_;

	while (@attrs) {
	    my $name     = shift @attrs;
	    my $values   = shift @attrs;
	    my $attrtype = shift @attrs;
	    my $defval   = shift @attrs;

	    $self->{'TYPE'}->{$name} = $attrtype;
	    $self->{'VALS'}->{$name} = $values;
	    $self->{'DEFV'}->{$name} = $defval;
	}
    }

    sub name {
	my $self = shift;
	my $value = shift;
	$self->{'NAME'} = $value if defined($value);
	return $self->{'NAME'};
    }

    sub type {
	return "attlist";
    }

    sub text {
	my $self = shift;
	return $self->{'DECL'};
    }

    sub attribute_list {
	my $self = shift;
	my(@attr) = keys %{$self->{'TYPE'}};
	return @attr;
    }

    sub attribute_type {
	my $self = shift;
	my $attr = shift;
	my $value = shift;
	$self->{'TYPE'}->{$attr} = $value if defined($value);
	return $self->{'TYPE'}->{$attr};
    }

    sub attribute_values {
	my $self = shift;
	my $attr = shift;
	my $value = shift;
	$self->{'VALS'}->{$attr} = $value if defined($value);
	return $self->{'VALS'}->{$attr};
    }

    sub attribute_default {
	my $self = shift;
	my $attr = shift;
	my $value = shift;
	$self->{'DEFV'}->{$attr} = $value if defined($value);
	return $self->{'DEFV'}->{$attr};
    }

    sub xml {
	my $self = shift;
	my $xml = "";
	my(@attr) = $self->attribute_list();
	my($attr, $text);

	$xml .= "<attlist name=\"" . $self->name() . "\">\n";

	my $cdata = $self->{'DECL'};
	$cdata =~ s/&/&amp;/sg;
	$cdata =~ s/</&lt;/sg;

	$xml .= "<attdecl>$cdata</attdecl>\n";

	foreach $attr (@attr) {
	    $xml .= "<attribute name=\"$attr\"\n";

	    $text = $self->attribute_type($attr);
	    # $text =~ s/\%/\&/sg;
	    $xml .= "           type=\"$text\"\n";

	    $text = $self->attribute_values($attr);
	    # $text =~ s/\%/\&/sg;

	    my $enumtype = undef;
	    if ($text =~ /^NOTATION \(/) {
		$enumtype = "notation";
		$text = "(" . $'; # '
	    }

	    if ($text =~ /^\(/) {
		$enumtype = "yes" if !defined($enumtype);
		$xml .= "           enumeration=\"$enumtype\"\n";
		$text =~ s/[\(\)\|]/ /g;
		$text =~ s/\s+/ /g;
		$text =~ s/^\s*//;
		$text =~ s/\s*$//;
	    }

	    $xml .= "           value=\"$text\"\n";

	    $text = $self->attribute_default($attr);
	    # $text =~ s/\%/\&/sg;
	    $xml .= "           default=\"$text\"/>\n";
	}

	$xml .= "</attlist>\n";

	return $xml;
    }
}

{
    package SGML::DTDParse::DTD::NOTATION;

    sub new {
	my($type, $dtd, $notation, $pub, $sys, $text) = @_;
	my $class = ref($type) || $type;
	my $self = {};

	$self->{'DTD'} = $dtd;
	$self->{'NAME'} = $notation;
	$self->{'PUBLIC'} = $pub;
	$self->{'SYSTEM'} = $sys;

	bless $self, $class;
    }

    sub name {
	my $self = shift;
	my $value = shift;
	$self->{'NAME'} = $value if defined($value);
	return $self->{'NAME'};
    }

    sub type {
	return "notation";
    }

    sub public {
	my $self = shift;
	my $value = shift;
	$self->{'PUBLIC'} = $value if defined($value);
	return $self->{'PUBLIC'};
    }

    sub system {
	my $self = shift;
	my $value = shift;
	$self->{'SYSTEM'} = $value if defined($value);
	return $self->{'SYSTEM'};
    }

    sub xml {
	my $self = shift;
	my $xml = "";

	$xml .= "<notation name=\"" . $self->name() . "\"\n";

	$xml .= "        public=\"" . $self->public() . "\"\n"
	    if $self->public();

	if (!$self->public() || $self->system()) {
	    $xml .= "        system=\"" . $self->system() . "\"\n";
	}

	$xml .= "/>\n";

	return $xml;
    }
}

sub new {
    my $type = shift;
    my %param = @_;
    my $class = ref($type) || $type;
    my $self = bless {}, $class;
    my $cat = new SGML::DTDParse::Catalog (%param);

    $self->{'LASTMSGLEN'} = 0;
    $self->{'NEWLINE'} = 0;
    $self->{'CAT'} = $cat;
    $self->{'PENT'} = {};
    $self->{'DECLS'} = [];
    $self->{'DECLS'}->[0] = 0;
    $self->{'PENTDECL'} = [];
    $self->{'PENTDECL'}->[0] = 0;
    $self->{'GENT'} = {};
    $self->{'GENTDECL'} = [];
    $self->{'GENTDECL'}->[0] = 0;
    $self->{'ELEM'} = {};
    $self->{'ATTR'} = {};
    $self->{'NOTN'} = {};
    $self->{'VERBOSE'} = $param{'Verbose'} || $param{'Debug'};
    $self->debug($param{'Debug'});
    $self->{'TITLE'} = $param{'Title'};
    $self->{'UNEXPANDED_CONTENT'}
      = $param{'UnexpandedContent'} ? 1 : 0;
    $self->{'SOURCE_DTD'} = $param{'SourceDtd'};
    $self->{'PUBLIC_ID'} = $param{'PublicId'};
    $self->{'SYSTEM_ID'} = $param{'SystemId'};
    $self->{'DECLARATION'} = $param{'Declaration'};
    $self->{'XML'} = $param{'Xml'};
    $self->{'NAMECASE_GEN'} = $param{'NamecaseGeneral'};
    $self->{'NAMECASE_ENT'} = $param{'NamecaseEntity'};

    # There's a deficiency in the way this code is written. The entity
    # boundaries are lost as entities are loaded, so there's no way to
    # keep track of the correct "current directory" for resolving
    # relative system identifiers. To work around this problem, the list
    # of all directories accessed is kept in a path, and that path is
    # searched for relative system identifiers. This could produce the
    # wrong results, but it doesn't seem very likely. A proper solution
    # may be implemented in the future.
    $self->{'SEARCHPATH'} = ();

    delete($self->{'DTD'}); # This isn't supposed to exist yet.

    return $self;
}

sub parse {
    my $self = shift;
    my $dtd = shift;
    my $dtd_fh = \*STDIN;
    local $_;

    die "Error: Already parsed " . $self->{'DTD'} . "\n" if $self->{'DTD'};

    if (!$dtd) {
	if ($self->{'SYSTEM_ID'}) {
	    $dtd = $self->{'CAT'}->system_map($self->{'SYSTEM_ID'});
	} elsif ($self->{'PUBLIC_ID'}) {
	    $dtd = $self->{'CAT'}->public_map($self->{'PUBLIC_ID'});
	}
    }

    if (!$dtd) {
	$self->status('Reading DTD from stdin...', 1);
	$self->{'DTD'} = '<osfd>0';
    } else {
	$self->{'DTD'} = $dtd;
    }
    if (!$self->{'SYSTEM_ID'}) {
	$self->{'SYSTEM_ID'} = $self->{'DTD'};
    }

    my $decl = $self->{'DECLARATION'};

    if (!$decl) {
	if ($self->{'PUBLIC_ID'}) {
	    $decl = $self->{'CAT'}->declaration($self->{'PUBLIC_ID'});
	} else {
	    my $pubid = $self->{'CAT'}->reverse_public_map($dtd);
	    $decl = $self->{'CAT'}->declaration($pubid);
	}
    }

    if ($self->{'PUBLIC_ID'}) {
	$self->status('Public ID: ' . $self->{'PUBLIC_ID'}, 1);
    } else {
	$self->status('Public ID: unknown', 1);
    }

    $self->status('System ID: ' . $self->{'SYSTEM_ID'}, 1);

    if ($decl) {
	$self->{'DECLARATION'} = $decl;
	$self->status("SGML declaration: $decl", 1);
	my($xml, $namecase, $entitycase) = $self->parse_decl($decl);
	$self->{'XML'} = $xml;
	$self->{'NAMECASE_GEN'} = $namecase;
	$self->{'NAMECASE_ENT'} = $entitycase;
    } else {
	$self->status("SGML declaration: unknown, using defaults for xml and namecase", 1);
    }

    if ($dtd) {
	use Symbol;
	$dtd_fh = gensym;
	open($dtd_fh, $dtd) || die qq{Error: Unable to open "$dtd": $!\n};
    }
    {
	# slurp up entire file
	local $/;
	$_ = <$dtd_fh>;
    }
    close ($dtd_fh)  if $dtd;

    $self->add_to_searchpath($dtd || '.');

    my ($tok, $rest) = $self->next_token($_);
    while ($tok) {
	if ($tok =~ /<!ENTITY/is) {
	    $rest = $self->parse_entity($rest);
	} elsif ($tok =~ /<!ELEMENT/is) {
	    $rest = $self->parse_element($rest);
	} elsif ($tok =~ /<!ATTLIST/is) {
	    $rest = $self->parse_attlist($rest);
	} elsif ($tok =~ /<!NOTATION/is) {
	    $rest = $self->parse_notation($rest);
	} elsif ($tok =~ /<!\[/) {
	    $rest = $self->parse_markedsection($rest);
	} else {
	    die "Error: Unexpected declaration: $tok\n";
	}

	($tok, $rest) = $self->next_token($rest);
    }

    $self->status("Parse complete.\n");

    return $self;
}

sub parseCatalog {
    my $self = shift;
    my $catalog = shift;

    $self->{'CAT'}->parse($catalog);
}

sub verbose {
    my $self = shift;
    my $val = shift;
    my $verb = $self->{'VERBOSE'};

    $self->{'VERBOSE'} = $val if defined($val);

    return $verb;
}

sub debug {
    my $self = shift;
    my $val = shift;
    my $dbg = $debug;
 
    if (defined($val)) {
	$debug = $val;
        if (ref($self)) {
            $self->{'DEBUG'} = $debug;
        }
    }
    return $dbg;
}

# ======================================================================

sub add_entity {
    my($self, $name, $type, $public, $system, $text) = @_;
    my $entity = new SGML::DTDParse::DTD::ENTITY $self, $name, $type, $public, $system, $text;
    my $count;

    if ($type eq 'param') {
	return if exists($self->{'PENT'}->{$name});
	$count = $self->{'PENTDECL'}->[0] + 1;
	$self->{'PENT'}->{$name} = $count;
	$self->{'PENTDECL'}->[0] = $count;
	$self->{'PENTDECL'}->[$count] = $entity;

	$count = $self->{'DECLS'}->[0] + 1;
	$self->{'DECLS'}->[0] = $count;
	$self->{'DECLS'}->[$count] = $entity;
    } else {
	return if exists($self->{'GENT'}->{$name});
	$count = $self->{'GENTDECL'}->[0] + 1;
	$self->{'GENT'}->{$name} = $count;
	$self->{'GENTDECL'}->[0] = $count;
	$self->{'GENTDECL'}->[$count] = $entity;

	$count = $self->{'DECLS'}->[0] + 1;
	$self->{'DECLS'}->[0] = $count;
	$self->{'DECLS'}->[$count] = $entity;
    }
}

sub pent {
    my $self = shift;
    my $name = shift;
    my $count = $self->{'PENT'}->{$name};

    return undef if !$count;

    return $self->{'PENTDECL'}->[$count];
}

sub gent {
    my $self = shift;
    my $name = shift;
    my $count = $self->{'GENT'}->{$name};

    return undef if !$count;

    return $self->{'GENTDECL'}->[$count];
}

sub declaration_count {
    my $self = shift;
    return $self->{'DECLS'}->[0];
}

sub declarations {
    my $self = shift;
    my @decls = @{$self->{'DECLS'}};
    shift @decls;
    return @decls;
}

# ======================================================================

sub xml_elements {
    my $self = shift;
    my $fh   = shift;
    my %output = ();

    foreach $_ (keys %{$self->{'NOTN'}}) {
	print $fh $self->{'NOTN'}->{$_}->xml(), "\n";
    }

    foreach $_ (keys %{$self->{'PENT'}}) {
	print $fh $self->pent($_)->xml(), "\n";
    }

    foreach $_ (keys %{$self->{'GENT'}}) {
	print $fh $self->gent($_)->xml(), "\n";
    }

    foreach $_ (keys %{$self->{'ELEM'}}) {
	print $fh $self->{'ELEM'}->{$_}->xml(), "\n";
	print $fh $self->{'ATTR'}->{$_}->xml(), "\n"
	    if exists ($self->{'ATTR'}->{$_});
	$output{$_} = 1;
    }

    foreach $_ (keys %{$self->{'ATTR'}}) {
	print $fh $self->{'ATTR'}->{$_}->xml(), "\n" if !$output{$_};
    }
}

sub xml {
    my $self = shift;
    my $fh = shift;
    my $count;

    print $fh "<!DOCTYPE dtd PUBLIC \"$DTDPUBID\"\n";
    print $fh "              \"$DTDSYSID\" [\n";

#    for ($count = 1; $count <= $self->{'PENTDECL'}->[0]; $count++) {
#	my($pent) = $self->{'PENTDECL'}->[$count];
#	next if $pent->system() || $pent->public();
#	print $fh "<!ENTITY ", $pent->name(), " \"&#37;", $pent->name(), ";\">\n";
#    }

    for ($count = 1; $count <= $self->{'GENTDECL'}->[0]; $count++) {
	my $gent = $self->{'GENTDECL'}->[$count];

	if ($gent->type() ne 'sdata') {
	    my $name = $gent->name();
	    my $text = $gent->text();

	    $text = "&#38;#38;" if $text eq '&#38;';
	    $text = "&#38;#60;" if $text eq '&#60;';

	    print $fh "<!ENTITY $name \"$text\">\n";
	} elsif ($gent->type() ne 'pi') {
	    my $name = $gent->name();
	    my $text = $gent->text();

	    $text = "&#38;#38;" if $text eq '&#38;';
	    $text = "&#38;#60;" if $text eq '&#60;';

	    print $fh "<!ENTITY $name \"$text\">\n";
	}
    }

    print $fh "]>\n";
    print $fh "<dtd version='$DTDVERSION'\n";
    print $fh "     unexpanded='", $self->{'UNEXPANDED_CONTENT'}, "'\n";
    print $fh "     title=\"", entify($self->{'TITLE'}), "\"\n";
    print $fh "     namecase-general=\"", $self->{'NAMECASE_GEN'}, "\"\n";
    print $fh "     namecase-entity=\"", $self->{'NAMECASE_ENT'}, "\"\n";
    print $fh "     xml=\"", $self->{'XML'}, "\"\n";
    print $fh "     system-id=\"", entify($self->{'SYSTEM_ID'}), "\"\n";
    print $fh "     public-id=\"", entify($self->{'PUBLIC_ID'}), "\"\n";
    print $fh "     declaration=\"", $self->{'DECLARATION'}, "\"\n";
    print $fh "     created-by=\"DTDParse V$SGML::DTDParse::VERSION\"\n";
    print $fh "     created-on=\"", scalar(localtime()), "\"\n";
    print $fh ">\n";

    $self->xml_elements($fh);
    print $fh "</dtd>\n";
}

# ======================================================================

sub parse_entity {
    my $self = shift;
    my $dtd = shift;
    my($type, $name) = ('gen', undef);
    my($public, $system, $text) = ("", "", "");
    my($tok);

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok eq '%') {
	$type = 'param';
	($tok, $dtd) = $self->next_token($dtd);
    }

    $name = $tok;

    $tok = $self->peek_token($dtd);

    if ($tok =~ /^[\"\']/) {
	# we're looking at text...
	($text, $dtd) = $self->next_token($dtd);
	$text = $self->trim_quotes($text);
    } else {
	($tok, $dtd) = $self->next_token($dtd);

	if ($tok =~ /public/i) {
	    ($public, $dtd) = $self->next_token($dtd);
	    $public = $self->trim_quotes($public);
	    $tok = $self->peek_token($dtd);
	    if ($tok ne '>') {
		($system, $dtd) = $self->next_token($dtd);
		$system = $self->trim_quotes($system);
	    }
	} elsif ($tok =~ /system/i) {
	    ($system, $dtd) = $self->next_token($dtd);
	    $system = $self->trim_quotes($system);
	} elsif ($tok =~ /^sdata$/i) {
	    $type = 'sdata';
	    ($text, $dtd) = $self->next_token($dtd);
	    $text = $self->trim_quotes($text);
	} elsif ($tok =~ /^pi$/i) {
	    $type = 'pi';
	    ($text, $dtd) = $self->next_token($dtd);
	    $text = $self->trim_quotes($text);
	} elsif ($tok =~ /^cdata$/i) {
	    $type = 'cdata';
	    ($text, $dtd) = $self->next_token($dtd);
	    $text = $self->trim_quotes($text);
	} else {
	    die "Error: Unexpected declared entity type ($name): $tok\n";
	}
    }

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok =~ /ndata/i) {
	($tok, $dtd) = $self->next_token($dtd);
	# now $tok contains the notation name
	$type = "ndata $tok";
	($tok, $dtd) = $self->next_token($dtd);
	# now $tok should contain the token after the notation
    } elsif ($tok =~ /cdata/i) {
	($tok, $dtd) = $self->next_token($dtd);
	# now $tok contains the notation name
	$type = "cdata $tok";
	($tok, $dtd) = $self->next_token($dtd);
	# now $tok should contain the token after the notation
    }

    if ($tok ne '>') {
	print "[[", substr($dtd, 0, 100), "]]\n";
	die "Error: Unexpected token in ENTITY declaration: $tok\n";
    }

    print STDERR "ENT: $type $name (P: $public) (S: $system) [$text]\n" if $debug>1;

    $self->status("Entity $name");

    $self->add_entity($name, $type, $public, $system, $text);

    return $dtd;
}

sub parse_element {
    my $self = shift;
    my $dtd = shift;
    my(@names) = ();
    my($stagm, $etagm) = ('', '');
    my $mc = new Text::DelimMatch '\(', '\)[\?\+\*\,]*';
    my($tok, $cm, $expand, $rest);
    my($incl, $excl, $name);

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok =~ /^\(/) {
	my($pre, $namegrp, $ntok, $rest);
	($pre, $namegrp, $dtd) = $mc->match($tok . $dtd);

	($ntok, $rest) = $self->next_token($namegrp);
	while ($ntok) {
	    if ($ntok =~ /[\|\(\)]/) {
		# nop
	    } else {
		push (@names, $ntok);
	    }
	    ($ntok, $rest) = $self->next_token($rest);
	}
    } else {
	push (@names, $tok);
    }

    # we need to look ahead a little bit here so that we can handle
    # the case where the start/end tag minimization flags are in
    # a parameter entity without accidentally expanding parameter
    # entities in the content model...

    ($tok, $dtd) = $self->next_token($dtd, 1);

    if ($tok =~ /^\%/) {
	# check to see what this is...
	($expand, $rest) = $self->next_token($tok);

	if ($expand =~ /^[\-o]/is) {
	    $stagm = $expand;
	    $dtd = $rest . $dtd;
	    ($etagm, $dtd) = $self->next_token($dtd);
	} else {
  	    $dtd = $tok . $dtd  if $expand =~ /\S/;
	}
    } elsif ($tok =~ /^[\-o]/is) {
	$stagm = $tok;
	($etagm, $dtd) = $self->next_token($dtd);
    } else {
	$dtd = $tok . $dtd;
    }

    # ok, now $dtd begins with the content model...
    ($tok, $dtd) = $self->next_token($dtd, 1);

    if ($tok eq '(') {
	my($pre, $match);
	($pre, $match, $dtd) = $mc->match($tok . $dtd);
	$cm = $match;
    } else {
	$cm = $tok;
    }

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok eq '-') {
	my($pre, $match);
	($pre, $match, $dtd) = $mc->match($tok . $dtd);
	$excl = $match;
	($tok, $dtd) = $self->next_token($dtd);
    }

    if ($tok eq '+') {
	my($pre, $match);
	($pre, $match, $dtd) = $mc->match($tok . $dtd);
	$incl = $match;
	($tok, $dtd) = $self->next_token($dtd);
    }

    if ($tok ne '>') {
	die "Error: Unexpected token in ELEMENT declaration: $tok\n";
    }

    foreach $name (@names) {
	$self->status("Element $name");

	if (exists($self->{'ELEM'}->{$name})) {
	    warn "Warning: Duplicate element declaration for $name ignored.\n";
	} else {
	    my $elem = new SGML::DTDParse::DTD::ELEMENT $self, $name, $stagm,$etagm, $cm, $incl, $excl;

	    $self->{'ELEM'}->{$name} = $elem;

	    my $count = $self->{'DECLS'}->[0] + 1;
	    $self->{'DECLS'}->[0] = $count;
	    $self->{'DECLS'}->[$count] = $elem;
	}

	print STDERR "ELEM: $name = $cm -($excl) +($incl)\n" if $debug>1;
    }

    return $dtd;
}

sub parse_attlist {
    my $self = shift;
    my $dtd = shift;
    my(@names) = ();
    my $mc = new Text::DelimMatch '\(', '\)[\?\+\*\,]*';
    my(@attr) = ();
    my($name, $values, $defval, $type, $tok, $notation_hack);

    # name   is name
    # values is CDATA or an enumeration (for example)
    # defval is a default value
    # type   is #IMPLIED, #FIXED, #REQUIRED, etc.

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok =~ /^\(/) {
	my($pre, $namegrp, $ntok, $rest);
	($pre, $namegrp, $dtd) = $mc->match($tok . $dtd);

	($ntok, $rest) = $self->next_token($namegrp);
	while ($ntok) {
	    if ($ntok =~ /[\|\(\)]/) {
		# nop
	    } else {
		push (@names, $ntok);
	    }
	    ($ntok, $rest) = $self->next_token($rest);
	}
    } else {
	push (@names, $tok);
    }

    print STDERR "\nATTLIST ", join(" ", @names), "\n" if $debug > 2;

    # now we're looking at the attribute declarations...

    # first grab the whole darn thing, unexpanded...
    # this is a tad iffy, perhaps, but I think it always works...
    $dtd =~ /^(.*?)>/is;
    my $attdecl = $1;

    # then we can look at the expanded thing...
    ($tok, $dtd) = $self->next_token($dtd);
    while ($tok ne '>') {
	$name = $tok;
	($values, $dtd) = $self->next_token($dtd);

	$defval = "";
	$type = "";

	print STDERR "$name\n" if $debug > 2;

	$notation_hack = "";
	if ($values =~ /^notation$/i) {
	    if ($self->peek_token($dtd)) {
		$notation_hack = "NOTATION ";
		($values, $dtd) = $self->next_token($dtd);
	    }
	}

	if ($values eq '(') {
	    my(@enum) = ();
	    my($pre, $enum, $ntok, $rest);

	    ($pre, $enum, $dtd) = $mc->match($values . $dtd);
	    ($ntok, $rest) = $self->next_token($enum);
	    print STDERR "\$rest = $rest\n"  if $debug>4;
	    while ($ntok ne '') {
		print STDERR "\$ntok = $ntok\n"  if $debug>4;
		if ($ntok =~ /[,\|\(\)]/) {
		    # nop
		} else {
		    print STDERR "Adding to \@enum: $ntok\n"  if $debug>4;
		    push (@enum, $ntok);
		}
		($ntok, $rest) = $self->next_token($rest);
	    }

	    $values = $notation_hack . '(' . join("|", @enum) . ')';
	}

	print STDERR "\t$values\n" if $debug > 2;

	($type, $dtd) = $self->next_token($dtd);

	print STDERR "\t$type\n" if $debug > 2;

	if ($type =~ /\#FIXED/i) {
	    ($defval, $dtd) = $self->next_token($dtd);
	    $defval = $self->trim_quotes($defval) if $defval =~ /^[\"\']/;
	} elsif ($type !~ /^\#/) {
	    $defval = $type;
	    $defval = $self->trim_quotes($defval) if $defval =~ /^[\"\']/;
	    $type = "";
	}

	print STDERR "\t$defval\n" if $debug > 2;

	push (@attr, $name, $values, $type, $defval);

	($tok, $dtd) = $self->next_token($dtd);
    }

    foreach $name (@names) {
	$self->status("Attlist $name");

	if (exists($self->{'ATTR'}->{$name})) {
	    my $attlist = $self->{'ATTR'}->{$name};
	    $attlist->append($self, $name, $attdecl, @attr);
	    warn ": duplicate attlist declaration for $name appended.\n";
	} else {
	    my $attlist = new SGML::DTDParse::DTD::ATTLIST $self, $name, $attdecl, @attr;
	    $self->{'ATTR'}->{$name} = $attlist;

	    my $count = $self->{'DECLS'}->[0] + 1;
	    $self->{'DECLS'}->[0] = $count;
	    $self->{'DECLS'}->[$count] = $attlist;
	}
    }

    return $dtd;
}

sub parse_notation {
    my $self = shift;
    my $dtd = shift;
    my $name = undef;
    my($public, $system, $text) = ("", "", "");
    my($tok);

    ($name, $dtd) = $self->next_token($dtd);
    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok =~ /public/i) {
	($public, $dtd) = $self->next_token($dtd);
	$public = $self->trim_quotes($public);

	$tok = $self->peek_token($dtd);
	if ($tok ne '>') {
	    ($system, $dtd) = $self->next_token($dtd);
	    $system = $self->trim_quotes($system);
	}
    } elsif ($tok =~ /system/i) {
	$tok = $self->peek_token($dtd);
	if ($tok eq '>') {
	    $system = "";
	} else {
	    ($system, $dtd) = $self->next_token($dtd);
	    $system = $self->trim_quotes($system);
	}
    } else {
	$text = $self->trim_quotes($tok);
    }

    ($tok, $dtd) = $self->next_token($dtd);

    if ($tok ne '>') {
	die "Error: Unexpected token in NOTATION declaration: $tok\n";
    }

    print STDERR "NOT: $name (P: $public) (S: $system) [$text]\n" if $debug > 1;

    $self->status("Notation $name");

    if (exists($self->{'NOTN'}->{$name})) {
	warn "Warning: Duplicate notation declaration for $name ignored.\n";
    } else {
	my $notation = new SGML::DTDParse::DTD::NOTATION $self, $name, $public, $system, $text;

	$self->{'NOTN'}->{$name} = $notation;

	my $count = $self->{'DECLS'}->[0] + 1;
	$self->{'DECLS'}->[0] = $count;
	$self->{'DECLS'}->[$count] = $notation;
    }

    return $dtd;
}

sub parse_markedsection {
    my $self = shift;
    my $dtd = shift;
    my $mc = new Text::DelimMatch '<!\[.*?\[', '\]\]\>';
    my($tok, $pre, $match, $ms);

    ($tok, $dtd) = $self->next_token($dtd);

    ($pre, $ms, $dtd) = $mc->match("<![$tok" . $dtd);

    if ($tok =~ /^include$/i) {
	$ms =~ /^<!\[.*?\[(.*)\]\]\>$/s;
	$dtd = $1 . $dtd;
    }

    return $dtd;
}

sub peek_token {
    my $self = shift;
    my $dtd = shift;
    my $return_peref = shift;
    my $tok;

    ($tok, $dtd) = $self->next_token($dtd, $return_peref);

    return $tok;
}

sub next_token {
    my $self = shift;
    my $dtd = shift;
    my $return_peref = shift;

    $dtd =~ s/^\s*//sg;

    if ($dtd =~ /^<!--.*?-->/s) {
	# comment declaration
	return $self->next_token($'); # '
    }

    if ($dtd =~ /^--.*?--/s) {
	# comment
	return $self->next_token($'); # '
    }

    if ($dtd =~ /^<\?.*?>/s) {
	# processing instruction
	return $self->next_token($'); # '
    }

    if ($dtd =~ /^<!\[/s) {
	# beginning of a marked section
	print STDERR "TOK: [$&]\n" if $debug > 3;
	return ($&, $'); # '
    }

    if ($dtd =~ /^[\(\)\-\+\|\&\,\>]/) {
	# beginning of a model group, or incl., or excl., or end decl
	print STDERR "TOK: [$&]\n" if $debug > 3;
	return ($&, $'); # '
    }

    if ($dtd =~ /^[\"\']/) {
	# quoted string
	$dtd =~ /^(([\"\'])(.*?)\2)/s;
	print STDERR "TOK: [$1]\n" if $debug > 3;
	return ($&, $'); # '
    }

    if ($dtd =~ /^\%([a-zA-Z0-9\_\-\.]+);?/) {
	# peref
	print STDERR "TOK: [$1]\n" if $debug > 3;
	if ($return_peref) {
	    return ("%$1;", $'); # '
	} else {
	    my $repltext = $self->entity_repl($1);
	    $dtd = $repltext . $'; # '
	    return $self->next_token($dtd);
	}
    }

    if ($dtd =~ /^([^\s\|\&\,\(\)\[\]\>\%]+)/s) {
	# next non-space sequence
	print STDERR "TOK: [$1]\n" if $debug > 3;
	return ($1, $'); # '
    }

    if ($dtd =~ /^(\%)/s) {
	# lone % (for param entity declarations)
	print STDERR "TOK: [$1]\n" if $debug > 3;
	return ($1, $');
    }

    print STDERR "TOK: <<none>>\n" if $debug > 3;
    return (undef, $dtd);
}

sub entity_repl {
    my $self = shift;
    my $name = shift;
    my $entity = $self->pent($name);
    local(*F, $_);

    die "Error: %$name; undeclared.\n" if !$entity;

    if ($entity->{'PUBLIC'} || $entity->{'SYSTEM'}) {
	my $id = "";
	my $filename = "";

	if ($entity->{'PUBLIC'}) {
	    $id = $entity->{'PUBLIC'};
	    $filename = $self->{'CAT'}->public_map($id);
	}

	if (!$filename && $entity->{'SYSTEM'}) {
	    $id = $entity->{'SYSTEM'};
	    $filename = $self->{'CAT'}->system_map($id);
	}

	if (!defined($filename)) {
	    die "%Error: $name; ($id): not found in catalog.\n";
	}

	if ($self->debug()) {
	    $self->status("Loading $id\n\t($filename)", 1);
	} else {
	    $self->status("Loading $id", 1);
	}

	$filename = $self->resolve_relativesystem($filename);

	$self->add_to_searchpath($filename);

	open (F, $filename) ||
	    die qq{\n%Error: $name;: Unable to open "$filename": $! \n};
	{
	    local $/;
	    $_ = <F>;
	}
	close (F);
	return $_;
    } else {
	return $entity->{'TEXT'};
    }
}

sub trim_quotes {
    my $self = shift;
    my $text = shift;

    if ($text =~ /^\"(.*)\"$/s) {
	$text = $1;
    } elsif ($text =~ /^\'(.*)\'$/s) {
	$text = $1;
    } else {
	die "Error: Unexpected text: $text\n";
    }

    return $text;
}

sub fix_entityrefs {
    my $self = shift;
    my $text = shift;

    if ($text ne "") {
	my $value = "";

	# make sure all entity references end in semi-colons
	while ($text =~ /^(.*?)([\&\%]\#?[-.:_a-z0-9]+;?)(.*)$/si) {
	    my $entref = $2;
	    $value .= $1;
	    $text = $3;

	    if ($entref =~ /\;$/s) {
		$value .= $entref;
	    } else {
		$value .= $entref . ";";
	    }
	}

	$text = $value . $text;
    }

    return $text;
}

sub expand_entities {
    my $self = shift;
    my $text = shift;

    while ($text =~ /\%(.*?);/) {
	my $pre = $`;
	my $pename = $1;
	my $post = $'; # '

	$text = $pre . $self->entity_repl($pename) . $post;
    }

    return $text;
}

sub parse_decl {
    my $self = shift;
    my $decl = shift;
    local (*F, $_);
    my $xml = 0;
    my $namecase_gen = 1;
    my $namecase_ent = 0;

    if (!open (F, $decl)) {
	$self->status(qq{Warning: Failed to load declaration "$decl": $!}, 1);
	return ($xml, $namecase_gen, $namecase_ent);
    }

    {
	local $/;
	$_ = <F>;
    }
    close (F);

#    <!SGML -- SGML Declaration for valid XML documents --
#     "ISO 8879:1986 (WWW)"

    s/--.*?--//gs; # get rid of comments
    if (!/<!SGML/) {
	return ($xml, $namecase_gen, $namecase_ent);
    }

    if (/<!SGML\s*\"([^\"]+\(WWW\))\"/is) {
	# this is XML
	return (1, 0, 0);
    }

    if (/namecase\s+/is) {
	$_ = $'; # '
	my @words = split(/\s+/is, $_);
	my $done = 0;

	while (!$done) {
	    my $word = shift @words;

	    if ($word =~ /^general$/i) {
		$word = shift @words;
		$namecase_gen = ($word =~ /^yes$/i);
	    } elsif ($word =~ /^entity$/i) {
		$word = shift @words;
		$namecase_ent = ($word =~ /^yes$/i);
	    } else {
		$done = 1;
	    }
	}
    } else {
	print "No namecase declaration???\n";
    }

    return ($xml, $namecase_gen, $namecase_ent);
}

sub add_to_searchpath {
    my $self = shift;
    my $file = shift;
    my $searchpath = ".";
    my $found = 0;

    $file =~ s/\\/\//sg;
    $searchpath = $1 if $file =~ /^(.*)\/[^\/]+$/;

    foreach my $path (@{$self->{'SEARCHPATH'}}) {
	$found = 1 if $path eq $searchpath;
    }

    push (@{$self->{'SEARCHPATH'}}, $searchpath)
	if !$found && $searchpath;
}

sub resolve_relativesystem {
    my $self = shift;
    my $system = shift;
    my $found = 0;
    my $resolved = $system;

    return $system if ($system =~ /^\//) || ($system =~ /^[a-z]:[\\\/]/);

    foreach my $path (@{$self->{'SEARCHPATH'}}) {
	if (-f "$path/$system") {
	    $found = 1;
	    $resolved = "$path/$system";
	    last;
	}
    }

    if ($found) {
	$self->add_to_searchpath($resolved);
    } else {
	$self->status("Could not resolve relative path: $system", 1);
    }

    return $resolved;
}

sub status {
    my $self = shift;
    my $msg = shift;
    my $persist = shift;

    return if !$self->verbose();

    if ($self->debug() || $self->{'NEWLINE'}) {
	print STDERR "\n";
    } else {
	print STDERR "\r";
	print STDERR " " x $self->{'LASTMSGLEN'};
	print STDERR "\r";
    }

    print STDERR $msg;

    $self->{'LASTMSGLEN'} = length($msg);
    $self->{'NEWLINE'} = $persist || (length($msg) > 79);
}

1;

__END__

=head1 NAME

SGML::DTDParse::DTD - Parse an SGML or XML DTD.

=head1 SYNOPSIS

  use SGML::DTDParse::DTD;

  $dtd = SGML::DTDParse::DTD->new( %options );
  $dtd->parse($dtd_file);
  $dtd->xml($file_handle);

=head1 DESCRIPTION

B<SGML::DTDParse::DTD> is the main module for parsing a DTD.  Normally,
this module is not used directly with the program L<dtdparse|dtdparse>
being the prefered usage model for parsing a DTD.

=head1 CONSTRUCTOR METHODS

TODO.

=head1 METHODS

TODO.

=head1 SEE ALSO

L<dtdparse|dtdparse>

See L<SGML::DTDParse|SGML::DTDParse> for an overview of the DTDParse package.

=head1 PREREQUISITES

B<Text::DelimMatch>

=head1 AVAILABILITY

E<lt>I<http://dtdparse.sourceforge.net/>E<gt>

=head1 AUTHORS

Originally developed by Norman Walsh, E<lt>ndw@nwalsh.comE<gt>.

Earl Hood E<lt>earl@earlhood.comE<gt> picked up support and
maintenance.

=head1 COPYRIGHT AND LICENSE

See L<SGML::DTDParse|SGML::DTDParse> for copyright and license information.

