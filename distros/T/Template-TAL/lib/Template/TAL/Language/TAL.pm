=head1 NAME

Template::TAL::Language::TAL - implement TAL tags

=head1 DESCRIPTION

The TAL language module for Template::TAL. This module implements the
TAL specification version 1.4
(http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL%20Specification%201.4).

Tags in the TAL namespace (http://xml.zope.org/namespaces/tal) will be
handled by this module, for instance,

  <html xmlns:tal="http://xml.zope.org/namespaces/tal">
    <ul>
      <li tal:repeat="row rows" tal:content="row" />
    </ul>
  </html>

=cut

package Template::TAL::Language::TAL;
use warnings;
use strict;
use Carp qw( croak );
use base qw( Template::TAL::Language );
use overload;

sub namespace { 'http://xml.zope.org/namespaces/tal' }

sub tags { qw( define condition repeat replace content attributes omit-tag ) }

############
# tag definitions

sub process_tag_define {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;

  # there may be multiple set statements in one attribute.
  my @setters = Template::TAL::ValueParser->split($value);
  for (@setters) {
    # we can set variables into the local context or the golbal context
    my ($set_context, $var, $set) = /^(local\b|global\b)?\s*(\S+)\s+(.*)$/;
    $set_context ||= "local"; # defaults

    # interpret the value part as a TALES string
    my $result = $parent->parse_tales($set, $local_context, $global_context);

    if ($set_context eq 'local') {
      $local_context->{$var} = $result;
    } else {
      $global_context->{$var} = $result;
    }
  }
  
  return $node; # don't replace node
}

sub process_tag_condition {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  # if the TALES string 'value' doesn't return a true value, remove this entire node
  return $parent->parse_tales($value, $local_context, $global_context) ? $node : ();
}

sub process_tag_repeat {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  my ($var, $list) = $value =~ /^(\S+)\s+(.*)$/;
  # $list should tales-parse to a list object, and this node will be repeated with
  # the variable named by $var set to each element of the list

  # coerce to a list if it's not already. Template toolkit does this, I like it.
  my $items = $parent->parse_tales($list, $local_context, $global_context);
  my @items =
    ( UNIVERSAL::isa($items, "ARRAY") || overload::Method($items, '@{}') ) ?
    @$items : ($items);

  # create a scratch node to hold the things we're going to hand
  # back. We do this rather than create a list, because the recursive
  # processor might want to replace these nodes _again_, and it does
  # that using the DOM tree. For instance
  #  <foo tal:repeat="..." tal:replace="..." />
  # will clone many foo nodes, then replace them all, so we want to
  # return the replacements.
  my $temp = XML::LibXML::Element->new( "temp" );

  my $index = 0; # for the magic hash
  for my $localvalue (@items) {
    # clone the thing we're repeating, and add to the temp element
    my $new = $node->cloneNode(1);
    $temp->appendChild($new);

    # the local value of the list
    $local_context->{$var} = $localvalue;

    # magic repeat hash, defined in http://www.zope.org/Wikis/DevSite/Projects/ZPT/RepeatVariable
    $local_context->{repeat}{$var} = {
      'index' => $index,
      'number' => $index + 1,
      'even' => $index % 2 ? 0 : 1,
      'odd' => $index % 2 ? 1 : 0,
      'start' => $index == 0,
      'end' => $index == scalar(@items) - 1,
      'length' => scalar(@items),
      'letter' => "TODO", # hmm.
    };
    $index++;

    # now we've cloned this node, recurse into it, with the new local context
    $parent->_process_node( $new, $local_context, $global_context );
  }

  # return a list of new nodes, which will get put into the original
  # document.
  return $temp->childNodes;
}

# replace the referenced node with the value of the tal:replace attribute
sub process_tag_replace {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;

  my ($type, $set) = $value =~ /^(text\b|structure\b)?\s*(.*)$/;
  $type ||= 'text';
  my $result = $parent->parse_tales($set, $local_context, $global_context);

  # replace the node with the content
  my @dom = $self->_dom_for_content( $type, $result );
  return @dom;
}

# replace the contents of the node with the value of the tal:content attribute
sub process_tag_content {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;

  my ($type, $set) = $value =~ /^(text\b|structure\b)?\s*(.*)$/;
  $type ||= 'text';
  my $result = $parent->parse_tales($set, $local_context, $global_context);

  # place the result into the node
  my @dom = $self->_dom_for_content( $type, $result );
  $node->removeChildNodes(); # remove existing children
  $node->appendChild($_) for @dom; # and add new children

  return $node; # don't replace node
}

sub _dom_for_content {
  my ($class, $type, $content) = @_;
  if ($type eq 'text') {
    return XML::LibXML::Text->new( defined($content) ? Encode::encode_utf8($content) : "" );
  } else {
    my $parser = XML::LibXML->new();
    $parser->recover(1); # this seems like it will be useful. TODO - should be an option
    # to allow for strings such as 'foo <bar>baz</bar>', which aren't themselves
    # valid XML, but should sensibly be dealt with, wrap in an enclosing tag,
    # and return all subnodes. TODO - Is this even desired behaviour?

    # convert to utf-8 bytes, and parse as a utf-8 document, to preserve non-ascii
    my $bytes = Encode::encode_utf8($content);
    my $document = $parser->parse_string(
      "<?xml version='1' encoding='utf-8'?><document>$bytes</document>");    
    return $document->documentElement->childNodes;
  }
}

sub process_tag_attributes {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  # there may be >1 attribute set here
  my @setters = Template::TAL::ValueParser->split($value);
  for (@setters) {
    my ($var, $set) = /^\s*(\S+)\s+(.*)$/;
    my $value = $parent->parse_tales($set, $local_context, $global_context);
    $node->setAttribute( $var, $value );
  }
  return $node; # don't replace node
}

sub process_tag_omit_tag {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  # if value is false, don't do anything
  return $node unless $parent->parse_tales($value, $local_context, $global_context);
  # otherwise process this node as normal, and return the children of it
  $parent->_process_node( $node, $local_context, $global_context );
  return $node->childNodes();
}

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
