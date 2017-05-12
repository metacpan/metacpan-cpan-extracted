# Copyright (c) 1999-2009 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Pod::Tree;

use strict;
use warnings;
use IO::File;
use Pod::Tree::Node;
use Pod::Tree::Stream;

our $VERSION = '1.25';

sub new {
	my $class = shift;
	my $tree  = {
		loaded     => 0,
		paragraphs => []
	};
	bless $tree, $class;
}

sub load_file {
	my ( $tree, $file, %options ) = @_;

	Pod::Tree::Node->set_filename($file);

	my $fh = IO::File->new;
	$fh->open($file) or return '';
	$tree->load_fh( $fh, %options );

	Pod::Tree::Node->set_filename("");
	1;
}

sub load_fh {
	my ( $tree, $fh, %options ) = @_;

	$tree->{in_pod} = 0;
	$tree->_load_options(%options);
	my $limit = $tree->{limit};

	my $stream = Pod::Tree::Stream->new($fh);
	my $paragraph;
	my @paragraphs;
	while ( $paragraph = $stream->get_paragraph ) {
		push @paragraphs, $paragraph;
		$limit and $limit == @paragraphs and last;
	}

	$tree->{paragraphs} = \@paragraphs;
	$tree->_parse;
}

sub load_string {
	my ( $tree, $string, %options ) = @_;

	my @chunks = split /( \n\s*\n | \r\s*\r | \r\n\s*\r\n )/x, $string;

	my (@paragraphs);
	while (@chunks) {
		push @paragraphs, join '', splice @chunks, 0, 2;
	}

	$tree->load_paragraphs( \@paragraphs, %options );
}

sub load_paragraphs {
	my ( $tree, $paragraphs, %options ) = @_;

	$tree->{in_pod} = 1;
	$tree->_load_options(%options);

	my $limit      = $tree->{limit};
	my @paragraphs = @$paragraphs;
	$limit and splice @paragraphs, $limit;

	$tree->{paragraphs} = \@paragraphs;
	$tree->_parse;
}

sub loaded { shift->{'loaded'} }

sub _load_options {
	my ( $tree, %options ) = @_;

	my ( $key, $value );
	while ( ( $key, $value ) = each %options ) {
		$tree->{$key} = $value;
	}
}

sub _parse {
	my $tree = shift;

	$tree->_make_nodes;
	$tree->_make_for;
	$tree->_make_sequences;

	my $root = $tree->{root};

	$root->parse_links;
	$root->unescape;
	$root->consolidate;
	$root->make_lists;

	$tree->{'loaded'} = 1;
}

sub _add_paragraph {
	my ( $tree, $paragraph ) = @_;

	for ($paragraph) {
		/^=cut/ and do {
			$tree->{in_pod} = 0;
			last;
		};
		$tree->{in_pod} and do {
			push @{ $tree->{paragraphs} }, $paragraph;
			last;
		};
		/^=\w/ and do {
			$tree->{in_pod} = 1;
			push @{ $tree->{paragraphs} }, $paragraph;
			last;
		};
	}
}

my %Command = map { $_ => 1 } qw(=pod =cut
	=head1 =head2 =head3 =head4
	=over =item =back
	=for =begin =end);

sub _make_nodes {
	my $tree       = shift;
	my $paragraphs = $tree->{paragraphs};
	my $in_pod     = $tree->{in_pod};
	my @children;

	for my $paragraph (@$paragraphs) {
		my ($word) = split( /\s/, $paragraph );
		my $node;

		if ($in_pod) {
			if ( $paragraph =~ /^\s/ ) {
				$node = verbatim Pod::Tree::Node $paragraph;
			}
			elsif ( $Command{$word} ) {
				$node   = command Pod::Tree::Node $paragraph;
				$in_pod = $word ne '=cut';
			}
			else {
				$node = ordinary Pod::Tree::Node $paragraph;
			}
		}
		else {
			if ( $Command{$word} ) {
				$node   = command Pod::Tree::Node $paragraph;
				$in_pod = $word ne '=cut';
			}
			else {
				$node = code Pod::Tree::Node $paragraph;
			}
		}

		push @children, $node;
	}

	$tree->{root} = root Pod::Tree::Node \@children;
}

