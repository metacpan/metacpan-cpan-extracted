# Copyright (c) 1999-2004 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Pod::Tree::Node;

use 5.006;
use strict;
use warnings;
use Pod::Escapes ();

our $VERSION = '1.30';

sub root    # ctor
{
	my ( $class, $children ) = @_;

	my $node = {
		type     => 'root',
		children => $children
	};

	bless $node, $class;
}

sub code    #ctor
{
	my ( $class, $paragraph ) = @_;

	my $node = {
		type => 'code',
		text => $paragraph
	};

	bless $node, $class;
}

sub verbatim    # ctor
{
	my ( $class, $paragraph ) = @_;

	my $node = {
		type => 'verbatim',
		raw  => $paragraph,
		text => $paragraph
	};

	bless $node, $class;
}

my %Argumentative = map { $_ => 1 } qw(=over
	=for =begin =end);

sub command    # ctor
{
	my ( $class, $paragraph ) = @_;
	my ( $command, $arg, $text );

	($command) = split( /\s/, $paragraph );

	if ( $Argumentative{$command} ) {
		( $command, $arg, $text ) = split( /\s+/, $paragraph, 3 );
	}
	else {
		( $command, $text ) = split( /\s+/, $paragraph, 2 );
		$arg = '';
	}

	$command =~ s/^=//;

	my $node = {
		type    => 'command',
		raw     => $paragraph,
		command => $command,
		arg     => $arg,
		text    => $text
	};

	bless $node, $class;
}

sub ordinary    # ctor
{
	my ( $class, $paragraph ) = @_;

	my $node = {
		type => 'ordinary',
		raw  => $paragraph,
		text => $paragraph
	};

	bless $node, $class;
}

sub letter    # ctor
{
	my ( $class, $token ) = @_;

	my $node = {
		type => 'letter',
		letter => substr( $token, 0, 1 ),
		width  => $token =~ tr/</</
	};

	bless $node, $class;
}

sub sequence    # ctor
{
	my ( $class, $letter, $children ) = @_;

	my $node = {
		type     => 'sequence',
		'letter' => $letter->{'letter'},
		children => $children
	};

	bless $node, $class;
}

sub text    # ctor
{
	my ( $class, $text ) = @_;

	my $node = {
		type => 'text',
		text => $text
	};

	bless $node, $class;
}

sub target    # ctor
{
	my ( $class, $children ) = @_;

	my $node = bless {
		type     => 'target',
		children => $children
	}, $class;

	$node->unescape;
	my $text = $node->get_deep_text;

	if ( $text =~ m(^[A-Za-z]+:(?!:)) )    # a URL
	{
		$node->{page}    = $text;
		$node->{section} = '';
		$node->{domain}  = 'HTTP';
	}
	else                                   # a POD link
	{
		my ( $page, $section ) = SplitTarget($text);
		$node->{page}    = $page;
		$node->{section} = $section;
		$node->{domain}  = 'POD';
	}

	$node;
}

sub SplitTarget {
	my $text = shift;
	my ( $page, $section );

	if ( $text =~ /^"(.*)"$/s )    # L<"sec">;
	{
		$page    = '';
		$section = $1;
	}
	else                           # all other cases
	{
		( $page, $section ) = ( split( m(/), $text, 2 ), '', '' );

		$page =~ s/\s*\(\d\)$//;         # ls (1) -> ls
		$section =~ s( ^" | "$ )()xg;    # lose the quotes

		# L<section in this man page> (without quotes)
		if ( $page !~ /^[\w.-]+(::[\w.-]+)*$/ and $section eq '' ) {
			$section = $page;
			$page    = '';
		}
	}

	$section =~ s(   \s*\n\s*   )( )xg;    # close line breaks
	$section =~ s( ^\s+ | \s+$  )()xg;     # clip leading and trailing WS

	( $page, $section );
}

sub link                                   # ctor
{
	my ( $class, $node, $page, $section ) = @_;

	my $target = bless {
		type     => 'target',
		domain   => 'POD',
		children => [$node],
		page     => $page,
		section  => $section
	}, $class;

	my $link = bless {
		type     => 'sequence',
		letter   => 'L',
		children => [$node],
		target   => $target
	}, $class;

	$link;
}

