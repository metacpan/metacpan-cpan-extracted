package Pod::Elemental::Element::Pod5::Region;
# ABSTRACT: a region of Pod (this role likely to be removed)
$Pod::Elemental::Element::Pod5::Region::VERSION = '0.103005';
use Moose;
with qw(
  Pod::Elemental::Paragraph
  Pod::Elemental::Node
  Pod::Elemental::Command
);

#pod =head1 WARNING
#pod
#pod This class is somewhat sketchy and may be refactored somewhat in the future,
#pod specifically to refactor its similarities to
#pod L<Pod::Elemental::Element::Nested>.
#pod
#pod =head1 OVERVIEW
#pod
#pod A Pod5::Region element represents a region marked by a C<=for> command or a
#pod pair of C<=begin> and C<=end> commands.  It may have content of its own as well
#pod as child paragraphs.
#pod
#pod Its C<as_pod_string> method will emit either a C<=begin/=end>-enclosed string
#pod or a C<=for> command, based on whichever is permissible.
#pod
#pod =cut

use Pod::Elemental::Types qw(FormatName);
use MooseX::Types::Moose qw(Bool);

#pod =attr format_name
#pod
#pod This is the format to which the region was targeted.  
#pod
#pod B<Note!>  The format name should I<not> include the leading colon to indicate a
#pod pod paragraph.  For that, see C<L</is_pod>>.
#pod
#pod =cut

has format_name => (is => 'ro', isa => FormatName, required => 1);

#pod =attr is_pod
#pod
#pod If true, this region contains pod (ordinary or verbatim) paragraphs, as opposed
#pod to data paragraphs.  This will generally result from the document originating
#pod in a C<=begin> block with a colon-prefixed target identifier:
#pod
#pod   =begin :html
#pod
#pod     This is still a verbatim paragraph.
#pod
#pod   =end :html
#pod
#pod =cut

has is_pod => (is => 'ro', isa => Bool, required => 1, default => 1);

sub command         { 'begin' }
sub closing_command { 'end' }

sub _display_as_for {
  my ($self) = @_;

  # Everything after "=for target" becomes the lone child paragraph, so there
  # is nowhere to put the (technically illegal) content. -- rjbs, 2009-11-24
  return if $self->content =~ /\S/;

  # We can't have more than one paragraph, because there'd be a blank, so we
  # couldn't round trip. -- rjbs, 2009-11-24
  return if @{ $self->children } != 1;

  my $child = $self->children->[0];

  return if $child->content =~ m{^\s*$}m;

  my $base = 'Pod::Elemental::Element::Pod5::';
  return 1 if   $self->is_pod and $child->isa("${base}Ordinary");
  return 1 if ! $self->is_pod and $child->isa("${base}Data");

  return;
}

sub as_pod_string {
  my ($self) = @_;

  my $string;

  if ($self->_display_as_for) {
    $string = $self->__as_pod_string_for($self);
  } else {
    $string = $self->__as_pod_string_begin($self);
  }

  $string =~ s/\n*\z//g;

  return $string;
}

sub __as_pod_string_begin {
  my ($self) = @_;

  my $content = $self->content;
  my $colon   = $self->is_pod ? ':' : '';

  my $string = sprintf "=%s %s%s\n",
    $self->command,
    $colon . $self->format_name,
    ($content =~ /\S/ ? " $content\n" : "\n");

  $string .= join(q{}, map { $_->as_pod_string } @{ $self->children });

  $string .= "\n\n"
    if  @{ $self->children }
    and $self->children->[-1]->isa( 'Pod::Elemental::Element::Pod5::Data');
    # Pod5::$self->is_pod; # XXX: HACK!! -- rjbs, 2009-10-21

  $string .= sprintf "=%s %s",
    $self->closing_command,
    $colon . $self->format_name;

  return $string;
}

sub __as_pod_string_for {
  my ($self) = @_;

  my $content = $self->content;
  my $colon = $self->is_pod ? ':' : '';

  my $string = sprintf "=for %s %s",
    $colon . $self->format_name,
    $self->children->[0]->as_pod_string;

  return $string;
}

sub as_debug_string {
  my ($self) = @_;

  my $colon = $self->is_pod ? ':' : '';

  my $string = sprintf "=%s %s",
    $self->command,
    $colon . $self->format_name;

  return $string;
}

with 'Pod::Elemental::Autoblank';
with 'Pod::Elemental::Autochomp';

# BEGIN Autochomp Replacement
use Pod::Elemental::Types qw(ChompedString);
has '+content' => (coerce => 1, isa => ChompedString);
# END   Autochomp Replacement

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Pod5::Region - a region of Pod (this role likely to be removed)

=head1 VERSION

version 0.103005

=head1 OVERVIEW

A Pod5::Region element represents a region marked by a C<=for> command or a
pair of C<=begin> and C<=end> commands.  It may have content of its own as well
as child paragraphs.

Its C<as_pod_string> method will emit either a C<=begin/=end>-enclosed string
or a C<=for> command, based on whichever is permissible.

=head1 ATTRIBUTES

=head2 format_name

This is the format to which the region was targeted.  

B<Note!>  The format name should I<not> include the leading colon to indicate a
pod paragraph.  For that, see C<L</is_pod>>.

=head2 is_pod

If true, this region contains pod (ordinary or verbatim) paragraphs, as opposed
to data paragraphs.  This will generally result from the document originating
in a C<=begin> block with a colon-prefixed target identifier:

  =begin :html

    This is still a verbatim paragraph.

  =end :html

=head1 WARNING

This class is somewhat sketchy and may be refactored somewhat in the future,
specifically to refactor its similarities to
L<Pod::Elemental::Element::Nested>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
