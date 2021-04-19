package Pod::Weaver::Section::Leftovers;
# ABSTRACT: a place to put everything that nothing else used
$Pod::Weaver::Section::Leftovers::VERSION = '4.017';
use Moose;
with(
  'Pod::Weaver::Role::Section',
  'Pod::Weaver::Role::Finalizer',
);

#pod =head1 OVERVIEW
#pod
#pod This section plugin is used to designate where in the output sequence all
#pod unused parts of the input C<pod_document> should be placed.
#pod
#pod Other section plugins are expected to remove from the input Pod document any
#pod sections that are consumed.  At the end of all section weaving, the Leftovers
#pod section will inject any leftover input Pod into its position in the output
#pod document.
#pod
#pod =cut

use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Types qw(FormatName);

has _marker => (
  is  => 'ro',
  isa => FormatName,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    my $str = sprintf '%s_%s', ref($self), 0+$self;
    $str =~ s/\W/_/g;

    return $str;
  }
);

sub weave_section {
  my ($self, $document, $input) = @_;

  my $placeholder = Pod::Elemental::Element::Pod5::Region->new({
    is_pod      => 0,
    format_name => $self->_marker,
    content     => '',
  });

  push @{ $document->children }, $placeholder;
}

sub finalize_document {
  my ($self, $document, $input) = @_;

  my $children = $input->{pod_document}->children;
  $input->{pod_document}->children([]);

  INDEX: for my $i (0 .. @{ $document->children } - 1) {
    my $para = $document->children->[$i];
    next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and    $para->format_name eq $self->_marker;

    $self->log_debug('splicing leftovers back into pod');
    splice @{ $document->children }, $i, 1, @$children;
    last INDEX;
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Leftovers - a place to put everything that nothing else used

=head1 VERSION

version 4.017

=head1 OVERVIEW

This section plugin is used to designate where in the output sequence all
unused parts of the input C<pod_document> should be placed.

Other section plugins are expected to remove from the input Pod document any
sections that are consumed.  At the end of all section weaving, the Leftovers
section will inject any leftover input Pod into its position in the output
document.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
