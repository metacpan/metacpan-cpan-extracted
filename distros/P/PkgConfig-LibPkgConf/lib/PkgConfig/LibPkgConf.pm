package PkgConfig::LibPkgConf;

use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.08';
our @EXPORT = qw(
  pkgconf_cflags
  pkgconf_libs
  pkgconf_exists
  pkgconf_version
  pkgconf_cflags_static
  pkgconf_libs_static
);

=head1 NAME

PkgConfig::LibPkgConf - Interface to .pc file interface via libpkgconf

=head1 SYNOPSIS

 use PkgConfig::LibPkgConf;
 
 if(pkgconf_exists('libarchive'))
 {
   my $version = pkgconf_version('libarchive');
   my $cflags  = pkgconf_cflags('libarchive');
   my $libs    = pkgconf_libs('libarchive');
 }

=head1 DESCRIPTION

Many libraries in compiled languages such as C or C++ provide C<.pc> 
files to specify the flags required for compiling and linking against 
those libraries.  Traditionally, the command line program C<pkg-config> 
is used to query these files.  This module provides a Perl level API
using C<libpkgconf> to these files.

This module provides a simplified interface for getting the existence,
version, cflags and library flags needed for compiling against a package,
using the default compiled in configuration of C<pkgconf>.  For a more
powerful, but complicated interface see L<PkgConfig::LibPkgConf::Client>.
In addition, L<PkgConfig::LibPkgConf::Util> provides some useful utility
functions that are also provided by C<pkgconf>.

=head1 FUNCTIONS

=head2 pkgconf_exists

 my $bool = pkgconf_exists $package_name;

Returns true if the package is available.

Exported by default.

=cut

sub pkgconf_exists
{
  my $pkg = eval { _pkg($_[0]) };
  return defined $pkg;
}

=head2 pkgconf_version

 my $version = pkgconf_version $package_name;

Returns the version of the package, if it exists.  Will throw an exception
if not found.

Exported by default.

=cut

sub pkgconf_version
{
  my $pkg = _pkg($_[0]);
  $pkg->version;
}

=head2 pkgconf_cflags

 my $cflags = pkgconf_cflags $package_name;

Returns the compiler flags for the package, if it exists.  Will throw an
exception if not found.

Exported by default.

=cut

sub pkgconf_cflags
{
  my $pkg = _pkg($_[0]);
  $pkg->cflags;
}

=head2 pkgconf_cflags_static

 my $cflags = pkgconf_cflags_static $package_name;

Returns the static compiler flags for the package, if it exists.  Will throw
an exception if not found.

=cut

sub pkgconf_cflags_static
{
  my $pkg = _pkg($_[0]);
  $pkg->cflags_static;  
}

=head2 pkgconf_libs

 my $libs = pkgconf_libs $package_name;

Returns the linker library flags for the package, if it exists.  Will throw
an exception if not found.

Exported by default.

=cut

sub pkgconf_libs
{
  my $pkg = _pkg($_[0]);
  $pkg->libs;
}

=head2 pkgconf_libs_static

 my $libs = pkgconf_libs_static $package_name;

Returns the static linker library flags for the package, if it exists.  Will
throw an exception if not found.

=cut

sub pkgconf_libs_static
{
  my $pkg = _pkg($_[0]);
  $DB::single = 1;
  $pkg->libs_static;  
}

sub _pkg
{
  my($name) = @_;
  require PkgConfig::LibPkgConf::Client;
  my $pkg = PkgConfig::LibPkgConf::Client->new->find($name);
  die "package $name not found" unless $pkg;
  $pkg;
}

1;

=head1 SUPPORT

IRC #native on irc.perl.org

Project GitHub tracker:

L<https://github.com/plicease/PkgConfig-LibPkgConf/issues>

If you want to contribute, please open a pull request on GitHub:

L<https://github.com/plicease/PkgConfig-LibPkgConf/pulls>

=head1 SEE ALSO

The best entry point to the low level C<pkgconf> interface can be found 
via L<PkgConfig::LibPkgConf::Client>.

Alternatives include:

=over 4

=item L<PkgConfig>

Pure Perl implementation of C<pkg-config> which can be used from the 
command line, or as an API from Perl.  Does not require pkg-config in 
your path, so is a safe dependency for CPAN modules.

=item L<ExtUtils::PkgConfig>

Wrapper for the C<pkg-config> command line interface.  This module will 
fail to install if C<pkg-config> cannot be found in the C<PATH>, so it 
is not safe to use a dependency if you want your CPAN module to work on 
platforms where C<pkg-config> is not installed.

=item L<Alien::Base>

Provides tools for building non-Perl libraries and making them 
dependencies for your CPAN modules, even on platforms where the non-Perl 
libraries aren't already installed.  Includes hooks for probing 
C<pkg-config> C<.pc> files using either C<pkg-config> or L<PkgConfig>.

=back

=head1 ACKNOWLEDGMENTS

Thanks to the C<pkgconf> developers for their efforts:

L<https://github.com/pkgconf/pkgconf/graphs/contributors>

=head1 AUTHOR

Graham Ollis 

Contributors:

A. Wilcox (awilfox)

Petr Pisar (ppisar)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under 
the same terms as the Perl 5 programming language system itself.

=cut