sub is_code     { shift->{type} eq 'code' }
sub is_command  { shift->{type} eq 'command' }
sub is_for      { shift->{type} eq 'for' }
sub is_item     { shift->{type} eq 'item' }
sub is_letter   { shift->{type} eq 'letter' }
sub is_list     { shift->{type} eq 'list' }
sub is_ordinary { shift->{type} eq 'ordinary' }
sub is_root     { shift->{type} eq 'root' }
sub is_sequence { shift->{type} eq 'sequence' }
sub is_text     { shift->{type} eq 'text' }
sub is_verbatim { shift->{type} eq 'verbatim' }

sub is_link {
	my $node = shift;
	$node->is_sequence and $node->{'letter'} eq 'L';
}

sub is_pod {
	my $node = shift;
	not $node->is_code and not $node->is_c_cut and not $node->is_c_pod;
}

sub is_c_head1 {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'head1';
}

sub is_c_head2 {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'head2';
}

sub is_c_head3 {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'head3';
}

sub is_c_head4 {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'head4';
}

sub is_c_cut {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'cut';
}

sub is_c_pod {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'pod';
}

sub is_c_over {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'over';
}

sub is_c_back {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'back';
}

sub is_c_item {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'item';
}

sub is_c_for {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'for';
}

sub is_c_begin {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'begin';
}

sub is_c_end {
	my $node = shift;
	$node->{type} eq 'command' and $node->{'command'} eq 'end';
}

sub get_arg       { shift->{arg} }
sub get_back      { shift->{back} }
sub get_children  { shift->{children} }
sub get_command   { shift->{'command'} }
sub get_domain    { shift->{domain} }
sub get_item_type { shift->{item_type} }
sub get_letter    { shift->{'letter'} }
sub get_list_type { shift->{list_type} }
sub get_page      { shift->{page} }
sub get_raw       { shift->{raw} }
sub get_raw_kids  { shift->{raw_kids} }
sub get_section   { shift->{section} }
sub get_siblings  { shift->{siblings} }
sub get_target    { shift->{'target'} }
sub get_text      { shift->{'text'} }
sub get_type      { shift->{'type'} }
sub get_url       { shift->{'url'} }

sub get_brackets {
	my $node     = shift;
	my $brackets = $node->{brackets};
	$brackets;
}

sub get_deep_text {
	my $node = shift;

	for ( $node->get_type ) {
		/text/     and return $node->{'text'};
		/verbatim/ and return $node->{'text'};
	}

	join '', map { $_->get_deep_text } @{ $node->{children} };
}

sub force_text {
	my ( $node, $text ) = @_;
	$node->{type} = 'text';
	$node->{'text'} = $text;
	undef $node->{children};
}

sub force_for {
	my $node = shift;
	$node->{type} = 'for';

	my ($bracket) = $node->{raw} =~ /^(=\w+\s+\w+\s+)/;

	$node->{brackets} = [$bracket];
}

sub parse_begin {
	my ( $node, $nodes ) = @_;

	my $foreign;
	my @raw;
	while (@$nodes) {
		$foreign = shift @$nodes;
		$foreign->is_c_end and last;
		push @raw, $foreign->{'raw'};
	}
	$node->{'text'} = join '', @raw;

	my $interpreter = $foreign->{arg};
	$interpreter
		and $interpreter ne $node->{arg}
		and $node->_warn("Mismatched =begin/=end tags around\n$node->{'text'}");

	$node->{type} = 'for';
	$node->{brackets} = [ $node->{raw}, $foreign->{raw} ];
}

sub set_children {
	my ( $node, $children ) = @_;
	$node->{children} = $children;
}

sub make_sequences {
	my $node      = shift;
	my $text      = $node->{'text'};
	my @tokens    = split /( [A-Z]<<+\s+ | [A-Z]< | \s+>>+ | > )/x, $text;
	my $sequences = _parse_text( \@tokens );
	$node->{children} = $sequences;
}

