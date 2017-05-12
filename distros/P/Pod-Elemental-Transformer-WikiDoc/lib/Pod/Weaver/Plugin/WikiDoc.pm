package Pod::Weaver::Plugin::WikiDoc;

use Moose;
with 'Pod::Weaver::Role::Dialect';
# ABSTRACT: allow wikidoc-format regions to be translated during dialect phase

our $VERSION = '0.093004';

#pod =head1 OVERVIEW
#pod
#pod This plugin is an exceedingly thin wrapper around
#pod L<Pod::Elemental::Transformer::WikiDoc>.  When you load this plugin, then
#pod C<=begin> and C<=for> regions with the C<wikidoc> format will be translated to
#pod standard Pod5 before further weaving continues.
#pod
#pod =cut

use namespace::autoclean;

use Pod::Elemental::Transformer::WikiDoc;

sub translate_dialect {
  my ($self, $pod_document) = @_;

  Pod::Elemental::Transformer::WikiDoc->new->transform_node($pod_document);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::WikiDoc - allow wikidoc-format regions to be translated during dialect phase

=head1 VERSION

version 0.093004

=head1 OVERVIEW

This plugin is an exceedingly thin wrapper around
L<Pod::Elemental::Transformer::WikiDoc>.  When you load this plugin, then
C<=begin> and C<=for> regions with the C<wikidoc> format will be translated to
standard Pod5 before further weaving continues.

=for Pod::Coverage translate_dialect

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
