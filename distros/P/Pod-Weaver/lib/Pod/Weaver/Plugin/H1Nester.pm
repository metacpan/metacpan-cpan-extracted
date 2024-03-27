package Pod::Weaver::Plugin::H1Nester 4.020;
# ABSTRACT: structure the input pod document into head1-grouped sections

use Moose;
with 'Pod::Weaver::Role::Transformer';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;

#pod =head1 OVERVIEW
#pod
#pod This plugin is very, very simple:  it uses the
#pod L<Pod::Elemental::Transformer::Nester> to restructure the document under its
#pod C<=head1> elements.
#pod
#pod =cut

sub transform_document {
  my ($self, $document) = @_;

  my $nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(head1) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(head2 head3 head4 over item back) ]),
    ],
  });

  $nester->transform_node($document);

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::H1Nester - structure the input pod document into head1-grouped sections

=head1 VERSION

version 4.020

=head1 OVERVIEW

This plugin is very, very simple:  it uses the
L<Pod::Elemental::Transformer::Nester> to restructure the document under its
C<=head1> elements.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