sub _parse_text {
	my $tokens = shift;
	my ( @stack, @width );

	while (@$tokens) {
		my $token = shift @$tokens;
		length $token or next;

		$token =~ /^[A-Z]</ and do {
			my $width = $token =~ tr/</</;
			push @width, $width;
			my $node = Pod::Tree::Node->letter($token);
			push @stack, $node;
			next;
		};

		@width and $token =~ />{$width[-1],}$/ and do {
			my $width = pop @width;
			my ( $letter, $interior ) = _pop_sequence( \@stack, $width );
			my $node = Pod::Tree::Node->sequence( $letter, $interior );
			push @stack, $node;
			$token =~ s/^\s*>{$width}//;
			my @tokens = split //, $token;
			unshift @$tokens, @tokens;
			next;
		};

		my $node = Pod::Tree::Node->text($token);
		push @stack, $node;
	}

	if (@width) {
		my @text = map { $_->get_deep_text } @stack;
		Pod::Tree::Node->_warn("Missing '>' delimiter in\n@text");
	}

	\@stack;
}

sub _pop_sequence {
	my ( $stack, $width ) = @_;
	my ( $node, @interior );

	while (@$stack) {
		$node = pop @$stack;
		$node->is_letter
			and $node->{width} == $width
			and return ( $node, \@interior );
		unshift @interior, $node;
	}

	my @text = map { $_->get_deep_text } @interior;
	$node->_warn("Mismatched sequence delimiters around\n@text");

	$node = Pod::Tree::Node->letter(' ');
	$node, \@interior;
}

sub parse_links {
	my $node = shift;

	$node->is_link and $node->_parse_link;

	my $children = $node->{children};
	for my $child (@$children) {
		$child->parse_links;
	}
}

sub _parse_link {
	my $node = shift;

	$node->{raw_kids} = $node->clone->{children};

	my $children = $node->{children};
	my ( $text_kids, $target_kids ) = SplitBar($children);

	$node->{children} = $text_kids;
	$node->{'target'} = Pod::Tree::Node->target($target_kids);
}

sub SplitBar {
	my $children = shift;
	my ( @text, @link );

	while (@$children) {
		my $child = shift @$children;

		$child->is_text or do {
			push @text, $child;
			next;
		};

		my ( $text, $link ) = split m(\|), $child->{'text'}, 2;
		$link and do {
			push @text, Pod::Tree::Node->text($text) if $text;
			push @link, Pod::Tree::Node->text($link), @$children;
			return ( \@text, \@link );
		};

		push @text, $child;
	}

	( \@text, \@text );
}

sub unescape {
	my $node = shift;

	my $children = $node->{children};
	for my $child (@$children) {
		$child->unescape;
	}

	$node->is_sequence and $node->_unescape_sequence;
}

sub _unescape_sequence {
	my $node = shift;

	for ( $node->{'letter'} ) {
		/Z/ and $node->force_text(''), last;
		/E/ and do {
			my $child = $node->{children}[0];
			$child or last;
			my $text = $child->_unescape_text;
			$text and $node->force_text($text);
			last;
		};
	}
}

sub _unescape_text {
	my $node = shift;
	my $text = $node->{'text'};

	defined $text ? Pod::Escapes::e2char($text) : "E<UNDEF?!>";
}

sub consolidate {
	my $node = shift;
	my $old  = $node->{children};
	$old and @$old or return;

	my $new = [];

	push @$new, shift @$old;

	while (@$old) {
		if (   $new->[-1]->is_text and $old->[0]->is_text
			or $new->[-1]->is_verbatim and $old->[0]->is_verbatim
			or $new->[-1]->is_code and $old->[0]->is_code )
		{
			$new->[-1]{'text'} .= $old->[0]{'text'};
			shift @$old;
		}
		else {
			push @$new, shift @$old;
		}
	}

	$node->{children} = $new;

	for my $child (@$new) {
		$child->consolidate;
	}
}

sub make_lists {
	my $root  = shift;
	my $nodes = $root->{children};

	$root->_make_lists($nodes);
}

sub _make_lists {
	my ( $node, $old ) = @_;
	my $new = [];
	my $back;

	while (@$old) {
		my $child = shift @$old;
		$child->is_c_over and $child->_make_lists($old);
		$child->is_c_item and $child->_make_item($old);
		$child->is_c_back and $back = $child, last;
		push @$new, $child;
	}

	$node->{children} = $new;

	$node->is_root and return;

	$node->{type} = 'list';
	$node->{back} = $back;
	$node->_set_list_type;
}

