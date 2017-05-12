# $Id: SAX.pm,v 1.25 2003/01/29 18:01:08 matt Exp $

package Pod::SAX;

$VERSION = '0.14';
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

use strict;
use XML::SAX::DocumentLocator;

sub _parse_bytestream {
    my ($self, $fh) = @_;
    my $parser = Pod::SAX::Parser->new();
    $parser->set_parent($self);
    $parser->parse_from_filehandle($fh, undef);
}

sub _parse_characterstream {
    my ($self, $fh) = @_;
    die "parse_characterstream not supported";
}

sub _parse_string {
    my ($self, $str) = @_;
    my $parser = Pod::SAX::Parser->new();
    $parser->set_parent($self);
    my $strobj = Pod::SAX::StringIO->new($str);
    $parser->parse_from_filehandle($strobj, undef);
}

sub _parse_systemid {
    my ($self, $sysid) = @_;
    my $parser = Pod::SAX::Parser->new();
    $parser->set_parent($self);
    $parser->parse_from_file($sysid, undef);
}

package Pod::SAX::Parser;

use Pod::Parser;
use vars qw(@ISA %HTML_Escapes);
@ISA = qw(Pod::Parser);

%HTML_Escapes = (
    'amp'       =>      '&',    #   ampersand
    'lt'        =>      '<',    #   left chevron, less-than
    'gt'        =>      '>',    #   right chevron, greater-than
    'quot'      =>      '"',    #   double quote
    'sol'       =>      '/',    #   slash
    'verbar'    =>      '|',    #   vertical bar

    "Aacute"    =>      "\xC3\x81", #   capital A, acute accent
    "aacute"    =>      "\xC3\xA1", #   small a, acute accent
    "Acirc"     =>      "\xC3\x82", #   capital A, circumflex accent
    "acirc"     =>      "\xC3\xA2", #   small a, circumflex accent
    "AElig"     =>      "\xC3\x86", #   capital AE diphthong (ligature)
    "aelig"     =>      "\xC3\xA6", #   small ae diphthong (ligature)
    "Agrave"    =>      "\xC3\x80", #   capital A, grave accent
    "agrave"    =>      "\xC3\xA0", #   small a, grave accent
    "Aring"     =>      "\xC3\x85", #   capital A, ring
    "aring"     =>      "\xC3\xA5", #   small a, ring
    "Atilde"    =>      "\xC3\x83", #   capital A, tilde
    "atilde"    =>      "\xC3\xA3", #   small a, tilde
    "Auml"      =>      "\xC3\x84", #   capital A, dieresis or umlaut mark
    "auml"      =>      "\xC3\xA4", #   small a, dieresis or umlaut mark
    "Ccedil"    =>      "\xC3\x87", #   capital C, cedilla
    "ccedil"    =>      "\xC3\xA", #   small c, cedilla
    "Eacute"    =>      "\xC3\x89", #   capital E, acute accent
    "eacute"    =>      "\xC3\xA9", #   small e, acute accent
    "Ecirc"     =>      "\xC3\x8A", #   capital E, circumflex accent
    "ecirc"     =>      "\xC3\xAA", #   small e, circumflex accent
    "Egrave"    =>      "\xC3\x88", #   capital E, grave accent
    "egrave"    =>      "\xC3\xA8", #   small e, grave accent
    "ETH"       =>      "\xC3\x90", #   capital Eth, Icelandic
    "eth"       =>      "\xC3\xB0", #   small eth, Icelandic
    "Euml"      =>      "\xC3\x8B", #   capital E, dieresis or umlaut mark
    "euml"      =>      "\xC3\xAB", #   small e, dieresis or umlaut mark
    "Iacute"    =>      "\xC3\x8D", #   capital I, acute accent
    "iacute"    =>      "\xC3\xAD", #   small i, acute accent
    "Icirc"     =>      "\xC3\x8E", #   capital I, circumflex accent
    "icirc"     =>      "\xC3\xAE", #   small i, circumflex accent
    "Igrave"    =>      "\xC3\x8D", #   capital I, grave accent
    "igrave"    =>      "\xC3\xAD", #   small i, grave accent
    "Iuml"      =>      "\xC3\x8F", #   capital I, dieresis or umlaut mark
    "iuml"      =>      "\xC3\xAF", #   small i, dieresis or umlaut mark
    "Ntilde"    =>      "\xC3\x91",         #   capital N, tilde
    "ntilde"    =>      "\xC3\xB1",         #   small n, tilde
    "Oacute"    =>      "\xC3\x93", #   capital O, acute accent
    "oacute"    =>      "\xC3\xB3", #   small o, acute accent
    "Ocirc"     =>      "\xC3\x94", #   capital O, circumflex accent
    "ocirc"     =>      "\xC3\xB4", #   small o, circumflex accent
    "Ograve"    =>      "\xC3\x92", #   capital O, grave accent
    "ograve"    =>      "\xC3\xB2", #   small o, grave accent
    "Oslash"    =>      "\xC3\x98", #   capital O, slash
    "oslash"    =>      "\xC3\xB8", #   small o, slash
    "Otilde"    =>      "\xC3\x95", #   capital O, tilde
    "otilde"    =>      "\xC3\xB5", #   small o, tilde
    "Ouml"      =>      "\xC3\x96", #   capital O, dieresis or umlaut mark
    "ouml"      =>      "\xC3\xB6", #   small o, dieresis or umlaut mark
    "szlig"     =>      "\xC3\x9F",         #   small sharp s, German (sz ligature)
    "THORN"     =>      "\xC3\x9E", #   capital THORN, Icelandic
    "thorn"     =>      "\xC3\xBE", #   small thorn, Icelandic
    "Uacute"    =>      "\xC3\x9A", #   capital U, acute accent
    "uacute"    =>      "\xC3\xBA", #   small u, acute accent
    "Ucirc"     =>      "\xC3\x9B", #   capital U, circumflex accent
    "ucirc"     =>      "\xC3\xBB", #   small u, circumflex accent
    "Ugrave"    =>      "\xC3\x99", #   capital U, grave accent
    "ugrave"    =>      "\xC3\xB9", #   small u, grave accent
    "Uuml"      =>      "\xC3\x9C", #   capital U, dieresis or umlaut mark
    "uuml"      =>      "\xC3\xBC", #   small u, dieresis or umlaut mark
    "Yacute"    =>      "\xC3\x9D", #   capital Y, acute accent
    "yacute"    =>      "\xC3\xBD", #   small y, acute accent
    "yuml"      =>      "\xC3\xBF", #   small y, dieresis or umlaut mark

    "lchevron"  =>      "\xC2\xAB", #   left chevron (double less than)
    "rchevron"  =>      "\xC2\xBB", #   right chevron (double greater than)
);

