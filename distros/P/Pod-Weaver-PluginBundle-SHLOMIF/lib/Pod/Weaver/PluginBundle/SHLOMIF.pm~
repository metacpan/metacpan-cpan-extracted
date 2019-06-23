use strict;
use warnings;

package Pod::Weaver::PluginBundle::SHLOMIF;

our $VERSION = '0.0010000';

use Pod::Weaver 4; # he played knick-knack on my door
use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Elemental::Transformer::List 0.102000 ();
use Pod::Elemental::PerlMunger 0.200001        (); # replace with comment support
use Pod::Weaver::Section::Support 1.001        ();
use Pod::Weaver::Section::Contributors 0.008   ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

my $repo_intro = <<'END';
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
END

my $bugtracker_content = <<'END';
Please report any bugs or feature requests through the issue tracker
at {WEB}.
You will be notified automatically of any progress on your issue.
END

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        [ '@SHLOMIF/SingleEncoding', _exp('-SingleEncoding'), {} ],
        [ '@SHLOMIF/WikiDoc',        _exp('-WikiDoc'),        {} ],
        [ '@SHLOMIF/CorePrep',       _exp('@CorePrep'),       {} ],
        [ '@SHLOMIF/Name',           _exp('Name'),            {} ],
        [ '@SHLOMIF/Version',        _exp('Version'),         {} ],

        [ '@SHLOMIF/Prelude',     _exp('Region'),  { region_name => 'prelude' } ],
        [ '@SHLOMIF/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS' } ],
        [ '@SHLOMIF/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
        [ '@SHLOMIF/Usage',       _exp('Generic'), { header      => 'USAGE' } ],
        [ '@SHLOMIF/Overview',    _exp('Generic'), { header      => 'OVERVIEW' } ],
        [ '@SHLOMIF/Stability',   _exp('Generic'), { header      => 'STABILITY' } ],
    );

    for my $plugin (
        [ 'Requirements', _exp('Collect'), { command => 'requires' } ],
        [ 'Attributes',   _exp('Collect'), { command => 'attr' } ],
        [ 'Constructors', _exp('Collect'), { command => 'construct' } ],
        [ 'Methods',      _exp('Collect'), { command => 'method' } ],
        [ 'Functions',    _exp('Collect'), { command => 'func' } ],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins,
      (
        [ '@SHLOMIF/Leftovers', _exp('Leftovers'), {} ],
        [ '@SHLOMIF/postlude', _exp('Region'), { region_name => 'postlude' } ],
        [
            '@SHLOMIF/Support',
            _exp('Support'),
            {
                all_modules => 1,
                perldoc     => 0,
            }
        ],
        [ '@SHLOMIF/Authors',      _exp('Authors'),      {} ],
        [ '@SHLOMIF/Bugs',         _exp('Bugs'),         {} ],
        [ '@SHLOMIF/Contributors', _exp('Contributors'), {} ],
        [ '@SHLOMIF/Legal',        _exp('Legal'),        {} ],
        [ '@SHLOMIF/List', _exp('-Transformer'), { 'transformer' => 'List' } ],
      );

    return @plugins;
}

# ABSTRACT: SHLOMIF's default Pod::Weaver config
# COPYRIGHT

1;

=for Pod::Coverage mvp_bundle_config

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-WikiDoc]

  [@Default]

  [Support]
  perldoc = 0
  websites = none
  bugs = metadata
  bugs_content = ... stuff (web only, email omitted) ...
  repository_link = both
  repository_content = ... stuff ...

  [Contributors]

  [-Transformer]
  transformer = List

=head1 USAGE

This PluginBundle is used automatically with the C<@DAGOLDEN> L<Dist::Zilla>
plugin bundle.

It also has region collectors for:

=for :list
* requires
* construct
* attr
* method
* func

=head1 SEE ALSO

=for :list
* L<Pod::Weaver>
* L<Pod::Weaver::Plugin::WikiDoc>
* L<Pod::Elemental::Transformer::List>
* L<Pod::Weaver::Section::Contributors>
* L<Pod::Weaver::Section::Support>
* L<Dist::Zilla::Plugin::PodWeaver>

=cut
