package Pod::Tree::HTML;
use strict;
use warnings;

# Copyright (c) 1999-2007 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

use HTML::Stream;
use IO::File;
use IO::String;
use Pod::Tree;
use Text::Template;

use Pod::Tree::BitBucket;
use Pod::Tree::StrStream;
use Pod::Tree::HTML::LinkMap;

use constant BGCOLOR => '#ffffff';
use constant TEXT    => '#000000';

our $VERSION = '1.25';

sub new {
	my ( $class, $source, $dest, %options ) = @_;
	defined $dest or die "Pod::Tree::HTML::new: not enough arguments\n";

	my $tree = _resolve_source($source);
	my ( $fh, $stream ) = _resolve_dest( $dest, $tree, \%options );

	my $options = {
		bgcolor  => BGCOLOR,
		depth    => 0,
		hr       => 1,
		link_map => Pod::Tree::HTML::LinkMap->new(),
		text     => TEXT,
		toc      => 1,
	};

	my $HTML = {
		tree        => $tree,
		root        => $tree->get_root,
		stream      => $stream,
		fh          => $fh,
		text_method => 'text',
		options     => $options,
	};

	bless $HTML, $class;

	$HTML->set_options(%options);
	$HTML;
}

sub _resolve_source {
	my $source = shift;
	my $ref    = ref $source;
	local *isa = \&UNIVERSAL::isa;

	isa( $source, 'Pod::Tree' ) and return $source;

	my $tree = Pod::Tree->new;
	not $ref and $tree->load_file($source);
	isa( $source, 'IO::File' ) and $tree->load_fh($source);
	$ref eq 'SCALAR' and $tree->load_string($$source);
	$ref eq 'ARRAY'  and $tree->load_paragraphs($source);

	$tree->loaded
		or die "Pod::Tree::HTML::_resolve_source: Can't load POD from $source\n";

	$tree;
}

sub _resolve_dest {
	my ( $dest, $tree, $options ) = @_;

	$tree->has_pod
		or $options->{empty}
		or return ( undef, Pod::Tree::BitBucket->new );

	local *isa = \&UNIVERSAL::isa;
	local *can = \&UNIVERSAL::can;

	isa( $dest, 'HTML::Stream' ) and return ( undef, $dest );
	isa( $dest, 'IO::File' )     and return ( $dest, HTML::Stream->new($dest) );
	can( $dest, 'print' ) and return ( $dest, HTML::Stream->new($dest) );

	if ( ref $dest eq 'SCALAR' ) {
		my $fh = IO::String->new($$dest);
		return ( $fh, HTML::Stream->new($fh) );
	}

	if ( ref $dest eq '' and $dest ) {
		my $fh = IO::File->new;
		$fh->open( $dest, '>' ) or die "Pod::Tree::HTML::new: Can't open $dest: $!\n";
		return ( $fh, HTML::Stream->new($fh) );
	}

	die "Pod::Tree::HTML::_resolve_dest: Can't write HTML to $dest\n";
}

sub set_options {
	my ( $html, %options ) = @_;

	my ( $key, $value );
	while ( ( $key, $value ) = each %options ) {
		$html->{options}{$key} = $value;
	}
}

sub get_options {
	my ( $html, @options ) = @_;

	map { $html->{options}{$_} } @options;
}

sub get_stream { shift->{stream} }

sub translate {
	my ( $html, $template ) = @_;

	if ($template) {
		$html->_template($template);
	}
	else {
		$html->_translate;
	}
}

sub _translate {
	my $html    = shift;
	my $stream  = $html->{stream};
	my $bgcolor = $html->{options}{bgcolor};
	my $text    = $html->{options}{text};
	my $title   = $html->_make_title;
	my $base    = $html->{options}{base};
	my $css     = $html->{options}{css};

	$stream->HTML->HEAD;

	defined $title and $stream->TITLE->text($title)->_TITLE;
	defined $base  and $stream->BASE( href => $base );
	defined $css   and $stream->LINK(
		href => $css,
		type => "text/css",
		rel  => "stylesheet"
	);

	$stream->_HEAD->BODY( BGCOLOR => $bgcolor, TEXT => $text );

	$html->emit_toc;
	$html->emit_body;

	$stream->nl->_BODY->_HTML;
}