sub sex {
    require Data::Dumper;$Data::Dumper::Indent=1;warn(Data::Dumper::Dumper(@_));
}

sub set_parent {
    my $self = shift;
    $self->{parent} = shift;
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub begin_pod {
    my $self = shift;
    my $sysid = $self->parent->{ParserOptions}->{Source}{SystemId};
    $self->parent->set_document_locator(
         XML::SAX::DocumentLocator->new(
            sub { "" },
            sub { $sysid },
            sub { $self->{line_number} },
            sub { 0 },
        ),
    );
    $self->parent->start_document({});
    $self->parent->start_element(_element('pod'));
    $self->parent->characters({Data => "\n"});
    $self->parent->comment({Data => " Pod::SAX v$Pod::SAX::VERSION, using POD::Parser v$Pod::Parser::VERSION "});
    $self->parent->characters({Data => "\n"});
}

sub end_pod {
    my $self = shift;
    if ($self->{in_verbatim}) {
	$self->parent->end_element(_element('verbatim', 1));
	$self->parent->characters({Data => "\n"});
    }
    while ($self->{in_list}) {
	$self->close_list();
    }
    $self->parent->end_element(_element('pod', 1));
    $self->parent->end_document({});
}

sub open_list {
    my $self = shift;
    my ($list_type) = @_;
    $self->{list_type}[$self->{in_list}] = $list_type;
    $self->parent->characters({Data => (" " x $self->{in_list})});
    my $el = _element($list_type);
    _add_attrib($el, indent_width => $self->{indent});
    $self->parent->start_element($el);
    $self->parent->characters({Data => "\n"});
    $self->{open_lists}--;
    return;
}

sub close_list {
    my $self = shift;
    
    if ($self->{in_item}) {
	$self->parent->end_element(_element('listitem', 1));
	$self->parent->characters({Data => "\n"});
	$self->{in_item}--;
    }
    
    my $list_type = $self->{list_type}[$self->{in_list}];
    $self->{list_type}[$self->{in_list}] = undef;
    $self->parent->characters({Data => (" " x $self->{in_list})});
    $self->{in_list}--;
    $self->parent->end_element(_element($list_type, 1));
    $self->parent->characters({Data => "\n"});
    return;
}

sub command { 
    my ($self, $command, $paragraph, $line_num) = @_;
    ## Interpret the command and its text; sample actions might be:
    $self->{line_number} = $line_num;
    $paragraph =~ s/\s*$//;
    $paragraph =~ s/^\s*//;
    
    if ($self->{in_verbatim}) {
	$self->parent->end_element(_element('verbatim', 1));
	$self->parent->characters({Data => "\n"});
	$self->{in_verbatim} = 0;
    }
    
    if ($command eq 'over') {
	$self->{in_list}++;
	$self->{open_lists}++;
	my $indent = ($paragraph ? $paragraph + 0 : 4);
	$self->{indent} = $indent;
	return;
    }
    elsif ($command eq 'back') {
	if ($self->{in_list}) {
	    $self->close_list();
	}
	else {
	    throw XML::SAX::Exception::Parse ( 
					      Message => "=back without =over",
					      LineNumber => $self->{line_number},
					      ColumnNumber => 0,
					      );
	}
	return;
    }
    elsif ($command eq 'item') {
	if (!$self->{in_list}) {
	    throw XML::SAX::Exception::Parse (
					      Message => "=item without =over",
					      LineNumber => $self->{line_number},
					      ColumnNumber => 0,
					      );
	}
	if ($self->{open_lists}) {
	    # determine list type, and open list tag
	    my $list_type = 'itemizedlist';
	    $paragraph =~ s|^\s* \*  \s*||x and $list_type = 'itemizedlist';
	    $paragraph =~ s|^\s* \d+\.? \s*||x and $list_type = 'orderedlist';
	    $self->open_list($list_type);
	}
	else {
	    if ($self->{list_type}[$self->{in_list}] eq 'itemizedlist') {
		$paragraph =~ s|^\s* \*  \s*||x;
	    }
	    elsif ($self->{list_type}[$self->{in_list}] eq 'orderedlist') {
		$paragraph =~ s|^\s* \d+\.? \s*||x;
	    }
	    
	    if ($self->{in_item}) {
		# close the last one
		$self->parent->end_element(_element('listitem', 1));
		$self->parent->characters({Data => "\n"});
		$self->{in_item}--;
	    }
	}
	
	$self->parent->characters({Data => " ".(" " x $self->{in_list})});
	
	$self->parent->start_element(_element('listitem'));
	if ($paragraph) {
	    $self->parse_text({ -expand_ptree => 'expand_ptree' }, $paragraph, $line_num);
	    $self->parent->characters({Data => "\n"});
	}
	$self->{in_item}++;
	return;
    }
    elsif ($command eq 'begin' || $command eq 'for') {
	if ($self->{open_lists}) {
	    # non =item command while in =over section - must be indented
	    my $list_type = 'indent';
	    $self->open_list($list_type);
	}
	
	my $el = _element('markup');
	$paragraph =~ s/^(\S*)\s*//;
	my $type = $1;
	my $process_paragraphs = 0;
	if ($type =~ /^:(.*)$/) {
	    $process_paragraphs = 1;
	    $type = $1;
	}
	_add_attrib($el, type => $type);
	_add_attrib($el, ordinary_paragraph => $process_paragraphs);
	$self->parent->start_element($el);
	if ($process_paragraphs) {
	    $self->parse_text({ -expand_ptree => 'expand_ptree' }, $paragraph, $line_num);
	}
	else {
	    $self->parent->characters({Data => $paragraph});
	}
	$self->parent->end_element(_element('markup', 1)) if $command eq 'for';
	$self->{in_begin_section} = 1 if $command eq 'begin';
	return;
    }
    elsif ($command eq 'end') {
	if ($self->{open_lists}) {
	    # non =item command while in =over section - must be indented
	    my $list_type = 'indent';
	    $self->open_list($list_type);
	}
	
	if ($self->{in_begin_section}) {
	    $self->parent->end_element(_element('markup'));
	    $self->{in_begin_section} = 0;
	}
	else {
	    throw XML::SAX::Exception::Parse (
					      Message => "=end without =begin",
					      LineNumber => $self->{line_number},
					      ColumnNumber => 0,
					      );
	}
	return;
    }
    elsif ($self->{in_list}) {
	throw XML::SAX::Exception::Parse (
					  Message => "=$command inside =over/=end block is not allowed",
					  LineNumber => $self->{line_number},
					  ColumnNumber => 0,
					  );
    }
    
    if ($command eq 'pod') {
	return;
    }
    
    $self->parent->start_element(_element($command));
    $self->parse_text({ -expand_ptree => 'expand_ptree' }, $paragraph, $line_num);
    $self->parent->end_element(_element($command, 1));
    $self->parent->characters({Data => "\n"});
}

sub verbatim { 
    my ($self, $paragraph, $line_num) = @_;
    $self->{line_number} = $line_num;
    
    my $text = $paragraph;
    $text =~ s/\n\z//;
    
    if ($self->{open_lists}) {
	# non =item command while in =over section - must be indented
	$self->open_list('indent');
    }
    
    return unless $paragraph =~ /\S/;
    
    my $last_verbatim = 0;
    if ($text =~ /\n\z/) {
	$last_verbatim = 1;
    }
    
    $self->parent->start_element(_element('verbatim')) unless $self->{in_verbatim};
    $self->parent->characters({Data => "\n\n"}) if $self->{in_verbatim};
    $self->{in_verbatim} = 1;
    
    if ($paragraph =~ /^(\s+)/) {
        # get all indents
        my @indents = ($paragraph =~ m/^([ \t]+)/mg);
        # and take the shortest one
        my $indent = (
          sort { length($a) <=> length($b) } 
          map { s/\t/        /g; $_ } # expand tabs
          @indents)[0];

        $paragraph =~ s/\s*$//;
        return unless length $paragraph;
        # warn("stripping: '$indent'\n");
        $paragraph =~ s/^$indent//mg; # un-indent
	$self->parent->characters({Data => $paragraph});
    }
    
    if ($last_verbatim) {
	$self->parent->end_element(_element('verbatim', 1));
	$self->parent->characters({Data => "\n"});
	$self->{in_verbatim} = 0;
    }
}

sub textblock { 
    my ($self, $paragraph, $line_num) = @_;
    $self->{line_number} = $line_num;

    if ($self->{open_lists}) {
	# non =item command while in =over section - must be indented
	my $list_type = 'indent';
	$self->{list_type}[$self->{in_list}] = $list_type;
	$self->parent->characters({Data => (" " x $self->{in_list})});
	my $el = _element($list_type);
	_add_attrib($el, indent_width => $self->{indent});
	$self->parent->start_element($el);
	$self->parent->characters({Data => "\n"});
	$self->{open_lists}--;
    }
    if ($self->{in_verbatim}) {
	$self->parent->end_element(_element('verbatim', 1));
	$self->parent->characters({Data => "\n"});
	$self->{in_verbatim} = 0;
    }
	
    
    $paragraph =~ s/^\s*//;
    $paragraph =~ s/\s*$//;
    
    $self->parent->start_element(_element('para'));
    $self->parse_text({ -expand_ptree => 'expand_ptree' }, $paragraph, $line_num);
    $self->parent->end_element(_element('para', 1));
    $self->parent->characters({Data => "\n"});
}

sub expand_ptree {
    my ($self, $ptree) = @_;
    foreach my $node ($ptree->children) {
	# warn("Expand_ptree($node)\n");
	if (ref($node)) {
	    $self->expand_seq($node);
	}
	else {
	    $self->parent->characters({Data => $node});
	}
    }
}

# Copied from Pod::Tree::Node
sub SplitTarget
{
    my $text = shift;
    my($page, $section);
    
    if ($text =~ /^"(.*)"$/s)     # L<"sec">;
    {
	$page    = '';
	$section = $1;
    }
    else                          # all other cases
    {
	($page, $section) = split m(/), $text, 2;
	
	# to quiet -w
	defined $page    or $page    = '';
	defined $section or $section = '';
	
	$page    =~ s/\s*\(\d\)$//;    # ls (1) -> ls
	$section =~ s( ^" | "$ )()xg;  # lose the quotes
	
	# L<section in this man page> (without quotes)
	if ($page !~ /^[\w.-]+(::[\w.-]+)*$/ and $section eq '')
	{
	    $section = $page;
	    $page = '';
	}
    }
    
    $section =~ s(   \s*\n\s*   )( )xg;  # close line breaks
    $section =~ s( ^\s+ | \s+$  )()xg;   # clip leading and trailing WS
    
    ($page, $section)
}

sub expand_seq {
    my ($self, $sequence) = @_;
    
    my $name = $sequence->cmd_name;
    my ($filename, $line_number) = $sequence->file_line();
    $self->{line_number} = $line_number;
    
    # warn("seq $name\n");
    
    if ($name eq 'L') {
	# link
	
	my $link = $sequence->raw_text;
	$link =~ s/^L<(.*)>$/$1/;
        $link =~ s/^<+\s(.*)\s>+$/$1/;
	my ($text, $inferred, $name, $section, $type) = $self->parselink($link);
	$text = '' unless defined $text;
	$inferred = '' unless defined $inferred;
	$name = '' unless defined $name;
	$section = '' unless defined $section;
	$type = '' unless defined $type;

	# warn("Link L<$link> parsed into: '$text', '$inferred', '$name', '$section', '$type'\n");
	
	if ($type eq 'url') {
	    my $start = _element("xlink");
	    _add_attrib($start, href => $name);
	    
	    $self->parent->start_element($start);
	    $self->parse_text({ -expand_ptree => 'expand_ptree' }, $inferred, $line_number);
	    $self->parent->end_element(_element('xlink', 1));
	}
	else {
	    my $start = _element("link");
	    _add_attrib($start, page => $name);
	    _add_attrib($start, section => $section);
	    _add_attrib($start, type => $type);
	    
	    $self->parent->start_element($start);
            $self->parse_text({ -expand_ptree => 'expand_ptree' }, $inferred, $line_number);
	    $self->parent->end_element(_element('link', 1));
	}
    }
    elsif ($name eq 'E') {
	my $text = join('', $sequence->parse_tree->children);
	my $char;
	if ($text =~ /^\d+$/) {
	    $char = chr($text);
	}
	else {
	    $char = $HTML_Escapes{$text};
	}
        # warn("doing E<$text> = $char\n");
	    
	$self->parent->characters({Data => $char});
    }
    elsif ($name eq 'S') {
	my $spaces = join('', $sequence->parse_tree->children);
	$self->parent->characters({Data => "\160" x length($spaces)});
    }
    else {
	$self->parent->start_element(_element($name));
	$self->expand_ptree($sequence->parse_tree);
	$self->parent->end_element(_element($name, 1));
    }
}

sub expand_text {
    my ($self, $text, $ptree_node) = @_;
    $self->parent->characters({Data => $text});
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} =
      {
	  Name => $name,
	    LocalName => $name,
	    Prefix => "",
	    NamespaceURI => "",
	    Value => $value,
      };
}

