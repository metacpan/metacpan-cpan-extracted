# Copyright (c) 2000-2003 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Pod::Tree::Pod;
use 5.006;
use strict;
use warnings;

our $VERSION = '1.29';

use IO::File;
use Pod::Tree;

sub new {
	my ( $class, $tree, $dest ) = @_;
	defined $dest or die "Pod::Tree::Pod::new: not enough arguments\n";

	my $file = _resolve_dest($dest);

	my $pod = {
		tree     => $tree,
		root     => $tree->get_root,
		file     => $file,
		interior => 0,
		link     => 0
	};

	bless $pod, $class;
}

sub _resolve_dest {
	my $dest = shift;

	ref $dest and return $dest;

	my $fh = IO::File->new;
	$fh->open(">$dest") or die "Pod::Tree::Pod::new: Can't open $dest: $!\n";
	$fh;
}

sub translate {
	my $pod  = shift;
	my $root = $pod->{root};
	$pod->_emit_children($root);
}

sub _emit_children {
	my ( $pod, $node ) = @_;

	my $children = $node->get_children;

	for my $child (@$children) {
		$pod->_emit_node($child);
	}
}

sub _emit_siblings {
	my ( $pod, $node ) = @_;

	my $siblings = $node->get_siblings;

	for my $sibling (@$siblings) {
		$pod->_emit_node($sibling);
	}
}

sub _emit_node {
	my ( $pod, $node ) = @_;
	my $type = $node->{type};

	for ($type) {
		/code/     and $pod->_emit_code($node);
		/command/  and $pod->_emit_command($node);
		/for/      and $pod->_emit_for($node);
		/item/     and $pod->_emit_item($node);
		/list/     and $pod->_emit_list($node);
		/ordinary/ and $pod->_emit_ordinary($node);
		/sequence/ and $pod->_emit_sequence($node);
		/text/     and $pod->_emit_text($node);
		/verbatim/ and $pod->_emit_verbatim($node);
	}
}

sub _emit_code {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};
	my $text = $node->get_text;

	$file->print($text);
}

sub _emit_command {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};
	my $raw  = $node->get_raw;

	$file->print($raw);
}

sub _emit_for {
	my ( $pod, $node ) = @_;
	my $file     = $pod->{file};
	my $brackets = $node->get_brackets;

	$file->print( $brackets->[0] );
	$file->print( $node->get_text );
	$file->print( $brackets->[1] ) if $brackets->[1];
}

sub _emit_item {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};

	$file->print("=item ");
	$pod->_emit_children($node);

	$pod->_emit_siblings($node);
}

sub _emit_list {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};

	my $over = $node->get_raw;
	$file->print($over);

	$pod->_emit_children($node);

	my $back = $node->get_back;
	$back
		and $file->print( $back->get_raw );
}

sub _emit_ordinary {
	my ( $pod, $node ) = @_;

	$pod->_emit_children($node);
}

sub _emit_sequence {
	my ( $pod, $node ) = @_;

	$pod->{interior}++;

	for ( $node->get_letter ) {
		/I|B|C|E|F|S|X/ and $pod->_emit_element($node), last;
		/L/             and $pod->_emit_link($node),    last;
	}

	$pod->{interior}--;
}

sub _emit_element {
	my ( $pod, $node ) = @_;

	my $letter = $node->get_letter;
	my $file   = $pod->{file};

	$file->print("$letter<");
	$pod->_emit_children($node);
	$file->print(">");
}

sub _emit_link {
	my ( $pod, $node ) = @_;

	my $file = $pod->{file};

	$file->print("L<");

	my $children = $node->get_raw_kids;
	for my $child (@$children) {
		$pod->_emit_node($child);
	}

	$file->print(">");
}

sub _emit_link_hide {
	my ( $pod, $node ) = @_;

	my $file    = $pod->{file};
	my $target  = $node->get_target;
	my $page    = $target->get_page;
	my $section = $target->get_section;
	my $slash   = $section ? '/' : '';
	my $link    = "$page$slash$section";

	if ( $link eq $node->get_deep_text ) {
		$file->print("L<");
		$pod->_emit_children($node);
		$file->print(">");
	}
	else {
		$pod->{link}++;

		$file->print("L<");
		$pod->_emit_children($node);

		$page    = $pod->_escape($page);
		$section = $pod->_escape($section);
		$file->print("|$page$slash$section>");

		$pod->{link}--;
	}
}

sub _emit_text {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};
	my $text = $node->get_text;

	$text = $pod->_escape($text);
	$file->print($text);
}

sub _escape {
	my ( $pod, $text ) = @_;

	$text =~ s/^=(\w)/=Z<>$1/;

	if ( $pod->{interior} ) {
		$text =~ s/([A-Z])</$1E<lt>/g;
		$text =~ s/>/E<gt>/g;
	}

	if ( $pod->{link} ) {
		$text =~ s(\|)(E<verbar>)g;
		$text =~ s(/)(E<sol>)g;
	}

	$text =~ s/([\x80-\xff])/sprintf("E<%d>", ord($1))/eg;

	$text;
}

sub _emit_verbatim {
	my ( $pod, $node ) = @_;
	my $file = $pod->{file};
	my $text = $node->get_text;

	$file->print($text);
}

1

__END__

=head1 NAME

Pod::Tree::Pod - Convert a Pod::Tree back to a POD

=head1 SYNOPSIS

  use Pod::Tree::Pod;

  $tree =  Pod::Tree->new;
    
  $dest =  IO::File->new;
  $dest = "file.pod";

  $pod  =  Pod::Tree::Pod->new($tree, $dest);

  $pod->translate;

=head1 DESCRIPTION

C<Pod::Tree::Pod> converts a Pod::Tree back to a POD.
The destination is fixed when the object is created.
The C<translate> method does the actual translation.

For convenience, 
Pod::Tree::Pod can write the POD to a variety of destinations.
The C<new> method resolves the I<$dest> argument.

=head2 Destination resolution

C<Pod::Tree::Pod> can write HTML to either of 2 destinations.
C<new> resolves I<$dest> by checking these things,
in order:

=over 4

=item 1

If I<$dest> is a reference,
then it is taken to be an C<IO::File> object
that is already open on the file where the POD will be written.

=item 2

If I<$dest> is not a reference,
then it is taken to be the name of the file where the POD will be written.

=back

=head1 METHODS

=over 4

=item I<$pod> = C<new> C<Pod::Tree::Pod> I<$tree>, I<$dest>

Creates a new C<Pod::Tree::Pod> object.

I<$tree> is a C<Pod::Tree> object that represents a POD.
I<$pod> writes the POD to I<$dest>.
See L</Destination resolution> for details.

=item I<$pod>->C<translate>

Writes the text of the POD.
This method should only be called once.

=back

=head1 DIAGNOSTICS

=over 4

=item C<Pod::Tree::Pod::new: not enough arguments>

(F) C<new> called with fewer than 2 arguments.

=item C<Pod::Tree::HTML::new: Can't open $dest: $!>

(F) The destination file couldn't be opened.

=back

=head1 NOTES

=over 4

=item *

The destination doesn't actually have to be an C<IO::File> object.
It may be any object that has a C<print> method.

=back

=head1 SEE ALSO

perl(1), L<C<Pod::Tree>>, L<C<Pod::Tree::Node>>

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright (c) 2000-2003 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.
