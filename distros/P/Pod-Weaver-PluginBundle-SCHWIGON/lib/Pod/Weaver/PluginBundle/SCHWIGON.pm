use strict;
use warnings;

package Pod::Weaver::PluginBundle::SCHWIGON;
# git description: v0.002-3-g3228faa

BEGIN {
  $Pod::Weaver::PluginBundle::SCHWIGON::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Document your modules like SCHWIGON does
$Pod::Weaver::PluginBundle::SCHWIGON::VERSION = '0.003';
# (well actually like FLORA - as it is shamelessly stolen)

use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

use namespace::clean;


sub mvp_bundle_config {
    return (
        [ '@SCHWIGON/CorePrep',  _exp('@CorePrep'),    {} ],
        [ '@SCHWIGON/Name',      _exp('Name'),         {} ],
        [ '@SCHWIGON/prelude',   _exp('Region'),       { region_name => 'prelude' } ],

        [ 'SYNOPSIS',         _exp('Generic'),      {} ],
        [ 'DESCRIPTION',      _exp('Generic'),      {} ],
        [ 'OVERVIEW',         _exp('Generic'),      {} ],

        [ 'ATTRIBUTES',       _exp('Collect'),      { command => 'attr'   } ],
        [ 'METHODS',          _exp('Collect'),      { command => 'method' } ],
        [ 'FUNCTIONS',        _exp('Collect'),      { command => 'func'   } ],
        [ 'TYPES',            _exp('Collect'),      { command => 'type'   } ],

        [ '@SCHWIGON/Leftovers', _exp('Leftovers'),    {} ],

        [ '@SCHWIGON/postlude',  _exp('Region'),       { region_name => 'postlude' } ],

        [ '@SCHWIGON/Authors',   _exp('Authors'),      {} ],
        [ '@SCHWIGON/Legal',     _exp('Legal'),        {} ],

        [ '@SCHWIGON/List',           _exp('-Transformer'),    { transformer => 'List' } ],
        [ '@SCHWIGON/SingleEncoding', _exp('-SingleEncoding'), {} ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::SCHWIGON - Document your modules like SCHWIGON does

=head1 SYNOPSIS

In weaver.ini:

  [@SCHWIGON]

or in dist.ini:

  [PodWeaver]
  config_plugin = @SCHWIGON

=head1 DESCRIPTION

This is the L<Pod::Weaver> config I use for building my
documentation. I use it via L<Dist::Zilla::PluginBundle::SCHWIGON>.

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

  [-SingleEncoding]

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