# Next three functions copied from Pod::ParseLink

# Parse the name and section portion of a link into a name and section.
sub _parse_section {
    my ($link) = @_;
    $link =~ s/^\s+//;
    $link =~ s/\s+$//;
    
    # If the whole link is enclosed in quotes, interpret it all as a section
    # even if it contains a slash.
    return (undef, $1) if ($link =~ /^"\s*(.*?)\s*"$/);
    
    # Split into page and section on slash, and then clean up quoting in the
    # section.  If there is no section and the name contains spaces, also
    # guess that it's an old section link.
    my ($page, $section) = split (/\s*\/\s*/, $link, 2);
    $section =~ s/^"\s*(.*?)\s*"$/$1/ if $section;
    if ($page && $page =~ / / && !defined ($section)) {
	$section = $page;
	$page = undef;
    } else {
	$page = undef unless $page;
	$section = undef unless $section;
    }
    return ($page, $section);
}

# Infer link text from the page and section.
sub _infer_text {
    my ($page, $section) = @_;
    my $inferred;
    if ($page && !$section) {
	$inferred = $page;
    } elsif (!$page && $section) {
	$inferred = '"' . $section . '"';
    } elsif ($page && $section) {
	$inferred = '"' . $section . '" in ' . $page;
    }
    return $inferred;
}

