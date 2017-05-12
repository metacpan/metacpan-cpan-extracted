#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Pod/Weaver/PluginBundle/Author/VDB.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Pod-Weaver-PluginBundle-Author-VDB.
#
#   perl-Pod-Weaver-PluginBundle-Author-VDB is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Pod-Weaver-PluginBundle-Author-VDB is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Pod-Weaver-PluginBundle-Author-VDB. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =head1 DESCRIPTION
#pod
#pod It is unlikely that someone else will want to use it, so I will not bother with documenting it, at
#pod least for now.
#pod
#pod =cut

package Pod::Weaver::PluginBundle::Author::VDB;

use strict;
use warnings;
use namespace::autoclean;
use version 0.77;

# PODNAME: Pod::Weaver::PluginBundle::Author::VDB
# ABSTRACT: VDB's plugin bundle
our $VERSION = 'v0.3.4'; # VERSION

use Pod::Weaver::Config::Assembler;

#   `AutoPrereqs` hints:
use Pod::Weaver::PluginBundle::CorePrep qw{};
use Pod::Weaver::Plugin::SingleEncoding qw{};
use Pod::Weaver::Plugin::Transformer    qw{};
use Pod::Weaver::Section::Authors       qw{};
use Pod::Weaver::Section::Collect       qw{};
use Pod::Weaver::Section::Generic       qw{};
use Pod::Weaver::Section::Leftovers     qw{};
use Pod::Weaver::Section::Legal         qw{};
use Pod::Weaver::Section::Name          qw{};
use Pod::Weaver::Section::Region        qw{};
use Pod::Weaver::Section::Version       qw{};
use Pod::Elemental::Transformer::List   qw{};

sub _p($) {
    my ( $pkg ) = @_;
    return Pod::Weaver::Config::Assembler->expand_package( $pkg );
};

#pod =for Pod::Coverage mvp_bundle_config
#pod
#pod =cut

sub mvp_bundle_config {

    my $me = '@Author::VDB';

    my $authors   = _p( 'Authors'   );
    my $collect   = _p( 'Collect'   );
    my $generic   = _p( 'Generic'   );
    my $leftovers = _p( 'Leftovers' );
    my $legal     = _p( 'Legal'     );
    my $name      = _p( 'Name'      );
    my $region    = _p( 'Region'    );
    my $version   = _p( 'Version'   );

    return (
        #   Plugins and other stuff.
        [ "$me/CorePrep",           _p( '@CorePrep'       ), {} ],
        [ "$me/SingleEncoding",     _p( '-SingleEncoding' ), {} ],
        [ "$me/Transformer",        _p( '-Transformer'    ), {
            'transformer' => 'List',
        } ],
        #   Sections
        [ "$me/Name",               $name,      {} ],
        [ "$me/Version",            $version,   {
            'format' => [
                'Version %v, released on %{yyyy-MM-dd HH:mm zzz}d.',
                '%T This is a B<trial release>.',
            ],
        } ],
        [ 'WHAT?',                  $generic,   {} ],
        [ "$me/this",               $region,    { region_name => 'this'          } ],
        [ "$me/that",               $region,    { region_name => 'that'          } ],
        [ "$me/those",              $region,    { region_name => 'those'         } ],
        #   Special processing for `=for test_synopsis` directives.
        #   By default `Pod::Weaver` moves them to the end of the weaved document (to the
        #   leftovers). However, `Test::Synopsis` v0.14 wants this directive is located *before*
        #   synopsis section.
        [ "$me/test_synopsis",      $region,    { region_name => 'test_synopsis',
            allow_nonpod => 1,      # Do not require colon in fron of format name.
            flatten      => 0,      # Do not drop `=for` directive, write whole region as-is.
        } ],
        [ 'SYNOPSIS',               $generic,   {} ],
        [ 'DESCRIPTION',            $generic,   {} ],
        [ 'EXPORT',                 $generic,   {} ],
        [ 'CONSTANTS',              $collect,   { command => 'const'             } ],
        [ 'CLASS METHODS',          $collect,   { command => 'Method'            } ],
        [ 'OBJECT ATTRIBUTES',      $collect,   { command => 'attr'              } ],
        [ 'OBJECT METHODS',         $collect,   { command => 'method'            } ],
        [ 'FUNCTIONS',              $collect,   { command => 'func'              } ],
        [ 'OPERATORS',              $collect,   { command => 'operator'          } ],
        [ 'VARIABLES',              $collect,   { command => 'variable'          } ],
        [ 'OPTIONS',                $collect,   { command => 'option'            } ],
        [ 'RETURN VALUE',           $generic,   {} ],
        [ 'ERRORS',                 $generic,   {} ],
        [ 'EXAMPLES',               $collect,   { command => 'example'           } ],
        [ 'ENVIRONMENT',            $generic,   {} ],
        [ 'FILES',                  $generic,   {} ],
        [ 'CAVEATS',                $collect,   { command => 'caveat'            } ],
        [ 'KNOWN BUGS',             $collect,   { command => 'bug'               } ],
        [ 'RESTRICTIONS',           $generic,   {} ],
        [ 'NOTES',                  $collect,   { command => 'note'              } ],
        [ 'WHY?',                   $generic,   {} ],
        [ "$me/Leftovers",          $leftovers, {} ],
        [ 'GLOSSARY',               $generic,   {} ],
        [ 'SEE ALSO',               $generic,   {} ],
        [ "$me/Authors",            $authors,   {} ],
        [ 'HISTORY',                $generic,   {} ],
        [ 'COPYRIGHT AND LICENSE',  $generic,   {} ],
    );

};

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Pod-Weaver-PluginBundle-Author-VDB.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Pod-Weaver-PluginBundle-Author-VDB> (or just C<@Author::VDB>) is a C<Pod::Weaver> plugin bundle used by VDB.
#pod
#pod =cut

# end of file #
#   ------------------------------------------------------------------------------------------------
#
#   file: doc/why.pod
#
#   This file is part of perl-Pod-Weaver-PluginBundle-Author-VDB.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod I have published few distributions on CPAN. Every distribution has F<weaver.ini> file. All the
#pod F<weaver.ini> files are exactly the same. Maintaining multiple F<weaver.ini> files is boring.
#pod Plugin bundle solves the problem.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::VDB - VDB's plugin bundle

=head1 VERSION

Version v0.3.4, released on 2016-12-19 22:30 UTC.

=head1 WHAT?

C<Pod-Weaver-PluginBundle-Author-VDB> (or just C<@Author::VDB>) is a C<Pod::Weaver> plugin bundle used by VDB.

=head1 DESCRIPTION

It is unlikely that someone else will want to use it, so I will not bother with documenting it, at
least for now.

=head1 WHY?

I have published few distributions on CPAN. Every distribution has F<weaver.ini> file. All the
F<weaver.ini> files are exactly the same. Maintaining multiple F<weaver.ini> files is boring.
Plugin bundle solves the problem.

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