sub _template {
	my ( $html, $tSource ) = @_;

	my $fh      = $html->{fh};
	my $sStream = Pod::Tree::StrStream->new;
	$html->{stream} = HTML::Stream->new($sStream);

	our $bgcolor = $html->{options}{bgcolor};
	our $text    = $html->{options}{text};
	our $title   = $html->_make_title;
	our $base    = $html->{options}{base};
	our $css     = $html->{options}{css};

	$html->emit_toc;
	our $toc = $sStream->get;

	$html->emit_body;
	our $body = $sStream->get;

	my $template = Text::Template->new( SOURCE => $tSource )
		or die "Can't create Text::Template object: $Text::Template::ERROR\n";

	$template->fill_in( OUTPUT => $fh )
		or die $Text::Template::ERROR;
}

sub _make_title {
	my $html = shift;

	my $title = $html->{options}{title};
	defined $title and return $title;

	my $children = $html->{root}->get_children;
	my $node1;
	my $i = 0;
	for my $child (@$children) {
		is_pod $child or next;
		$i++ and $node1 = $child;
		$node1 and last;
	}

	$node1 or return undef;    ##no critic (ProhibitExplicitReturnUndef)

	my $text = $node1->get_deep_text;
	($title) = split m(\s+-), $text;

	$title or return undef;    ##no critic (ProhibitExplicitReturnUndef)
	$title =~ s(\s+$)();

	$title;
}

sub emit_toc {
	my $html = shift;
	$html->{options}{toc} or return;

	my $root  = $html->{root};
	my $nodes = $root->get_children;
	my @nodes = @$nodes;

	$html->_emit_toc_1( \@nodes );

	$html->{options}{hr} > 0 and $html->{stream}->HR;
}

sub _emit_toc_1 {
	my ( $html, $nodes ) = @_;
	my $stream = $html->{stream};

	$stream->UL;

	while (@$nodes) {
		my $node = $nodes->[0];
		is_c_head2 $node and $html->_emit_toc_2($nodes), next;
		is_c_head1 $node and $html->_emit_toc_item($node);
		shift @$nodes;
	}

	$stream->_UL;
}

sub _emit_toc_2 {
	my ( $html, $nodes ) = @_;
	my $stream = $html->{stream};

	$stream->UL;

	while (@$nodes) {
		my $node = $nodes->[0];
		is_c_head1 $node and last;
		is_c_head2 $node and $html->_emit_toc_item($node);
		shift @$nodes;
	}

	$stream->_UL;
}

sub _emit_toc_item {
	my ( $html, $node ) = @_;
	my $stream = $html->{stream};
	my $target = $html->_make_anchor($node);

	$stream->LI->A( HREF => "#$target" );
	$html->_emit_children($node);
	$stream->_A;
}

sub emit_body {
	my $html = shift;
	my $root = $html->{root};
	$html->_emit_children($root);
}

sub _emit_children {
	my ( $html, $node ) = @_;

	my $children = $node->get_children;

	for my $child (@$children) {
		$html->_emit_node($child);
	}
}

sub _emit_siblings {
	my ( $html, $node ) = @_;

	my $siblings = $node->get_siblings;

	if ( @$siblings == 1 and $siblings->[0]{type} eq 'ordinary' ) {

		# don't put <p></p> around a single ordinary paragraph
		$html->_emit_children( $siblings->[0] );
	}
	else {
		for my $sibling (@$siblings) {
			$html->_emit_node($sibling);
		}
	}

}

sub _emit_node {
	my ( $html, $node ) = @_;
	my $type = $node->{type};

	for ($type) {
		/command/  and $html->_emit_command($node);
		/for/      and $html->_emit_for($node);
		/item/     and $html->_emit_item($node);
		/list/     and $html->_emit_list($node);
		/ordinary/ and $html->_emit_ordinary($node);
		/sequence/ and $html->_emit_sequence($node);
		/text/     and $html->_emit_text($node);
		/verbatim/ and $html->_emit_verbatim($node);
	}
}