# Given the contents of an L<> formatting code, parse it into the link text,
# the possibly inferred link text, the name or URL, the section, and the type
# of link (pod, man, or url).
sub parselink {
    my ($self, $link) = @_;
    $link =~ s/\s+/ /g;
    # my $real_text = $self->parse_text({ -expand_ptree => 'expand_link' }, $link, 0);
    if ($link =~ /\A\w+:[^:\s]\S*\Z/) {
	return (undef, $link, $link, undef, 'url');
    }
    else {
	my $text;
	if ($link =~ /\|/) {
	    ($text, $link) = split (/\|/, $link, 2);
	}
        if ($link =~ /\A(\w+):[^:\s]\S*\Z/) {
            my $scheme = $1;
            die "Invalid URL scheme: $scheme" unless $scheme =~ /^(https?|ftp|mailto|news|nntp|snews)$/;
            return (undef, $text, $link, $text, 'url');
        }
	my ($name, $section) = _parse_section ($link);
	my $inferred = $text || _infer_text ($name, $section);
	my $type = ($name && $name =~ /\(\S*\)/) ? 'man' : 'pod';
	return ($text, $inferred, $name, $section, $type);
    }
}

# Unused right now...
sub expand_link {
    my ($self, $ptree) = @_;
    my $text = '';
    foreach my $node ($ptree->children) {
	# warn("Expand_ptree($node)\n");
	if (ref($node)) {
	    $self->expand_seq($node);
	}
	else {
	    $self->parent->characters({Data => $node});
	}
    }
}