sub _make_for {
	my $tree = shift;
	my $root = $tree->{root};
	my $old  = $root->get_children;

	my @new;
	while (@$old) {
		my $node = shift @$old;
		is_c_for $node   and $node->force_for;
		is_c_begin $node and $node->parse_begin($old);
		push @new, $node;
	}

	$root->set_children( \@new );
}

sub _make_sequences {
	my $tree  = shift;
	my $root  = $tree->{root};
	my $nodes = $root->get_children;

	for my $node (@$nodes) {
		is_code $node     and next;
		is_verbatim $node and next;
		is_for $node      and next;
		$node->make_sequences;
	}
}

sub dump {
	my $tree = shift;
	$tree->{root}->dump;
}

sub get_root { shift->{root} }

sub set_root {
	my ( $tree, $root ) = @_;
	$tree->{root} = $root;
}

sub push {
	my ( $tree, @nodes ) = @_;
	my $root     = $tree->{root};
	my $children = $root->get_children;
	push @$children, @nodes;
}

sub pop {
	my $tree     = shift;
	my $root     = $tree->get_root;
	my $children = $root->get_children;
	pop @$children;
}

sub walk {
	my ( $tree, $sub ) = @_;

	my $root = $tree->get_root;
	_walk( $root, $sub );
}

sub _walk {
	my ( $tree, $sub ) = @_;

	my $descend = &$sub($tree);    # :TRICKY: sub can modify node
	$descend or return;

	my $node = $tree;

	my $children = $node->get_children;
	for my $child (@$children) {
		_walk( $child, $sub );
	}

	my $siblings = $node->get_siblings;
	for my $sibling (@$siblings) {
		_walk( $sibling, $sub );
	}
}

sub has_pod {
	my $tree     = shift;
	my $root     = $tree->get_root;
	my $children = $root->get_children;

	scalar grep { $_->get_type ne 'code' } @$children;
}

1

__END__

=head1 NAME

Pod::Tree - Create a static syntax tree for a POD


=head1 SYNOPSIS

  use Pod::Tree;
  
  $tree = Pod::Tree->new;
  $tree->load_file      ( $file, %options)
  $tree->load_fh        ( $fh  , %options);
  $tree->load_string    ( $pod , %options);
  $tree->load_paragraphs(\@pod , %options);
  
  $loaded = $tree->loaded;  
  
  $node   = $tree->get_root;
            $tree->set_root  ($node);
  $node =   $tree->pop;
            $tree->push(@nodes);
  
            $tree->walk(\&sub);
            $tree->has_pod and ...
  print     $tree->dump;


=head1 EXPORTS

Nothing


=head1 DESCRIPTION

C<Pod::Tree> parses a POD into a static syntax tree.
Applications walk the tree to recover the structure and content of the POD.
See L<C<Pod::Tree::Node>> for a description of the tree.


=head1 METHODS

=over 4

=item I<$tree> = C<Pod::Tree>->C<new>

Creates a new C<Pod::Tree> object.
The syntax tree is initially empty.


=item I<$ok> = I<$tree>->C<load_file>(I<$file>, I<%options>)

Parses a POD and creates a syntax tree for it.
I<$file> is the name of a file containing the POD.
Returns null iff it can't open I<$file>.

See L</OPTIONS> for a description of I<%options>


=item I<$tree>->C<load_fh>(I<$fh>, I<%options>)

Parses a POD and creates a syntax tree for it.
I<$fh> is an C<IO::File> object that is open on a file containing the POD.

See L</OPTIONS> for a description of I<%options>


=item I<$tree>->C<load_string>(I<$pod>, I<%options>)

Parses a POD and creates a syntax tree for it.
I<$pod> is a single string containing the POD.

See L</OPTIONS> for a description of I<%options>


=item I<$tree>->C<load_paragraphs>(\I<@pod>, I<%options>)

Parses a POD and creates a syntax tree for it.
I<\@pod> is a reference to an array of strings.
Each string is one paragraph of the POD.

See L</OPTIONS> for a description of I<%options>


=item I<$loaded> = I<$tree>->C<loaded>

Returns true iff one of the C<load_>* methods has been called on I<$tree>.


=item I<$node> = I<$tree>->C<get_root>

Returns the root node of the syntax tree.
See L<Pod::Tree::Node> for a description of the syntax tree.


=item I<$tree>->C<set_root>(I<$node>)