sub _set_list_type {
	my $list     = shift;
	my $children = $list->{children};

	$list->{list_type} = '';    # -w

	for my $child (@$children) {
		$child->{type} eq 'item' or next;
		$list->{list_type} = $child->{item_type};
		last;
	}
}

sub _make_item {
	my ( $item, $old ) = @_;
	my $siblings = [];

	while (@$old) {
		my $sibling = $old->[0];
		$sibling->is_c_item and last;
		$sibling->is_c_back and last;

		shift @$old;
		$sibling->is_c_over and do {
			$sibling->_make_lists($old);
		};
		push @$siblings, $sibling;
	}

	$item->{type}     = 'item';
	$item->{siblings} = $siblings;
	$item->_set_item_type;
}

sub _set_item_type {
	my $item = shift;
	my $text = $item->{'text'};

	$text =~ m(^\s* \*  \s*$ )x and $item->{item_type} = 'bullet';
	$text =~ m(^\s* \d+ \s*$ )x and $item->{item_type} = 'number';
	$item->{item_type} or $item->{item_type} = 'text';
}

sub clone {
	my $node  = shift;
	my $clone = {%$node};

	my $children = $node->{children};
	$clone->{children} = [ map { $_->clone } @$children ];

	bless $clone, ref $node;
}

my $Indent;
my $String;

sub dump {
	my $node = shift;

	$Indent = 0;
	$String = '';
	$node->_dump;
	$String;
}

sub _dump {
	my $node = shift;
	my $type = $node->get_type;

	$String .= ' ' x $Indent . uc $type . " ";

	for ($type) {
		/command/  and $String .= $node->_dump_command;
		/code/     and $String .= $node->_dump_code;
		/for/      and $String .= $node->_dump_for;
		/item/     and $String .= $node->_dump_item;
		/list/     and $String .= $node->_dump_list;
		/ordinary/ and $String .= "\n";
		/root/     and $String .= "\n";
		/sequence/ and $String .= $node->_dump_sequence;
		/text/     and $String .= $node->_dump_text;
		/verbatim/ and $String .= $node->_dump_verbatim;
	}

	$node->_dump_children;
	$node->_dump_siblings;
}

sub _dump_command {
	my $node    = shift;
	my $command = $node->get_command;
	my $arg     = $node->get_arg;

	"$command $arg\n";
}

sub _dump_code {
	my $node = shift;

	my $text = _indent( $node->get_text, 3 );
	my $block = "\n{\n$text}\n";

	_indent( $block, $Indent );
}

sub _dump_for {
	my $node = shift;
	my $arg  = $node->get_arg;
	my $text = _indent( $node->get_text, $Indent + 3 );

	"$arg\n$text\n";
}

sub _dump_item {
	my $node = shift;
	uc $node->get_item_type . "\n";
}

sub _dump_list {
	my $node = shift;
	uc $node->get_list_type . "\n";
}

sub _dump_sequence {
	my $node   = shift;
	my $letter = $node->get_letter;
	my $link   = $node->is_link ? $node->_dump_target : '';

	"$letter$link\n";
}

sub _dump_text {
	my $node = shift;
	my $text = $node->get_text;

	$text =~ s/([\x80-\xff])/sprintf("\\x%02x", ord($1))/eg;

	my $indent = ' ' x ( $Indent + 5 );
	$text =~ s( (?<=\n) (?=.) )($indent)xg;
	"$text\n";
}

sub _dump_verbatim {
	my $node = shift;
	"\n" . $node->get_text . "\n";
}

sub _dump_target {
	my $node    = shift;
	my $target  = $node->get_target;
	my $page    = $target->{page};
	my $section = $target->{section};
	" $page / $section";
}

sub _dump_children {
	my $node     = shift;
	my $children = $node->get_children;
	$children and DumpList( $children, '{', '}' );
}

sub _dump_siblings {
	my $node     = shift;
	my $siblings = $node->get_siblings;
	$siblings and DumpList( $siblings, '[', ']' );
}