package Pod::SAX::StringIO;

sub new {
    my $class = shift;
    my ($string) = @_;
    $string =~ s/\r//g;
    my @lines = split(/^/, $string);
    return bless \@lines, $class;
}

sub getline {
    my $self = shift;
    return shift @$self;
}

1;
__END__

=head1 NAME

Pod::SAX - a SAX parser for Pod

=head1 SYNOPSIS

  my $h = XML::SAX::Writer->new();
  my $p = Pod::SAX->new( Handler => $h );
  $p->parse_uri('perlpodspec.pod');

=head1 DESCRIPTION

Very simply, this module parses POD (or perl) files and turns the
Plain Old Documentation into SAX events (which often you'll use
to turn into XML, but there are other uses as well).

The aim of this module is not round-tripping, so some things may
be lost in the conversion. The aim is to be as standards compliant
as possible, while giving you very simple access to the data.

The main motivation for this module though was simple standards
compliance - all the Pod parsers out there seem to have their own
unique way of doing things, and so my aim was to unify that and
allow the flexibility that SAX gives me at the same time.

For an introduction to SAX, please read L<XML::SAX::Intro>.

One very important point to note is that just because this is a
SAX module it doesn't mandate that the results are XML. You could
just as easily use this module to extract all filenames from
a POD file, or extract custom =for/=begin sections. And because
it uses standardised interfaces this is a lot simpler than working
with any other POD parser out there, and the knowledge is
transferrable.

