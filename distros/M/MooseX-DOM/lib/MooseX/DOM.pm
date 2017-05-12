# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM.pm 68287 2008-08-12T03:01:31.558361Z daisuke  $

package MooseX::DOM;
use strict;
use Moose::Util;
use Carp ();

our $AUTHORITY = 'cpan:DMAKI';
our $VERSION   = '0.00004';

BEGIN {
    my $engine = $ENV{MOOSEX_DOM_ENGINE} || 'MooseX::DOM::LibXML';
    Class::MOP::load_class( $engine );

    constant->import(ENGINE => $engine);
}

sub import {
    my $class = shift;
    my $caller = caller(0);

    return if $caller eq 'main';

    # if $caller is already meta-fied.
    if ( $caller->can('meta') ) {
        Carp::confess "You already have 'meta' initialized. you need to 'use MooseX::DOM' /instead/ of 'use Moose'";
    }

    my $engine = &ENGINE;
    $engine->init_meta( $caller );
    Moose::Util::apply_all_roles($caller->meta, $engine);
    Moose->import( { into => $caller }, @_ );

    my $exporter = join('::', $engine, 'export_dsl');
    goto &$exporter;
}

sub unimport {
    my $class = shift;

    my $caller = caller(0);
    Moose->unimport( { into => $caller }, @_ );

    my $engine = &ENGINE;
    my $unexporter = join('::', $engine, 'unexport_dsl' );
    goto &$unexporter;
}

    

1;

__END__

=head1 NAME

MooseX::DOM - Simplistic Object XML Mapper

=head1 SYNOPSIS

  package MyObject;
  use MooseX::DOM;
 
  has_dom_child 'title';

  no Moose;
  no MoooseX::DOM;

  my $obj = MyObject->new(node => <<EOXML);
  <feed>
    <title>Foo</title>
  </feed>
  EOXML

  print $obj->title(), "\n"; # Foo
  $obj->title('Bar');
  print $obj->title(), "\n"; # Bar

=head1 DESCRIPTION

This module is intended to be used in conjunction with other modules
that encapsulate XML data (for example, XML feeds).

=head1 DECLARATION

=head2 has_dom_root $name[, %opts]

Specifies that the given XML have the specified tag. This specification is
also used when creating new root node for creating the underlying XML

  has_dom_root $name => (
    # attributes => { ... }
  );

=head2 has_dom_attr $name[, %opts]

Specifies that the object should contain an attribute by the given name

=head2 has_dom_child $name[, %opts]

Specifies that the object should contain a single child by the given name.
Will generate accessor that can handle set/get

  has_dom_child 'foo';

  $obj->foo(); # get the value of child element foo
  $obj->foo("bar"); # set the value of child element foo to bar

%opts may contain C<namespace>, C<tag>, and C<filter>

Specifying C<namespace> forces MooseX::DOM to look for tags in a specific
namespace uri.

Specifying C<tag> allows MooseX::DOM to look for the tag name given in C<tag>
while making the generated method name as C<$name>

The optional C<filter> parameter should be a subroutine that takes the object 
itself as the first parameter, and the DOM node(s) as the rest of the 
parameters.  You are allowed to transform the node as you like. By default, 
a filter that converts the node to its text content is used.

  has_dom_child 'foo' => (
    filter => sub {
      my ($self, $node) = @_;
      # return whatever you want to return, perhaps transforming $node
    }
  );

The optional C<create> parameter should be a subroutine that does the
does the actual insertion of the new node, given the arguments.
By default it expects a list of text argument, and creates a child node
with those arguments.

  has_dom_child 'foo' => (
    create => sub {
      my($self, %args) = @_;
      # keys in %args:
      #   child
      #   namespace
      #   tag
      #   value
    }
  );

=head2 has_dom_children 

Specifies that the object should contain possibly multiple children by the
given name

  has_dom_children 'foo';

  $obj->foo(); # Returns a list of values for each child element foo
  $obj->foo(qw(1 2 3)); # Discards old values of foo, and create new nodes

%opts may contain C<namespace>, C<tag>, C<filter>, and C<create>

The optional C<namespace> parameter forces MooseX::DOM to look for tags in a 
specific namespace uri.

The optional C<tag> parameter allows MooseX::DOM to look for the tag name given 
in C<tag> while making the generated method name as C<$name>

The optional C<filter> parameter should be a subroutine that takes the object 
itself as the first parameter, and the DOM node(s) as the rest of the 
parameters.  You are allowed to transform the node as you like. By default, 
a filter that converts the node to its text content is used.

  has_dom_children 'foo' => (
    filter => sub {
      my ($self, @nodes) = @_;
      # return whatever you want to return, perhaps transforming @nodes
    }
  );

The optional C<create> parameter should be a subroutine that does the
does the actual insertion of the new nodes, given the arguments.
By default it expects a list of text arguments, and creates child nodes
with those arguments.

  has_dom_children 'foo' => (
    create => sub {
      my($self, %args) = @_;
      # keys in %args:
      #   children
      #   namespace
      #   tag
      #   values
    }
  );

=head2 has_dom_content $name

If your node only contains text data (that is, your root node does not have any
subsequent element nodes as its child), you can access the text data directly
with this declaration

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut