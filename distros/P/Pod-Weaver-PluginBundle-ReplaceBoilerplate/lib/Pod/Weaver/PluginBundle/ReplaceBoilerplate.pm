package Pod::Weaver::PluginBundle::ReplaceBoilerplate;

# ABSTRACT: A Pod::Weaver bundle for replacing the boilerplate in a Pod document.

use strict;
use warnings;

use namespace::autoclean;

our $VERSION = '1.00';

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  return (
    [ '@ReplaceBoilerplate/CorePrep',         _exp('@CorePrep'),        {} ],
    [ '@ReplaceBoilerplate/ReplaceName',      _exp('ReplaceName'),      {} ],
    [ '@ReplaceBoilerplate/ReplaceVersion',   _exp('ReplaceVersion'),   {} ],

    [ '@ReplaceBoilerplate/Leftovers',        _exp('Leftovers'),        {} ],

    [ '@ReplaceBoilerplate/ReplaceAuthors',   _exp('ReplaceAuthors'),   {} ],
    [ '@ReplaceBoilerplate/ReplaceLegal',     _exp('ReplaceLegal'),     {} ],
  )
}

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::ReplaceBoilerplate - A Pod::Weaver bundle for replacing the boilerplate in a Pod document.

=head1 VERSION

version 1.00

=head1 OVERVIEW

This is a plugin bundle intended to replace use of [@Default] with equivilent
behaviour but with L<Pod::Weaver::Role::SectionReplacer> enabled plugins.

It is nearly equivalent to the following:

  [@CorePrep]

  [ReplaceName]
  [ReplaceVersion]

  [Leftovers]

  [ReplaceAuthors]
  [ReplaceLegal]

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=end readme

=for readme stop

=begin :internal

=head1 INTERNAL METHODS

=over

=item mvp_bundle_config

Returns the config data structure to substitute for this PluginBundle.

=back

=end :internal

=for readme continue

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

  perldoc Pod::Weaver::PluginBundle::ReplaceBoilerplate

You can also look for information at:

=over

=item RT, CPAN's request tracker

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-PluginBundle-ReplaceBoilerplate

=item AnnoCPAN, Annotated CPAN documentation

http://annocpan.org/dist/Pod-Weaver-PluginBundle-ReplaceBoilerplate

=item CPAN Ratings

http://cpanratings.perl.org/d/Pod-Weaver-PluginBundle-ReplaceBoilerplate

=item Search CPAN

http://search.cpan.org/dist/Pod-Weaver-PluginBundle-ReplaceBoilerplate/

=back

=head1 AUTHOR

Sam Graham <libpod-weaver-pluginbundle-replaceboilerplate-perl BLAHBLAH illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sam Graham <libpod-weaver-pluginbundle-replaceboilerplate-perl BLAHBLAH illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
