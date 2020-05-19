package PkgConfig::LibPkgConf::Util;

use strict;
use warnings;
use base qw( Exporter );
use PkgConfig::LibPkgConf::XS;

our $VERSION = '0.11';
our @EXPORT_OK = qw( argv_split compare_version path_sep path_relocate );

=head1 NAME

PkgConfig::LibPkgConf::Util - Non OO functions for PkgConfig::LibPkgConf

=head1 SYNOPSIS

 use PkgConfig::LibPkgConf::Util qw( argv_split compare_version );
 
 my @args = argv_split('-L/foo -lfoo'); # ('-L/foo', '-lfoo');
 my $cmp  = compare_version('1.2.3','1.2.4');

=head1 DESCRIPTION

This module provides some useful utility functions that come along with
C<libpkgconf>, but are not object oriented and thus do not get their own
class.

=head1 FUNCTIONS

=head2 argv_split

 my @argv = argv_split $args;

Splits a string into an argument list.

=head2 compare_version

 my $cmp = compare_version($version1, $version2);

Compare versions using RPM version comparison rules as described in the LSB.
Returns -1 if the first version is greater, 0 if both versions are equal,
1 if the second version is greater.

=head2 path_relocate

 my $path = path_relocate($path);

Relocates a path, possibly calling realpath() or cygwin_conv_path() on it.

=head2 path_sep

 my $sep = path_sep;

Returns the path separator as understood by C<pkgconf>.  This is usually
C<:> on UNIX and C<;> on Windows.

=head1 SUPPORT

IRC #native on irc.perl.org

Project GitHub tracker:

L<https://github.com/plicease/PkgConfig-LibPkgConf/issues>

If you want to contribute, please open a pull request on GitHub:

L<https://github.com/plicease/PkgConfig-LibPkgConf/pulls>

=head1 SEE ALSO

For additional related modules, see L<PkgConfig::LibPkgConf>

=head1 AUTHOR

Graham Ollis

For additional contributors see L<PkgConfig::LibPkgConf>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