sub DumpList {
	my ( $nodes, $open, $close ) = @_;

	$String .= ' ' x $Indent . "$open\n";
	$Indent += 3;

	for my $node (@$nodes) {
		$node->_dump;
	}

	$Indent -= 3;
	$String .= ' ' x $Indent . "$close\n";
}

sub _indent {
	my ( $text, $spaces ) = @_;
	my $indent = ' ' x $spaces;
	$text =~ s( (?<=\n) (?=.) )($indent)xg;
	$indent . $text;
}

sub _warn {
	my ( $node, $message ) = @_;

	my $filename = $node->get_filename;
	my $tag = $filename ? "in $filename" : $filename;
	warn "$message $tag\n";
}

sub set_filename {
	my ( $package, $filename ) = @_;

	$Pod::Tree::Node::filename = $filename;
}

sub get_filename {
	$Pod::Tree::Node::filename;
}

1

__END__


=head1 NAME

Pod::Tree::Node - nodes in a Pod::Tree

=head1 SYNOPSIS

  $node = Pod::Tree::Node->root     ( \@paragraphs );
  $node = Pod::Tree::Node->code     ( $paragraph   );
  $node = Pod::Tree::Node->verbatim ( $paragraph   );
  $node = Pod::Tree::Node->command  ( $paragraph   );
  $node = Pod::Tree::Node->ordinary ( $paragraph   );
  $node = Pod::Tree::Node->letter   ( $token       );
  $node = Pod::Tree::Node->sequence ( $letter, \@children );
  $node = Pod::Tree::Node->text     ( $text        );
  $node = Pod::Tree::Node->target   ( $target      );
  $node = Pod::Tree::Node->link     ( $node, $page, $section );
  
  $node->is_code     and ...
  $node->is_command  and ...
  $node->is_for      and ...
  $node->is_item     and ...
  $node->is_letter   and ...
  $node->is_list     and ...
  $node->is_ordinary and ...
  $node->is_pod      and ...
  $node->is_root     and ...
  $node->is_sequence and ...
  $node->is_text     and ...
  $node->is_verbatim and ...
  $node->is_link     and ...
  
  $node->is_c_head1  and ...
  $node->is_c_head2  and ...
  $node->is_c_head3  and ...
  $node->is_c_head4  and ...
  $node->is_c_cut    and ...
  $node->is_c_pod    and ...
  $node->is_c_over   and ...
  $node->is_c_back   and ...
  $node->is_c_item   and ...
  $node->is_c_for    and ...
  $node->is_c_begin  and ...
  $node->is_c_end    and ...
  
  $arg       = $node->get_arg       ;
  $brackets  = $node->get_brackets  ;
  $children  = $node->get_children  ;
  $command   = $node->get_command   ;
  $domain    = $node->get_domain    ;
  $item_type = $node->get_item_type ;
  $letter    = $node->get_letter    ;
  $list_type = $node->get_list_type ;
  $page      = $node->get_page      ;
  $raw       = $node->get_raw       ;
  $raw_kids  = $node->get_raw_kids  ;
  $section   = $node->get_section   ;
  $siblings  = $node->get_siblings  ;
  $target    = $node->get_target    ;
  $text      = $node->get_text      ;
  $type      = $node->get_type      ;
  $deep_text = $node->get_deep_text ;
  
  $node->force_text($text);
  $node->force_for;
  $node->parse_begin (\@nodes);
  $node->set_children(\@children);
  $node->make_sequences;
  $node->parse_links;
  $node->unescape;
  $node->consolidate;
  $node->make_lists;

  $node->clone;
  $node->dump;
  
  Pod::Tree::Node->set_filename($filename);
  $filename = $node->get_filename;


=head1 REQUIRES

Pod::Escapes


=head1 DESCRIPTION

C<Pod::Tree::Node> objects are nodes in a tree that represents a POD.
Applications walk the tree to recover the structure and content of the POD.

Methods are provided for

=over 4

=item *

creating nodes in the tree

=item *

parsing the POD into nodes

=item *

returning information about nodes

=item *

walking the tree

=back


=head1 TREE STRUCTURE


=head2 Root node

The tree descends from a single root node;
C<is_root> returns true on this node and no other.

	$children = $root->get_children

returns a reference to an array of nodes.
These nodes represent the POD.


=head2 Node types

