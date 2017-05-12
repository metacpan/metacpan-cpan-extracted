use strict;
use warnings;

package Pod::Weaver::PluginBundle::AMD;
# git description: v0.001-2-g1c145c4

BEGIN {
  $Pod::Weaver::PluginBundle::AMD::AUTHORITY = 'cpan:AMD';
}
{
  $Pod::Weaver::PluginBundle::AMD::VERSION = '4.1.0';
}
# ABSTRACT: Document your modules like AMD does



use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

use namespace::clean;


sub mvp_bundle_config {
    return (
        [ '@AMD/CorePrep',  _exp('@CorePrep'),    {} ],
        [ '@AMD/Name',      _exp('Name'),         {} ],
        [ '@AMD/prelude',   _exp('Region'),       { region_name => 'prelude' } ],

        [ 'SYNOPSIS',         _exp('Generic'),      {} ],
        [ 'DESCRIPTION',      _exp('Generic'),      {} ],
        [ 'OVERVIEW',         _exp('Generic'),      {} ],

        [ 'ATTRIBUTES',       _exp('Collect'),      { command => 'attr'   } ],
        [ 'METHODS',          _exp('Collect'),      { command => 'method' } ],
        [ 'FUNCTIONS',        _exp('Collect'),      { command => 'func'   } ],
        [ 'TYPES',            _exp('Collect'),      { command => 'type'   } ],

        [ '@AMD/Leftovers', _exp('Leftovers'),    {} ],

        [ '@AMD/postlude',  _exp('Region'),       { region_name => 'postlude' } ],

        [ '@AMD/Authors',   _exp('Authors'),      {} ],
        [ '@AMD/Legal',     _exp('Legal'),        {} ],

        [ '@AMD/List',      _exp('-Transformer'), { transformer => 'List' } ],
        [ '@AMD/Encoding',  _exp('-Encoding'),    {} ],
    );
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Pod::Weaver::PluginBundle::AMD - Document your modules like AMD does

=head1 SYNOPSIS

In weaver.ini:

  [@AMD]

or in dist.ini:

  [PodWeaver]
  config_plugin = @AMD

=head1 DESCRIPTION

This is the L<Pod::Weaver> config I use for building my
documentation. I use it via L<Dist::Zilla::PluginBundle::AMD>.

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

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

