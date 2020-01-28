package Pod::Elemental;
# ABSTRACT: work with nestable Pod elements
$Pod::Elemental::VERSION = '0.103005';
use Moose;

use namespace::autoclean;

use Sub::Exporter::ForMethods ();
use Mixin::Linewise::Readers
  { installer => Sub::Exporter::ForMethods::method_installer },
  -readers;

use MooseX::Types;

use Pod::Eventual::Simple 0.004; # nonpod events
use Pod::Elemental::Document;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Objectifier;

#pod =head1 DESCRIPTION
#pod
#pod Pod::Elemental is a system for treating a Pod (L<plain old
#pod documentation|perlpod>) documents as trees of elements.  This model may be
#pod familiar from many other document systems, especially the HTML DOM.
#pod Pod::Elemental's document object model is much less sophisticated than the HTML
#pod DOM, but still makes a lot of document transformations easy.
#pod
#pod In general, you'll want to read in a Pod document and then perform a number of
#pod prepackaged transformations on it.  The most common of these will be the L<Pod5
#pod transformation|Pod::Elemental::Transformer::Pod5>, which assumes that the basic
#pod meaning of Pod commands described in the Perl 5 documentation hold: C<=begin>,
#pod C<=end>, and C<=for> commands mark regions of the document, leading whitespace
#pod marks a verbatim paragraph, and so on.  The Pod5 transformer also eliminates
#pod the need to track elements representing vertical whitespace.
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Pod::Elemental;
#pod   use Pod::Elemental::Transformer::Pod5;
#pod
#pod   my $document = Pod::Elemental->read_file('lib/Pod/Elemental.pm');
#pod
#pod   Pod::Elemental::Transformer::Pod5->new->transform_node($document);
#pod
#pod   print $document->as_debug_string, "\n"; # quick overview of doc structure
#pod
#pod   print $document->as_pod_string, "\n";   # reproduce the document in Pod
#pod
#pod =method read_handle
#pod
#pod =method read_file
#pod
#pod =method read_string
#pod
#pod These methods read the given input and return a Pod::Elemental::Document.
#pod
#pod =cut

sub read_handle {
  my ($self, $handle) = @_;
  $self = $self->new unless ref $self;

  my $events   = $self->event_reader->read_handle($handle);
  my $elements = $self->objectifier->objectify_events($events);

  my $document = $self->document_class->new({
    children => $elements,
  });

  return $document;
}

#pod =attr event_reader
#pod
#pod The event reader (by default a new instance of
#pod L<Pod::Eventual::Simple|Pod::Eventual::Simple> is used to convert input into an
#pod event stream.  In general, it should provide C<read_*> methods that behave like
#pod Pod::Eventual::Simple.
#pod
#pod =cut

has event_reader => (
  is => 'ro',
  required => 1,
  default  => sub { return Pod::Eventual::Simple->new },
);

#pod =attr objectifier
#pod
#pod The objectifier (by default a new Pod::Elemental::Objectifier) must provide an
#pod C<objectify_events> method that converts Pod events into
#pod Pod::Elemental::Element objects.
#pod
#pod =cut

has objectifier => (
  is  => 'ro',
  isa => duck_type( [qw(objectify_events) ]),
  required => 1,
  default  => sub { return Pod::Elemental::Objectifier->new },
);

#pod =attr document_class
#pod
#pod This is the class for documents created by reading pod.
#pod
#pod =cut

has document_class => (
  is       => 'ro',
  required => 1,
  default  => 'Pod::Elemental::Document',
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental - work with nestable Pod elements

=head1 VERSION

version 0.103005

=head1 SYNOPSIS

  use Pod::Elemental;
  use Pod::Elemental::Transformer::Pod5;

  my $document = Pod::Elemental->read_file('lib/Pod/Elemental.pm');

  Pod::Elemental::Transformer::Pod5->new->transform_node($document);

  print $document->as_debug_string, "\n"; # quick overview of doc structure

  print $document->as_pod_string, "\n";   # reproduce the document in Pod

=head1 DESCRIPTION

Pod::Elemental is a system for treating a Pod (L<plain old
documentation|perlpod>) documents as trees of elements.  This model may be
familiar from many other document systems, especially the HTML DOM.
Pod::Elemental's document object model is much less sophisticated than the HTML
DOM, but still makes a lot of document transformations easy.

In general, you'll want to read in a Pod document and then perform a number of
prepackaged transformations on it.  The most common of these will be the L<Pod5
transformation|Pod::Elemental::Transformer::Pod5>, which assumes that the basic
meaning of Pod commands described in the Perl 5 documentation hold: C<=begin>,
C<=end>, and C<=for> commands mark regions of the document, leading whitespace
marks a verbatim paragraph, and so on.  The Pod5 transformer also eliminates
the need to track elements representing vertical whitespace.

=head1 ATTRIBUTES

=head2 event_reader

The event reader (by default a new instance of
L<Pod::Eventual::Simple|Pod::Eventual::Simple> is used to convert input into an
event stream.  In general, it should provide C<read_*> methods that behave like
Pod::Eventual::Simple.

=head2 objectifier

The objectifier (by default a new Pod::Elemental::Objectifier) must provide an
C<objectify_events> method that converts Pod events into
Pod::Elemental::Element objects.

=head2 document_class

This is the class for documents created by reading pod.

=head1 METHODS

=head2 read_handle

=head2 read_file

=head2 read_string

These methods read the given input and return a Pod::Elemental::Document.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Christian Walde Justin Cook Karen Etheridge Philippe Bruhat (BooK)

=over 4

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Justin Cook <jcook@cray.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