For each node,
call C<get_type> to discover the type of the node

	for $child (@$children)
	{
	    $type = $child->get_type;
	}

I<$type> will be one of these strings:

=over 4

=item 'root'

The node is the root of the tree.

=item 'code'

The node represents a paragraph that is not part of the POD.

=item 'verbatim'

The node represents a verbatim paragraph.

=item 'ordinary'

The node represents an ordinary paragraph.

=item 'command'

The node represents an =command paragraph (but not an =over paragraph).

=item 'sequence'

The node represents an interior sequence.

=item 'target'

The node represents the target of a link (An LE<lt>E<gt> markup).

=item 'text'

The node represents text that contains no interior sequences.

=item 'list'

The node represents an =over list.

=item 'item'

The node represents an item in an =over list.

=item 'for'

The node represents a =for paragraph,
or it represents the paragraphs between =begin/=end commands.

=back

Here are instructions for walking these node types.


=head2 root node

Call

	$children = $node->get_children

to get a list of nodes representing the POD.


=head2 code nodes

A code node contains the text of a paragraph that is not part of the
POD, for example, a paragraph that follows an C<=cut> command. Call

	$text = $node->get_text

to recover the text of the paragraph.


=head2 verbatim nodes

A verbatim node contains the text of a verbatim paragraph.
Call

	$text = $node->get_text

to recover the text of the paragraph.


=head2 ordinary nodes

An ordinary node represents the text of an ordinary paragraph.
The text is parsed into a list of text and sequence nodes;
these nodes are the children of the ordinary node.
Call

	$children = $node->get_children

to get a list of the children.
Iterate over this list to recover the text of the paragraph.


=head2 command nodes

A command node represents an =command paragraph.
Call 

	$command = $node->get_command;

to recover the name of the command. 
The name is returned I<without> the equals sign.

Z<>=over paragraphs are represented by list nodes,
not command nodes; see L<list nodes>, below.

The text of a command paragraph is parsed into 
a list of text and sequence nodes;
these nodes are the children of the command node.
Call

	$children = $node->get_children;

to get a list of the children.
Iterate over this list to recover the text of the paragraph.


=head2 sequence nodes

A sequence node represents a single interior sequence (a <> markup).
Call

	$node->get_letter

to recover the original markup letter.
The contents of the markup are parsed into a list of 
text and sequence nodes; 
these nodes are the children of the sequence node.
Call

	$node->get_children

to recover them.

ZE<lt>E<gt> and EE<lt>E<gt> markups do not generate sequence nodes;
these markups are expanded by C<Pod::Tree> when the tree is built.


=head2 target nodes

If a sequence node represents a link (an C<< LZ<><> >> markup),
then

	is_link $node

returns true and

	$target = $node->get_target

returns a node representing the target of the link. 

C<Pod::Tree::Node> can represent targets in two I<domains>: C<POD> and C<HTTP>.
The C<POD> domain represents the

	L<page/section>

markups that are described in L<perlpod>. 
The C<HTTP> domain represents C<< LZ<><> >> markups that contain a URL, e.g.

	L<http://foo.bar.com/page.html#fragment>

Call

	$domain = $target->get_domain

to discover the domain of the target.
For targets in the POD domain, call

	$page    = $target->get_page;
	$section = $target->get_section;

to recover the man page and section that the link refers to.
For targets in the HTTP domain, call

	$url     = $target->get_page;

to recover the URL for the link.

I<$target> is used only for constructing hyper-links;
the text to be displayed for the link is recovered by 
walking the children of I<$node>, as for any other interior sequence.


=head2 text nodes

A text node represents text that contains no interior sequences.
Call

	$text = $node->get_text

to recover the text.


=head2 list nodes

A list node represents an =over list.
Call

	$list_type = $node->get_list_type;

to discover the type of the list. This will be one of the strings

=over 4

=item 'bullet'

=item 'number'

=item 'text'

=back

The type of a list is the type of the first item in the list.

The children of a list node are item nodes;
each item node represents one item in the list.

You can call

	$node->get_arg;

to recover the indent value following the =over.


=head2 item nodes

An item node represents one item in an =over list.
Call

	$item_type = $node->get_item_type;

