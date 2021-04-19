package Pod::Weaver::Section::Generic;
# ABSTRACT: a generic section, found by lifting sections
$Pod::Weaver::Section::Generic::VERSION = '4.017';
use Moose;
with 'Pod::Weaver::Role::Section';

use v5.20.0;
use experimental 'postderef'; # this experiment succeeded -- rjbs, 2021-04-02

#pod =head1 OVERVIEW
#pod
#pod This section will find and include a located hunk of Pod.  In general, it will
#pod find a C<=head1> command with a content of the plugin's name.
#pod
#pod In other words, if your configuration include:
#pod
#pod   [Generic]
#pod   header = OVERVIEW
#pod
#pod ...then this weaver will look for "=head1 OVERVIEW" and include it at the
#pod appropriate location in your output.
#pod
#pod Since you'll probably want to use Generic several times, and that will require
#pod giving each use a unique name, you can omit C<header> if you provide a
#pod plugin name, and it will default to the plugin name.  In other words, the
#pod configuration above could be specified just as:
#pod
#pod   [Generic / OVERVIEW]
#pod
#pod If the C<required> attribute is given, and true, then an exception will be
#pod raised if this section can't be found.
#pod
#pod =cut

use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Selectors -all;

#pod =attr required
#pod
#pod A boolean value specifying whether this section is required to be present or not. Defaults
#pod to false.
#pod
#pod If it's enabled and the section can't be found an exception will be raised.
#pod
#pod =cut

has required => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =attr header
#pod
#pod The name of this section. Defaults to the plugin name.
#pod
#pod =cut

has header => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default => sub { $_[0]->plugin_name },
);

has selector => (
  is  => 'ro',
  isa => 'CodeRef',
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    return sub {
      return unless s_command(head1 => $_[0]);
      return unless $_[0]->content eq $self->header;
    };
  },
);

sub weave_section {
  my ($self, $document, $input) = @_;

  my $in_node = $input->{pod_document}->children;

  my @found = grep {
    $self->selector->($in_node->[$_]);
  } (0 .. $#$in_node);

  confess "Couldn't find required Generic section for " . $self->header . " in file "
    . (defined $input->{filename} ? $input->{filename} : '') if $self->required and not @found;

  $self->log_debug('adding ' . $self->header . ' back into pod');

  push $document->children->@*, map { splice @$in_node, $_, 1 } reverse @found;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Generic - a generic section, found by lifting sections

=head1 VERSION

version 4.017

=head1 OVERVIEW

This section will find and include a located hunk of Pod.  In general, it will
find a C<=head1> command with a content of the plugin's name.

In other words, if your configuration include:

  [Generic]
  header = OVERVIEW

...then this weaver will look for "=head1 OVERVIEW" and include it at the
appropriate location in your output.

Since you'll probably want to use Generic several times, and that will require
giving each use a unique name, you can omit C<header> if you provide a
plugin name, and it will default to the plugin name.  In other words, the
configuration above could be specified just as:

  [Generic / OVERVIEW]

If the C<required> attribute is given, and true, then an exception will be
raised if this section can't be found.

=head1 ATTRIBUTES

=head2 required

A boolean value specifying whether this section is required to be present or not. Defaults
to false.

If it's enabled and the section can't be found an exception will be raised.

=head2 header

The name of this section. Defaults to the plugin name.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