my %HeadTag = (
	head1 => { 'open' => 'H1', 'close' => '_H1', level => 1 },
	head2 => { 'open' => 'H2', 'close' => '_H2', level => 2 },
	head3 => { 'open' => 'H3', 'close' => '_H3', level => 3 },
	head4 => { 'open' => 'H4', 'close' => '_H4', level => 4 }
);

sub _emit_command {
	my ( $html, $node ) = @_;
	my $stream   = $html->{stream};
	my $command  = $node->get_command;
	my $head_tag = $HeadTag{$command};
	$head_tag or return;
	my $anchor = $html->_make_anchor($node);

	$html->_emit_hr( $head_tag->{level} );

	my $tag;
	$tag = $head_tag->{'open'};
	$stream->$tag()->A( NAME => $anchor );

	$html->_emit_children($node);

	$tag = $head_tag->{'close'};
	$stream->_A->$tag();
}

sub _emit_hr {
	my ( $html, $level ) = @_;
	$html->{options}{hr} > $level or return;
	$html->{skip_first}++ or return;
	$html->{stream}->HR;
}

sub _emit_for {
	my ( $html, $node ) = @_;

	my $interpreter = lc $node->get_arg;
	my $emit        = "_emit_for_$interpreter";

	$html->$emit($node) if $html->can($emit);
}

sub _emit_for_html {
	my ( $html, $node ) = @_;

	my $stream = $html->{stream};
	$stream->P;
	$stream->io->print( $node->get_text );
	$stream->_P;
}

sub _emit_for_image {
	my ( $html, $node ) = @_;

	my $stream = $html->{stream};
	my $link   = $node->get_text;
	$link =~ s(\s+$)();

	$stream->IMG( src => $link );
}

sub _emit_item {
	my ( $html, $node ) = @_;

	my $stream    = $html->{stream};
	my $item_type = $node->get_item_type;
	for ($item_type) {
		/bullet/ and do {
			$stream->LI();
			$html->_emit_siblings($node);
			$stream->_LI();
		};

		/number/ and do {
			$stream->LI();
			$html->_emit_siblings($node);
			$stream->_LI();
		};

		/text/ and do {
			my $anchor = $html->_make_anchor($node);
			$stream->DT->A( NAME => "$anchor" );
			$html->_emit_children($node);
			$stream->_A->_DT->DD;
			$html->_emit_siblings($node);
			$stream->_DD;
		};
	}

}

my %ListTag = (
	bullet => { 'open' => 'UL', 'close' => '_UL' },
	number => { 'open' => 'OL', 'close' => '_OL' },
	text   => { 'open' => 'DL', 'close' => '_DL' }
);

sub _emit_list {
	my ( $html, $node ) = @_;
	my ( $list_tag, $tag );    # to quiet -w, see beloew

	my $stream    = $html->{stream};
	my $list_type = $node->get_list_type;

	$list_type and $list_tag = $ListTag{$list_type};
	$list_tag  and $tag      = $list_tag->{'open'};
	$tag       and $stream->$tag();

	$html->_emit_children($node);

	$list_tag and $tag = $list_tag->{'close'};
	$tag and $stream->$tag();
}

sub _emit_ordinary {
	my ( $html, $node ) = @_;
	my $stream = $html->{stream};

	$stream->P;
	$html->_emit_children($node);
	$stream->_P;
}

sub _emit_sequence {
	my ( $html, $node ) = @_;

	for ( $node->get_letter ) {
		/I|B|C|F/ and $html->_emit_element($node), last;
		/S/       and $html->_emit_nbsp($node),    last;
		/L/       and $html->_emit_link($node),    last;
		/X/       and $html->_emit_index($node),   last;
		/E/       and $html->_emit_entity($node),  last;
	}
}

my %ElementTag = (
	I => { 'open' => 'I',    'close' => '_I' },
	B => { 'open' => 'B',    'close' => '_B' },
	C => { 'open' => 'CODE', 'close' => '_CODE' },
	F => { 'open' => 'I',    'close' => '_I' }
);

