package Pod::Weaver::Section::Leftovers 4.019;
# ABSTRACT: a place to put everything that nothing else used

use Moose;
with 'Pod::Weaver::Role::Section',
     'Pod::Weaver::Role::Finalizer';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

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

  push $document->children->@*, $placeholder;
}

sub finalize_document {
  my ($self, $document, $input) = @_;

  my $children = $input->{pod_document}->children;
  $input->{pod_document}->children([]);

  INDEX: for my $i (0 .. $document->children->$#*) {
    my $para = $document->children->[$i];
    next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and    $para->format_name eq $self->_marker;

    $self->log_debug('splicing leftovers back into pod');
    splice $document->children->@*, $i, 1, @$children;
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

version 4.019

=head1 OVERVIEW

This section plugin is used to designate where in the output sequence all
unused parts of the input C<pod_document> should be placed.

Other section plugins are expected to remove from the input Pod document any
sections that are consumed.  At the end of all section weaving, the Leftovers
section will inject any leftover input Pod into its position in the output
document.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