to discover the type of the item. 
This will be one of the strings shown above for L<list nodes>.
Typically, all the items in a list have the same type,
but C<Pod::Tree::Node> doesn't assume this.

The children of an item node represent the text of the =item paragraph;
this is usually of interest only for 'text' items.
Call

	$children = $node->get_children

to get a list of the children; 
these will be sequence and text nodes,
as for any other =command paragraph.

Each item node also has a list of nodes representing 
all the paragraphs following it,
up to the next =item command, 
or the end of the list.
These nodes are called I<siblings> of the item node.
Call

	$siblings = $node->get_siblings

to get a list of sibling nodes.


=head2 for nodes

for nodes represent text that is to be passed to an external formatter.
Call

	$formatter = $node->get_arg;

to discover the name of the formatter.
Call

	$text = $node->get_text;

to obtain the text to be passed to the formatter.
This will either be the text of an =for command, 
or all of the text between =begin and =end commands.


=head2 Walking the tree

PODs have a recursive structure;
therefore, any application that walks a Pod::Tree must also be recursive.
See F<skeleton> for an example of the necessary code.


=head1 METHODS

=head2 Constructors

These methods construct C<Pod::Tree::Node> objects.
They are used to build trees.
They aren't necessary to walk trees.

  $node = root     Pod::Tree::Node \@paragraphs;
  $node = code     Pod::Tree::Node $paragraph;
  $node = verbatim Pod::Tree::Node $paragraph;
  $node = command  Pod::Tree::Node $paragraph;
  $node = ordinary Pod::Tree::Node $paragraph;
  $node = letter   Pod::Tree::Node $token;
  $node = sequence Pod::Tree::Node $letter, \@children;
  $node = text     Pod::Tree::Node $text;
  $node = target   Pod::Tree::Node $target;
  $node = link     Pod::Tree::Node $node, $page, $section;

=over 4

=item I<$link> = C<Pod::Tree::Node>->C<link>(I<$node>, I<$page>, I<$section>)

Creates a new sequence node representing an C<< LZ<><> >> markup.
I<$node> becomes the sole child of the new node.
The target of the node is constructed from I<$page> and I<$section>.

This method isn't used to parse PODs.
It is provided for applications that want to create new links in an 
existing C<Pod::Tree> structure.

=back

=head2 Tests

These methods return true iff I<$node> has the type indicated by the
method name.

  is_code     $node and ...
  is_command  $node and ...
  is_for      $node and ...
  is_item     $node and ...
  is_letter   $node and ...
  is_link     $node and ...
  is_list     $node and ...
  is_ordinary $node and ...
  is_pod      $node and ...
  is_root     $node and ...
  is_sequence $node and ...
  is_text     $node and ...
  is_verbatim $node and ...

C<is_pod> returns true for all nodes except code, C<=pod>, 
and C<=cut> nodes. 


These methods return true iff I<$node> is a command node,
and the command is the one indicated by the method name.

  is_c_head1  $node and ...
  is_c_head2  $node and ...
  is_c_head3  $node and ...
  is_c_head4  $node and ...
  is_c_cut    $node and ...
  is_c_pod    $node and ...
  is_c_over   $node and ...
  is_c_back   $node and ...
  is_c_item   $node and ...
  is_c_for    $node and ...
  is_c_begin  $node and ...
  is_c_end    $node and ...


=head2 Accessors

These methods return information about nodes.
Most accessors are only relevant for certain types of nodes.

=over 4


=item I<$arg> = C<get_arg> I<$node>

Returns the argument of I<$node>.
This is the number following an =over command,
or the name of an external translator for =for, =begin, and =end commands.
Only relevant for these four command nodes.


=item I<$brackets> = C<get_brackets> I<$node>

Only relevant for for nodes.

If the node represents an =for command, 
I<@$brackets> is a single-element list.
The list element is the text of the =for command and its argument,
i.e. the name of the external formatter.

If the node represents a =begin/=end construct, 
I<@$brackets> is a two-element list containing
the text of the =begin and =end paragraphs.


=item I<$children> = C<get_children> I<$node>

Returns a reference to the list of nodes that are children of I<$node>.
May be called on any node.
The list may be empty.


=item I<$command> = C<get_command> I<$node>

Returns the name of a command, without the equals sign.
Only relevant for command nodes.


