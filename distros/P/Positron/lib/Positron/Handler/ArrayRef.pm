package Positron::Handler::ArrayRef;
our $VERSION = 'v0.1.3'; # VERSION

=head1 NAME

Positron::Handler::ArrayRef - a DOM interface for ArrayRefs

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

  my $engine = Positron::Template->new();

  my $template = [
    'a',
    { href => "/"},
    [ 'b', "Now: " ],
    "next page",
  ];
  my $data   = { foo => 'bar', baz => [ 1, 2, 3 ] };
  my $result = $engine->parse($template, $data); 

=head1 DESCRIPTION

This module allows C<Positron::Template> to work with a simple DOM representation:
ArrayRefs.
This module can also be used as a blueprint for writing more handlers; the
documentation of the methods is therefore extra deep.

=head2 ArrayRef representation

In ArrayRef representation, a DOM element is simply a reference to an array
with at least one element: the node tag, an optional hash (reference) with attributes,
and any children the node might have. Pure text is represented by simple strings.
Comments, processing instructions or similar have no intrinsic representation;
at best they can be represented as simple nodes with special tag names.

An example:

  [
    'a',
    { href => "/"},
    [ 'b', "Now: " ],
    "next page >>",
    ['br'],
  ];

This corresponds to the HTML representation of:

  <a href="/"><b>Now: </b>next page &gt;&gt;<br /></a>

Note the plain C<<< >> >>> in the ArrayRef representation: text does B<not>
need to be encoded in HTML entities.
Note also that the attributes, if present, need to occupy the second slot
of the array reference. A missing attribute hash reference corresponds to
no attributes.

=cut

use v5.10;
use strict;
use warnings;

use Carp;

# Format:
# [ 'a', { href => "/"},
#   [ 'b', [ "Now: " ] ],
#   "next page",
# ]

# TODO: is_regular_node? Places burden of checking types on caller 

=head1 CONSTRUCTOR

=head2 new

  $handler = Positron::Handler::ArrayRef->new();

The constructor has no parameters; this is a very basic class.
Normally, the template engine will automatically call the constructor
of the correct handler for whatever it is handed as template.

=cut 

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

=head1 METHODS

The following methods are part of the "handler interface". The point
of a handler is to present a unified interface for all DOM operations
that C<Positron::Template> needs to do. So even though these methods
are quite simple, even trivial, given the ArrayRef representation,
they must be fully implemented.

=head2 shallow_clone

  $new_node = $handler->shallow_clone($orig_node);

This method returns a clone of the given node. This clone has the
same attributes as the original, but no children. The clone is
never identical to the original, even if it could be (i.e. the
original has no children).

Text nodes, which are simple strings, are cloned to copies of
themselves.

=cut

sub shallow_clone {
    my ($self, $node) = @_;
    if (ref($node)) {
        # should not clone children
        my ($tag, $attributes) = @$node; 
        if (ref($attributes) ne 'HASH') {
            $attributes = {};
        }
        my $new_node = [ $tag, { %$attributes } ];
        return $new_node;
    } else {
        return "$node";
    }
}

=head2 get_attribute

  $value = $handler->get_attribute($node, $attr_name);

Gets the I<value> of a named attribute of the node. If the node does
not have an attribute of this name, or it is a text node (which has
no attributes), C<undef> is returned.

=cut

sub get_attribute {
    # gets the value, not the attribute node.
    my ($self, $node, $attr) = @_;
    return unless ref($node);
    my ($tag, $attributes, @children) = @$node; 
    if (ref($attributes) ne 'HASH') {
        $attributes = {};
    }
    return $attributes->{$attr};
}

=head2 set_attribute

  $handler->set_attribute($node, $attr_name => $new_value);

Sets the named attribute to the new value. Setting an attribute to
C<undef> will delete the attribute. It is not an error to try to
set an attribute on a text node, but nothing will happen.

Returns the new value (or C<undef> as needed), though C<Positron::Template>
does not use the return value.

=cut

sub set_attribute {
    my ($self, $node, $attr, $value) = @_;
    return unless ref($node);
    my ($tag, $attributes, @children) = @$node; 
    if (ref($attributes) ne 'HASH') {
        $attributes = {};
        splice @$node, 1, 0, $attributes;
    }
    if (defined($value)) {
        return $attributes->{$attr} = $value;
    } else {
        delete $attributes->{$attr};
        return;
    }
}

=head2 list_attributes

  @attr_names = $handler->list_attributes($node);

Lists the I<names> of all (defined) attributes on the node.
Text nodes have no attributes and generate an empty list.

=cut

sub list_attributes {
    my ($self, $node) = @_;
    return unless ref($node);
    my ($tag, $attributes, @children) = @$node; 
    return unless ref($attributes) eq 'HASH';
    return sort keys %$attributes;
}

=head2 push_contents

  $handler->push_contents($node, $child_1, $child_2, $child_3);

Push the passed nodes, in the given order, onto the I<end> of the
child list of the first argument.
Text nodes, again, ignore this method silently.

=cut

sub push_contents {
    # set_contents? Will only be called on shallow clones, right?
    my ($self, $node, @contents) = @_;
    return unless ref($node);
    return push @$node, @contents;
}

=head2 list_contents

  @child_nodes = $handler->list_contents($node);

Lists the contents, i.e. the child nodes, of the given node. These
are not cloned nodes, but the actual children. Text nodes, of course,
have none.

=cut

sub list_contents {
    my ($self, $node) = @_;
    return unless ref($node);
    return unless (@$node > 1); # neither attributes nor content
    my ($tag, $attributes, @children) = @$node; 
    if (ref($attributes) ne 'HASH') {
        # not an attribute hash after all?
        unshift @children, $attributes;
    }
    return @children;
}

=head2 parse_file

  $root_node = $handler->parse_file($filename);

Reads and parses a file with the given filename. It is recommended to pass
an absolute filename, unless you can be sure about your current directory.
Normally, this method would not be necessary (since the template engine works
on already-parsed DOM trees by design), but there are template constructs that
include files via filename.

If C<$filename> ends in C<.json> or C<.js>, the file is assumed to be in JSON
format, and will be parsed with a freshly C<require>d C<JSON> module.

Otherwise, it is assumed to be an array reference serialized with the
C<Storable> module.

=cut

sub parse_file {
    # Needs more info on directories!
    # Storable: { nodes = [ ... ] }
    my ($self, $filename) = @_;
    # TODO: select deserializer based on filename (Storable / JSON / eval?)
    if ($filename =~ m{ \. (json|js) $ }xms) {
        require JSON; # should use JSON::XS if available
        require File::Slurp;
        my $json = File::Slurp::read_file($filename);
        return JSON->new->utf8->allow_nonref->decode($json);
    } else {
        # Storable
        require Storable;
        my $dom = Storable::retrieve($filename);
        return $dom;
    }
}

1;

__END__

=head1 AUTHOR

Ben Deutsch, C<< <ben at bendeutsch.de> >>

=head1 BUGS

None known so far, though keep in mind that this is alpha software.

Please report any bugs or feature requests to C<bug-positron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Positron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is part of the Positron distribution.

You can find documentation for this distribution with the perldoc command.

    perldoc Positron

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Positron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Positron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Positron>

=item * Search CPAN

L<http://search.cpan.org/dist/Positron/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ben Deutsch. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See L<http://dev.perl.org/licenses/> for more information.

=cut