sub _emit_element {
	my ( $html, $node ) = @_;

	my $letter = $node->get_letter;
	my $stream = $html->{stream};

	my $tag;
	$tag = $ElementTag{$letter}{'open'};
	$stream->$tag();
	$html->_emit_children($node);
	$tag = $ElementTag{$letter}{'close'};
	$stream->$tag();
}

sub _emit_nbsp {
	my ( $html, $node ) = @_;

	my $old_method = $html->{text_method};
	$html->{text_method} = 'text_nbsp';
	$html->_emit_children($node);
	$html->{text_method} = $old_method;
}

sub _emit_link {
	my ( $html, $node ) = @_;

	my $stream = $html->{stream};
	my $target = $node->get_target;
	my $domain = $target->get_domain;
	my $method = "make_${domain}_URL";
	my $url    = $html->$method($target);

	$stream->A( HREF => $url );
	$html->_emit_children($node);
	$stream->_A;
}

sub make_POD_URL {
	my ( $html, $target ) = @_;

	my $link_map = $html->{options}{link_map};

	return $link_map->url( $html, $target ) if $link_map->can("url");

	$html->make_mapped_URL($target);
}

sub make_mapped_URL {
	my ( $html, $target ) = @_;

	my $link_map = $html->{options}{link_map};
	my $base     = $html->{options}{base} || '';
	my $page     = $target->get_page;
	my $section  = $target->get_section;
	my $depth    = $html->{options}{depth};

	( $base, $page, $section ) = $link_map->map( $base, $page, $section, $depth );

	$base =~ s(/$)();
	$page .= '.html' if $page;
	my $fragment = $html->escape_2396($section);
	my $url = $html->assemble_url( $base, $page, $fragment );

	$url;
}

sub make_HTTP_URL {
	my ( $html, $target ) = @_;

	$target->get_page;
}

sub _emit_index {
	my ( $html, $node ) = @_;

	my $stream = $html->{stream};
	my $anchor = $html->_make_anchor($node);
	$stream->A( NAME => $anchor )->_A;
}

sub _emit_entity {
	my ( $html, $node ) = @_;

	my $stream = $html->{stream};
	my $entity = $node->get_deep_text;
	$stream->ent($entity);
}

sub _emit_text {
	my ( $html, $node ) = @_;
	my $stream      = $html->{stream};
	my $text        = $node->get_text;
	my $text_method = $html->{text_method};

	$stream->$text_method($text);
}

sub _emit_verbatim {
	my ( $html, $node ) = @_;
	my $stream = $html->{stream};
	my $text   = $node->get_text;
	$text =~ s(\n\n$)();

	$stream->PRE->text($text)->_PRE;
}

sub _make_anchor {
	my ( $html, $node ) = @_;
	my $text = $node->get_deep_text;
	$text =~ s(   \s*\n\s*/  )( )xg;    # close line breaks
	$text =~ s( ^\s+ | \s+$  )()xg;     # clip leading and trailing WS
	$html->escape_2396($text);
}

sub bin { oct '0b' . join '', @_ }

my @LinkFormat = (
	sub { my ( $b, $p, $f ) = @_; "" },
	sub { my ( $b, $p, $f ) = @_; "#$f" },
	sub { my ( $b, $p, $f ) = @_; "$p" },
	sub { my ( $b, $p, $f ) = @_; "$p#$f" },
	sub { my ( $b, $p, $f ) = @_; "$b/" },
	sub { my ( $b, $p, $f ) = @_; "#$f" },
	sub { my ( $b, $p, $f ) = @_; "$b/$p" },
	sub { my ( $b, $p, $f ) = @_; "$b/$p#$f" }
);

sub assemble_url {
	my ( $html, $base, $page, $fragment ) = @_;

	my $i = bin map { length($_) ? 1 : 0 } ( $base, $page, $fragment );
	my $url = $LinkFormat[$i]( $base, $page, $fragment );

	$url;
}