=head1 API

=head2 new()

To construct a parser simply call new(). It is customary to pass
in the handler object that will receive the SAX events at this time,
though you do not have to:

  my $parser = Pod::SAX->new(Handler => $h);

You can re-use this parser object multiple times. It's possible to change
the handler at a later date using C<$parser->set_handler()>. This and many
other API calls are documented in L<XML::SAX::Base>, which this module
inherits from.

=head2 parse()

This method is an auto-detecting parser - it will try and figure out
what you passed to it (a string, a file handle or a filename) and
parse the data using the appropriate technique.

=head2 parse_file(), parse_string(), parse_uri(), parse_fh()

These are simply the non-detecting methods that parse() uses internally.
Use these if you are paranoid about what you're parsing, and don't want
the overhead of SAX trying to guess.

=head1 XML Format

The XML format is intended to be simple and map fairly closely to the
source POD. The documentation here shows the POD marker and the
tag that it maps to.

=head2 =pod (or any other way to begin the document)

  <pod>
  <!-- Pod::SAX v0.14, using POD::Parser v1.13 -->

The comment is automatically generated so that you can see what version
of Pod::SAX was used in parsing this document. The closing C<< </pod> >>
tag is generated when the end of the POD is reached.

=head2 =head1 and =headN

  <head1>Text here</head1>