Sets the root of the syntax tree to I<$node>.


=item I<$tree>->C<push>(I<@nodes>)

Pushes I<@nodes> onto the end of the top-level list of nodes in I<$tree>.


=item I<$node> = I<$tree>->C<pop>

Pops I<$node> off of the end of the top-level list of nodes in I<$tree>.


=item I<$tree>->C<walk>(I<\&sub>)

Walks the syntax tree, depth first.
Calls I<sub> once for each node in the tree.
The current node is passed as the first argument to I<sub>.

C<walk> descends to the children and siblings of I<$node> iff
I<sub()> returns true.


=item I<$tree>->C<has_pod>

Returns true iff I<$tree> contains POD paragraphs.


=item I<$tree>->C<dump>

Pretty prints the syntax tree.
This will show you how C<Pod::Tree> interpreted your POD.

=back


=head1 OPTIONS

These options may be passed in the I<%options> hash to the C<load_>* methods.

=over 4

=item C<< in_pod => 0 >>

=item C<< in_pod => 1 >>

Sets the initial value of C<in_pod>.
When C<in_pod> is false,
the parser ignores all text until the next =command paragraph.

The initial value of C<in_pod> 
defaults to false for C<load_file()> and C<load_fh()> calls
and true for  C<load_string()> and C<load_paragraphs()> calls.
This is usually what you want, unless you want consistency.
If this isn't what you want,
pass different initial values in the I<%options> hash.


=item C<limit> => I<n>

Only parse the first I<n> paragraphs in the POD.

=back


=head1 DIAGNOSTICS

=over 4

=item C<load_file>(I<$file>)

Returns null iff it can't open I<$file>.

=back


=head1 NOTES

=head2 No round-tripping

Currently, C<Pod::Tree> does not provide a complete, exact 
representation of its input. For example, it doesn't distingish
between 

    C<$foo-E<gt>bar>

and 

   C<< $foo->bar >>

As a result, it is not guaranteed that a file can be
exactly reconstructed from its C<Pod::Tree> representation.


=head2 LZ<><> markups

In the documentation of the 

    L<"sec">	section in this manual page

markup, L<C<perlpod>> has always claimed

		(the quotes are optional)

However, there is no way to decide from the syntax alone whether

    L<foo>

is a link to the F<foo> man page or 
a link to the C<foo> section of this man page.

C<Pod::Tree> parses C<< LZ<><foo> >> as a link to a section if
C<foo> looks like a section name (e.g. contains whitespace), 
and as a link to a man page otherswise. 

In practice, this tends to break links to sections.
If you want your section links to work reliably, 
write them as C<< LZ<><"foo"> >> or C<< LZ<></foo> >>.


=head1 SEE ALSO

perl(1), L<C<Pod::Tree::Node>>, L<C<Pod::Tree::HTML>>


=head1 ACKNOWLEDGMENTS

=over 4

=item *

<crazyinsomniac@yahoo.com>

=item *

<joenio@cpan.org>

=item *

Paul Bettinger <paul@n8geil.de>

=item *

Sean M. Burke <sburke@spinn.net>

=item *

Brad Choate <brad@bradchoate.com>

=item *

Havard Eidnes <he@NetBSD.org>

=item *

Rudi Farkas <rudif@bluemail.ch>

=item *

Paul Gibeault <pagibeault@micron.com>

=item *

Jay Hannah <jhannah@omnihotels.com>

=item *

Paul Hawkins <phawkins@datajunction.com>

=item *

Jost Krieger <Jost.Krieger@ruhr-uni-bochum.de>

=item *

Marc A. Lehmann <pcg@goof.com> 

=item *

Jonas Liljegren <jonas@jonas.rit.se>

=item *

Thomas Linden <tom@co.daemon.de>

=item *

Johan Lindstrom <johanl@bahnhof.se>

=item *

Terry Luedtke <terry_luedtke@nlm.nih.gov>

=item *

Rob Napier <rnapier@employees.org>

=item *

Kate L Pugh <kake@earth.li>

=item *

Christopher Shalah <trance@drizzle.com>

=item *

Johan Vromans <JVromans@Squirrel.nl>

=back


=head1 AUTHOR

Steven McDougall <swmcd@world.std.com>


=head1 COPYRIGHT

Copyright (c) 1999-2009 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.