sub escape_2396 {
	my ( $html, $text ) = @_;
	$text =~ s(([^\w\-.!~*'()]))(sprintf("%%%02x", ord($1)))eg;
	$text;
}

__END__

=head1 NAME

Pod::Tree::HTML - Generate HTML from a Pod::Tree

=head1 SYNOPSIS

  use Pod::Tree::HTML;
  
  $source   =   Pod::Tree->new(%options);
  $source   =  "file.pod";
  $source   =   IO::File->new;
  $source   = \$pod;
  $source   = \@pod;
  
  $dest     =   HTML::Stream->new;
  $dest     =   IO::File->new;
  $dest     =  "file.html";
  
  $html     =   Pod::Tree::HTML->new($source, $dest, %options);
  
              $html->set_options(%options);
  @values   = $html->get_options(@keys);
  
              $html->translate;
              $html->translate($template);
              $html->emit_toc;
              $html->emit_body;
  
  $fragment = $html->escape_2396 ($section);
  $url      = $html->assemble_url($base, $page, $fragment);


=head1 REQUIRES

C<HTML::Stream>, C<Text::Template>


=head1 DESCRIPTION

C<Pod::Tree::HTML> reads a POD and translates it to HTML.
The source and destination are fixed when the object is created.
Options are provided for controlling details of the translation.

The C<translate> method does the actual translation.

For convenience, 
C<Pod::Tree::HTML> can read PODs from a variety of sources,
and write HTML to a variety of destinations.
The C<new> method resolves the I<$source> and I<$dest> arguments.

C<Pod::Tree::HTML> can also use C<Text::Template> to fill in an HTML
template file.


=head2 Source resolution

C<Pod::Tree::HTML> can obtain a POD from any of 5 sources.
C<new> resolves I<$source> by checking these things,
in order:

=over 4

=item 1

If I<$source> C<isa> C<POD::Tree>, 
then the POD is taken from that tree.

=item 2

If I<$source> is not a reference, 
then it is taken to be the name of a file containing a POD.

=item 3

If I<$source> C<isa> C<IO::File>, 
then it is taken to be an C<IO::File> object that is already
open on a file containing a POD.

=item 4

If I<$source> is a SCALAR reference,
then the text of the POD is taken from that scalar.

=item 5

if I<$source> is an ARRAY reference,
then the paragraphs of the POD are taken from that array.

=back

If I<$source> isn't any of these things,
C<new> C<die>s.
 

=head2 Destination resolution

C<Pod::Tree::HTML> can write HTML to any of 5 destinations.
C<new> resolves I<$dest> by checking these things,
in order:

=over 4

=item 1

If I<$dest> C<isa> C<HTML::Stream>,
then C<Pod::Tree::HTML> writes HTML to that stream.

=item 2

If I<$dest> C<isa> C<IO::File>,
then C<Pod::Tree::HTML> writes HTML to that file.

=item 3

If I<$dest> has a C<print> method,
then C<Pod::Tree::HTML> passes HTML to that method.

=item 4

If I<$dest> is a SCALAR reference,
then C<Pod::Tree::HTML> writes HTML to that scalar.

=item 5

If I<$dest> is a string,
then C<Pod::Tree::HTML> writes HTML to the file with that name.

=back

If I<$dest> isn't any of these things,
C<new> C<die>s.


=head1 METHODS

=over 4

=item I<$html> = C<new> C<Pod::Tree::HTML> I<$source>, I<$dest>, I<%options>

Creates a new C<Pod::Tree::HTML> object.

I<$html> reads a POD from I<$source>,
and writes HTML to I<$dest>.
See L</Source resolution> and L</Destination resolution> for details.

Options controlling the translation may be passed in the I<%options> hash.
See L</OPTIONS> for details.

=item I<$html>->C<set_options>(I<%options>)

Sets options controlling the translation.
See L</OPTIONS> for details.

=item I<@values> = I<$html>->C<get_options>(I<@keys>)

Returns the current values of the options specified in I<@keys>.
See L</OPTIONS> for details.

=item I<$html>->C<translate>

=item I<$html>->C<translate>(I<$template>)

Translates the POD to HTML.
This method should only be called once.

In the second form,
I<$template> is the name of a file containing a template.
The template will be filled in by the C<Text::Template> module.
Here is a minimal template,
showing example usage of all the variables that are set by C<Pod::Tree::HTML>.

  <html>
   <head>
    <base href="{$base}">
    <link href="{$css}" rel="stylesheet" type="text/css">
    <title>{$title}</title>
   </head>
   <body bgcolor="{$bgcolor}" text="{$text}">
    {$toc}
    {$body}
   </body>
  </html>

The program fragments in the template are evaulted in the C<Pod::Tree::HTML> package.
Any variables that you set in this package will be available to your template.

When a template is used, the destination must not be an C<HTML::Stream> object.

C<translate> doesn't return anything.
The first form always returns.
The second form C<die>s if there is an error creating or filling in the template.


=item I<$html>->C<emit_toc>

=item I<$html>->C<emit_body>

Emits the table of contents and body of the HTML document.

These methods are called automatically by C<translate>.
They are exposed in the API for applications that wish to embed the 
HTML inside a larger document.

=back

=head2 Utility methods

These methods are provided for implementors who write their own link
mapper objects.

=over 4

=item I<$fragment> = I<$html>->C<escape_2396>(I<$section>)

Escapes I<$section> according to RFC 2396. For example, the section

    some section

is returned as

    some%20section

=item I<$url> = I<$html>->C<assemble_url>(I<$base>, I<$page>, I<$fragment>)

Assembles I<$base>, I<$page>, and I<$fragment> into a URL, of the form

    $base/$page#$fragment

Attempts to construct a valid URL, even if some of I<$base>, I<$page>,
and I<$fragment> are empty.

=back


=head1 OPTIONS

=over 4

=item C<base> => I<$url>

Specifies a base URL for relative HTML links.


=item C<bgcolor> => I<#rrggbb>

Set the background color to I<#rrggbb>.
Default is white.


=item C<css> => I<$url>

Specifies a Cascading Style Sheet for the generated HTML page.


=item C<depth> => I<$depth>

Specifies the depth of the generated HTML page in a directory tree.
See L</LINK MAPPING> for details.


=item C<empty> => C<1>

Causes the C<translate> method to emit an HTML file, even if the POD is empty.
If this option is not provided, then no HTML file is created for empty PODs.


=item C<hr> => I<$level>

Controls the profusion of horizontal lines in the output, as follows:

    $level   horizontal lines
    0 	     none
    1 	     between TOC and body
    2 	     after each =head1
    3 	     after each =head1 and =head2

Default is level 1.


=item C<link_map> => I<$link_map>

Sets the link mapper. 
See L</LINK MAPPING> for details.


=item C<text> => I<#rrggbb>

Set the text color to I<#rrggbb>.
Default is black.


=item C<title> => I<title>

Set the page title to I<title>.
If no C<title> option is given, 
C<Pod::Tree::HTML> will attempt construct a title from the 
second paragrah of the POD.
This supports the following style:

    =head1 NAME
    
    ls - list contents of directory


=item C<toc> => [C<0>|C<1>]

Includes or omits the table of contents.
Default is to include the TOC.

=back


=head1 LINKS and TARGETS

C<Pod::Tree::HTML> automatically generates HTML destination anchors for
all =headI<n> command paragraphs,
and for text items in =over lists.
The text of the paragraph becomes the C<name> attribute of the anchor.
Markups are ignored and the text is escaped according to RFC 2396.

For example, the paragraph

	=head1 C<Foo> Bar

is translated to 

	<h1><a name="Foo%20Bar"><code>Foo</code> Bar</a></h1>

To link to a heading, 
simply give the text of the heading in an C<< LZ<><> >> markup.
The text must match exactly; 
markups may vary.
Either of these would link to the heading shown above

	L</C<Foo> Bar>
	L</Foo Bar>

To generate destination anchors in other places,
use the index (C<< XZ<><> >>) markup

	We can link to X<this text> this text.

and link to it as usual

	L</this text> uses the index markup.

Earlier versions of this module also emitted the content of the XZ<><>
markup as visible text. However, L<perlpod> now specifies that XZ<><>
markups render as an empty string, so C<Pod::Tree::HTML> has been
changed to do that.


=head1 LINK MAPPING

The POD specification provides the C<< LZ<><> >> markup to link from
one document to another. HTML provides anchors (C<< <a href=""></a> >>) 
for the same purpose. Obviously, a POD2HTML translator should
convert the first to the second.

In general, this is a hard problem.
In particular, the POD format is not powerful enough to support the kind
of hyper-linking that people want in a complex documentation system.

Rather than try to be all things to all people,
C<Pod::Tree::HTML> uses a I<link mapper> object to translate 
the target of a POD link to a URL.
The default link mapper does a simple translation, described below.
If you don't like the default translation,
you can provide your own link mapper
with the L<< C<link_map> => I<$link_map> >> option.


=head2 Default

The default link mapper obtains the I<page> and I<section> from the target.
It translates C<::> sequences in the I<page> to C</>,
and returns a URL of the form [C<../>...][I<page>C<.html>][C<#>I<section>]

If the L<< C<depth> => I<$depth> >> option is given,
a corresponding number of C<../> sequences are prepended to I<page>.

This is a relative URL, 
so it will be interpreted relative to the L<< C<base> => I<$base> >> option,
if any.


=head2 Custom

To use your own link mapper,
create a link mapper object and provide it to C<Pod::Tree::HTML>
with the C<link_map> option

    sub MyMapper::new { bless {}, shift }
    
    sub MyMapper::url
    {
        my($mapper, $html, $target) = @_;
        ...
	return $url;
    }
    
    $mapper = MyMapper->new;
    $html   = Pod::Tree::HTML->new(link_map => $mapper);

Your object should implement one method

=over 4

=item I<$url> = I<$mapper>->C<url>(I<$html>, I<$target>)

When I<$html>->C<translate>() encounters an C<< LZ<><> >> markup, 
it calls I<$mapper>->C<url>. 
I<$html> is the C<Pod::Tree::HTML> object itself.
I<$target> is a C<Pod::Tree::Node> object representing the 
the target of the link. 
See L<Pod::Tree::Node/target nodes> for information on interpreting I<$target>.

The C<url> method must return a string, 
which will be emitted as the value of the C<href> attribute of an HTML 
anchor: C<< <a href=" >>I<$url>C<< "> >>...C<< </a> >>

C<Pod:Tree:HTML> provides the C<escape_2396> and C<assemble_url>
methods for convenience in implementing link mappers.

=back

If the link mapper does not provide a C<url> method,
C<Pod::Tree::HTML> will call C<map> 

=over 4

=item (I<$base>, I<$page>, I<$section>) = I<$mapper>-E<gt>C<map>(I<$base>, I<$page>, I<$section>, I<$depth>);

Where

=over 4

=item I<$base>

is the URL given in the C<base> option.

=item I<$page>

is the man page named in the LE<lt>E<gt> markup.

=item I<$section>

is the man page section given in the LE<lt>E<gt> markup.

=item I<$depth>

is the value of the C<depth> option.

=back

The C<map> method may perform arbitrary mappings on its arguments.
C<Pod::Tree::HTML> takes the returned values and constructs a URL 
of the form [I<$base>/][I<$page>C<.html>][C<#>I<$fragment>]

=back

The C<map> method is 

=over 4

=item *

deprecated

=item *

less flexible than the C<url> method

=item *

supported for backwards compatability with 
older versions of C<Pod::Tree::HTML>

=back


=head1 DIAGNOSTICS

=over 4

=item C<Pod::Tree::HTML::new: not enough arguments>

(F) C<new> called with fewer than 2 arguments.

=item C<Pod::Tree::HTML::new: Can't load POD from $source>

(F) C<new> couldn't resolve the I<$source> argument.
See L</Source resolution> for details.

=item C<Pod::Tree::HTML::new: Can't write HTML to $dest>

(F) C<new> couldn't resolve the I<$dest> argument.
See L</Destination resolution> for details.

=item C<Pod::Tree::HTML::new: Can't open $dest: $!>

(F) The destination file couldn't be opened.

=back


=head1 SEE ALSO

perl(1), L<C<Pod::Tree>>, L<C<Pod::Tree::Node>>,  L<C<Text::Template>>


=head1 AUTHOR

Steven McDougall, swmcd@world.std.com


=head1 COPYRIGHT

Copyright (c) 1999-2009 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.