=item I<$domain> = C<get_domain> I<$node>

Only relevant for target nodes.
Returns the domain of the target.
This will be one of the strings

=over 4

=item 'HTTP'

=item 'POD'

=back


=item I<$item_type> = C<get_item_type> I<$node>

Returns the type of an item node. The type will be one of

=over 4

=item 'bullet'

=item 'number'

=item 'text'

=back


=item I<$letter> = C<get_letter> I<$node>

Returns the letter that introduces an interior sequence.
Only relevant for sequence nodes.


=item I<$list_type> = C<get_list_type> I<$node>

Returns the type of a list node.
The type of a list node is the type of the first item node in the list.


=item I<$page> = C<get_page> I<$node>

Only relevant for target nodes.
For targets in the C<POD> domain,
returns the man page that is the target of the link.
For targets in the C<HTTP> domain,
returns the URL that is the target of the link.


=item I<$raw> = C<get_raw> I<$node>

Returns the original text of a paragraph.
Currently provided for command, verbatim, and ordinary paragraphs.


=item I<$raw_kids> = C<get_raw_kids> I<$node>

Only provided for LZ<><> sequence nodes.
Returns a reference to a list of nodes representing the entire text 
of the LZ<><> sequence, including any part following a vertical bar (|).

The original text of the LZ<><> markup can be reconstructed from this list.


=item I<$section> = C<get_section> I<$node>

Only relevant for target nodes in the C<POD> domain.
Returns the section that is the target of a link.


=item I<$siblings> = C<get_siblings> I<$node>

Returns the siblings of a node.
May be called on any node.
Only item nodes have siblings.


=item I<$target> = C<get_target> I<$node>

Returns the target of a node.
Only relevant for sequence nodes that represent links 
(C<LE<lt>E<gt>> markups).
C<is_link> returns true on these nodes.


=item I<$text> = C<get_text> I<$node>

Returns the text of a node.
I<$text> will not contain any interior sequences.
Only relevant for text nodes.


=item I<$type> = C<get_type> I<$node>

Returns the type of I<$node>.
May be called on any node.
See L</TREE STRUCTURE> for descriptions of the node types.


=item I<$deep_text> = C<get_deep_text> I<$node>

Recursively walks the children of a node,
catenates together the text from each node,
and returns all that text as a single string.
All interior sequence markups are discarded.

C<get_deep_text> is provided as a convenience for applications that
want to ignore markups in a POD paragraph.

=back


=head2 Parsing

These methods manipulate the tree while it is being built.
They aren't necessary to walk the tree.

  $node->force_text($text)
  $node->force_for;
  $node->parse_begin (\@nodes);
  $node->set_children(\@children);
  $node->make_sequences;
  $node->parse_links;
  $node->unescape;
  $node->consolidate;
  $node->make_lists;


=head2 Utility

=over 4

=item I<$node>->C<clone>

Returns a deep copy of a node.
Only implemented for C<text> and C<sequence> nodes.


=item I<$node>->C<dump>

Returns a string containing a pretty-printed representation of the node.
Calling C<dump> on the root node of a tree will show the entire POD.


=item C<Pod::Tree::Node>->C<set_filename>(I<$filename>)

Sets the file name to be reported in error messages.


=item I<$filename> = $I<node>->C<getfile_name>

Returns the file name set by C<set_file_name>.


=back


=head1 EXAMPLES

The F<t/> directory in the C<Pod::Tree> distribution contains
examples of PODs, 
together with dumps of the trees that C<Pod::Tree> constructs for them.
The tree for C<t/>F<file>C<.pod> is in C<t/>F<file>C<.p_exp>.

C<Pod::Tree::Node::dump> is a simple example of code that walks a POD tree.

F<skeleton> is a skeleton application that walks a POD tree.


=head1 NOTES

=over 4

=item *

There is no provision in L<perlpod> for C<< LZ<><> >> markups to contain
URLs, but due to popular demand, this is now supported in
C<Pod::Tree::Node>.

=back


=head1 SEE ALSO

perl(1), L<C<Pod::Tree>>


=head1 AUTHOR

Steven McDougall, swmcd@world.std.com


=head1 COPYRIGHT

Copyright (c) 1999-2004 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.
