package Mojolicious::Plugin::Bundle;

BEGIN {
    $Mojolicious::Plugin::Bundle::VERSION = '0.004';
}
use strict;

1;

=pod

=head1 NAME

Mojolicious::Plugin::Bundle - Collection of mojolicious plugins

=head1 VERSION

version 0.004

=head1 SYNOPSIS

#In mojolicious application

  $self->plugin('yml_config');

  $self->plugin('asset_tag_helper');

  $self->plugin('bcs');

  $self->plugin('bcs-oracle');

=head1 DESCRIPTION

This distribution provides bunch of mojolicious plugins.

=over

=item *

L<YAML Config|Mojolicious::Plugin::YmlConfig>

B<YAML Config> plugin provides helper for loading yaml config file.

=item *

L<AssetTagHelpers|Mojolicious::Plugin::AssetTagHelpers>

B<AssetTagHelpers> plugin provides helpers for generating HTML links to view assets such as
images,  stylesheets and javascripts.

=item *

L<BCS|Mojolicious::Plugin::Bcs>

B<BCS> plugin provides a helper for L<Bio::Chado::Schema> module to work with
chado(genomic) database.

L<BCS-Oracle|Mojolicious::Plugin::Bcs::Oracle>

B<BCS-Oracle> is identical with I<BCS> plugin except it is specifically tuned for working
with oracle database.

=back

=over

=item For every plugin refer to its individual documentation.

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Collection of mojolicious plugins