All head levels are supported.

=head2 Paragraphs

Plain paragraphs are represented with:

  <para>text</para>

=head2 Verbatim

Verbatim sections (i.e. when you indent the text) are represented with:

  <verbatim>text</verbatim>

=head2 =over/=back

Pod::SAX automatically detects whether a list is itemized or ordered (i.e.
whether it should have bullet points or numbers), and so =over/=back are
represented by:

  <itemizedlist>  </itemizedlist>

and

  <orderedlist>   </orderedlist>

respectively. The indent value (as in "=over 4") is saved in the
C<indent_width> attribute, although for most purposes this can be ignored.

=head2 =item

For both bulleted and numbered lists, the =item tag always maps to:

  <listitem>text</listitem>

If a paragraph follows an =item tag (and occurs before any =back) then
the paragraph is included immediately after the tag, so for example:

  =item foo
  
  Some text about foo

Maps to:

  <listitem>foo
    <para>Some text about foo</para>
  </listitem>

=head2 =begin foo

And "=for foo" (the two are semantically equivalent in Pod)

  <markup type="foo" ordinary_paragraph="0">text here</markup>

If the markup section is meant for ordinary processing (see
the perlpodspec section on "About Data Paragraphs and "=begin/=end"
Regions"), which means the type name begins with a colon as in:

  =begin :biblio

Then the markup produced indicates that using:

  <markup type="biblio" ordinary_paragraph="1"/>

And the parser will expand all interior Pod commands as it should.

B<Note>: There is I<no> special treatment of =begin html or
=begin XML or any variant thereof. The contents of those markers
will simply be treated as text, and it is up to the user of this
module to parse that data as XML if they wish to do so.

=head2 Sequences or Formatting Codes

Sequences in POD consist of the following:

  L<> - Links
  E<> - Entities
  I<> - Italics
  B<> - Bold
  C<> - Code
  F<> - Filename
  S<> - Non breaking space
  X<> - Index marker
  Z<> - Null

Most sequences are simply converted to tags of the same name, case
preserved:

  <B>This is bold text</B> and also <I>some in italics</I>.

Special treatment is given to the LE<lt>> EE<lt>> and SE<lt>> tags
only.

=head3 Links

Links in Pod are... funky.

Parsing links is really hard, so don't expect that I've got this right.
Basically though you've got this mapping:

  L<foo/bar>
   => <link type="pod" page="foo" section="bar">foo</link>
  
  L<Some Foo|foo>
   => <link type="pod" page="foo" section="">Some Foo</link>
  
  L<select(3)>
   => <link type="man" page="select(3)" section="">select(3)</link>
  
  L<http://foo.com>
   => <xlink href="http://foo.com">http://foo.com</xlink>

And many variations thereof! Basically it should do the right thing

=head3 Entities

In POD an EE<lt>> marker defines an entity. In pod these are single
characters only, and take either a text form, in which case they map
to the standard HTML entities (e.g. ouml, Agrave etc), or a decimal
number in which case they map to the unicode character at that code
point.

In Pod::SAX entities are always converted to unicode and never generate
any tags or markers in the data stream so it will be as though the
entity was never there.

=head3 Non-Breaking Space

Non breaking space is simply achieved by changing all space within
the SE<lt>> section into the unicode codepoint 160 - the non-breaking
space character. Normally this is enough to do the right thing, but
if you need to you can detect this with a regexp.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org. Copyright AxKit.com Ltd 2002

=head1 BUGS

There may be bugs in the unicode handling on perl 5.8, because it's
just really hard to get things right on 5.8 when dealing with
unicode. :-)

=head1 LICENSE

This is free software. You may use it and redistribute it under the same
terms as Perl itself.

=cut
