package Mojo::DOM::Role::PrettyPrinter;

use Role::Tiny;
use Carp 'croak';
use Mojo::ByteStream 'b';

our $VERSION = '0.03';

requires 'tree';

# Render as pretty xml
sub to_pretty_string {
  my ($self, $i) = (shift, shift // 0);
  my $tree = shift || $self->tree;

  my $e = $tree->[0];

  # No element
  croak('No element') and return unless $e;

  # Element is tag
  if ($e eq 'tag') {
    my $subtree = [@{$tree}[0 .. 2], [@{$tree}[4 .. $#$tree]]];

    return $self->_element($i, $subtree);
  }

  # Element is text
  elsif ($e eq 'text') {

    my $escaped = $tree->[1];

    for ($escaped) {
      next unless $_;

      # Escape and trim whitespaces from both ends
      $_ = b($_)->xml_escape->trim;
    }

    return $escaped;
  }

  # Element is comment
  elsif ($e eq 'comment') {

    # Padding for every line
    my $p = '  ' x $i;
    my $comment = join "\n$p     ", split(/;\s+/, $tree->[1]);

    return "\n" . ('  ' x $i) . "<!-- $comment -->\n";

  }

  # Element is processing instruction
  elsif ($e eq 'pi') {
    return ('  ' x $i) . '<?' . $tree->[1] . "?>\n";

  }

  # Element is root
  elsif ($e eq 'root') {

    my $content;

    # Pretty print the content
    $content .= $self->to_pretty_string($i, $tree->[$_]) for 1 .. $#$tree;

    return $content;
  }
}

# Render element with pretty printing
sub _element {
  my ($self, $i) = (shift, shift);
  my ($type, $qname, $attr, $child) = @{shift()};

  # Is the qname valid?
  croak "$qname is no valid QName" unless $qname =~ /^(?:[a-zA-Z_]+:)?[^\s]+$/;

  # Start start tag
  my $content = ('  ' x $i) . "<$qname";

  # Add attributes
  $content .= $self->_attr(('  ' x $i) . (' ' x (length($qname) + 2)), $attr);

  # Has the element a child?
  if ($child->[0]) {

    # Close start tag
    $content .= '>';

    # There is only a textual child - no indentation
    if (!$child->[1] && ($child->[0] && $child->[0]->[0] eq 'text')) {
        # Escape
        $content .= b($child->[0]->[1])->trim->xml_escape;
    }

    # There are a couple of children
    else {

      my $offset = 0;

      # First element is unformatted textual
      if ($child->[0] && $child->[0]->[0] eq 'text') {

        # Append directly to the last tag
        $content .= b($child->[0]->[1])->trim->xml_escape;
        $offset = 1;
      }

      # Start on a new line
      $content .= "\n";

      # Loop through all child elements
      foreach (@{$child}[$offset .. $#$child]) {

        # Render next element
        $content .= $self->to_pretty_string($i + 1, $_);
      }

      # Correct Indent
      $content .= ('  ' x $i);
    }

    # End Tag
    $content .= "</$qname>\n";
  }

  # No child - close start element as empty tag
  else {
    $content .= " />\n";
  }

  # Return content
  return $content;
}

# Render attributes with pretty printing
sub _attr {
  my ($self, $indent_space) = (shift, shift);
  my %attr = %{$_[0]};

  # Prepare attribute values
  $_ = b($_)->xml_escape->quote foreach values %attr;

  # Return indented attribute string
  if (keys %attr) {
    return ' ' . join "\n$indent_space",
      map { "$_=" . $attr{$_} } sort keys %attr;
  }

  # Return nothing
  return '';
}


1;

=head1 NAME

Mojo::DOM::Role::PrettyPrinter - Add a pretty printer method to Mojo::DOM

=head1 SYNOPSIS

  use Mojo::DOM;
  my $dom=Mojo::DOM->with_roles('+PrettyPrinter')->new('<div><h1>Loving it</h1></div>');
  warn $dom->to_pretty_string;
  # <div>
  #   <h1>Loving it</h1>
  # </div>

=head1 DESCRIPTION

Support pretty printing XML documents. The original source for this function was
extracted from L<XML::Loy>.

=head1 METHODS

=head2 to_pretty_string

Returns the current L<Mojo::DOM> structure as indented XML.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2017, Marcus Ramberg and Nils Diewald

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
