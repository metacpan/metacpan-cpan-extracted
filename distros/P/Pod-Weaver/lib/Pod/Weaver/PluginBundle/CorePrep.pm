use strict;
use warnings;
package Pod::Weaver::PluginBundle::CorePrep 4.018;
# ABSTRACT: a bundle for the most commonly-needed prep work for a pod document

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use Pod::Weaver::Plugin::H1Nester;

sub mvp_bundle_config {
  return (
    [ '@CorePrep/EnsurePod5', 'Pod::Weaver::Plugin::EnsurePod5', {} ],
    # dialects should run here
    [ '@CorePrep/H1Nester',   'Pod::Weaver::Plugin::H1Nester',   {} ],
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::CorePrep - a bundle for the most commonly-needed prep work for a pod document

=head1 VERSION

version 4.018

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
