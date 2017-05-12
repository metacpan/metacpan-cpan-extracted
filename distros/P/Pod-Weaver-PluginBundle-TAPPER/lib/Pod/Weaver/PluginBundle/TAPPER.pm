use strict;
use warnings;

package Pod::Weaver::PluginBundle::TAPPER;
# git description: v0.001-3-g704d5fb

BEGIN {
  $Pod::Weaver::PluginBundle::TAPPER::AUTHORITY = 'cpan:TAPPER';
}
{
  $Pod::Weaver::PluginBundle::TAPPER::VERSION = '0.002';
}
# ABSTRACT: Document your modules like TAPPER does


use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

use namespace::clean;


sub mvp_bundle_config {
    return (
        [ '@TAPPER/CorePrep',  _exp('@CorePrep'),    {} ],
        [ '@TAPPER/Name',      _exp('Name'),         {} ],
        [ '@TAPPER/prelude',   _exp('Region'),       { region_name => 'prelude' } ],

        [ 'SYNOPSIS',          _exp('Generic'),      {} ],
        [ 'DESCRIPTION',       _exp('Generic'),      {} ],
        [ 'OVERVIEW',          _exp('Generic'),      {} ],

        [ 'ATTRIBUTES',        _exp('Collect'),      { command => 'attr'   } ],
        [ 'METHODS',           _exp('Collect'),      { command => 'method' } ],
        [ 'FUNCTIONS',         _exp('Collect'),      { command => 'func'   } ],
        [ 'TYPES',             _exp('Collect'),      { command => 'type'   } ],

        [ '@TAPPER/Leftovers', _exp('Leftovers'),    {} ],

        [ '@TAPPER/postlude',  _exp('Region'),       { region_name => 'postlude' } ],

        [ '@TAPPER/Authors',   _exp('Authors'),      {} ],
        [ '@TAPPER/Legal',     _exp('Legal'),        {} ],

        [ '@TAPPER/List',      _exp('-Transformer'), { transformer => 'List' } ],
        [ '@TAPPER/Encoding',  _exp('-Encoding'),    {} ],
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Pod::Weaver::PluginBundle::TAPPER - Document your modules like TAPPER does

=head1 SYNOPSIS

In weaver.ini:

  [@TAPPER]

or in dist.ini:

  [PodWeaver]
  config_plugin = @TAPPER

=head1 DESCRIPTION

This is the L<Pod::Weaver> config I use for building my
documentation. I use it via L<Dist::Zilla::PluginBundle::TAPPER>.

=head1 OVERVIEW

This plugin bundle is equivalent to the following weaver.ini file:

  [@CorePrep]

  [Name]

  [Region / prelude]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]

  [Collect / ATTRIBUTES]
  command = attr

  [Collect / METHODS]
  command = method

  [Collect / FUNCTIONS]
  command = func

  [Leftovers]

  [Region / postlude]

  [Authors]
  [Legal]

  [-Transformer]
  transformer = List

  [-Encoding]

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
