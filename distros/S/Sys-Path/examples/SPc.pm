package Acme::NewModule::SPc;

use warnings;
use strict;

our $VERSION = '0.001';

use File::Spec;

sub _path_types {qw(
	sysconfdir
	datadir
	docdir
	localedir
	cachedir
	logdir
	spooldir
	rundir
	lockdir
	sharedstatedir
	webdir
)};

sub prefix     { use Sys::Path; Sys::Path->find_distribution_root(__PACKAGE__); };
sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'conf') };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub docdir     { File::Spec->catdir(__PACKAGE__->prefix, 'doc') };
sub localedir  { File::Spec->catdir(__PACKAGE__->prefix, 'locale') };
sub cachedir   { File::Spec->catdir(__PACKAGE__->prefix, 'cache') };
sub logdir     { File::Spec->catdir(__PACKAGE__->prefix, 'log') };
sub spooldir   { File::Spec->catdir(__PACKAGE__->prefix, 'spool') };
sub rundir     { File::Spec->catdir(__PACKAGE__->prefix, 'run') };
sub lockdir    { File::Spec->catdir(__PACKAGE__->prefix, 'lock') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->prefix, 'lib') };
sub webdir     { File::Spec->catdir(__PACKAGE__->prefix, 'www') };
sub srvdir     { File::Spec->catdir(__PACKAGE__->prefix, 'srv') };

1;

__END__

=head1 NAME

Acme::NewModule::SPc - example distribution-local path configuration

=head1 DESCRIPTION

This example keeps an application's writable and read-only directories beneath
its distribution root. It illustrates an alternative to the system-wide paths
provided by C<Sys::Path::SPc>.

=head1 PATHS

=head2 _path_types

Return the ordered names of the directory accessors intended for list-driven
configuration. C<prefix> is omitted because it is discovered dynamically.

Current limitation: C<srvdir> is also omitted even though this module defines
that accessor.

=head2 prefix

Use C<Sys::Path::find_distribution_root> to locate the nearest ancestor
containing F<MANIFEST>, F<Build.PL>, or F<Makefile.PL>.

=head2 Directory accessors

=over 4

=item sysconfdir

Return the distribution root followed by F<conf>.

=item datadir

Return the distribution root followed by F<share>.

=item docdir

Return the distribution root followed by F<doc>.

=item localedir

Return the distribution root followed by F<locale>.

=item cachedir

Return the distribution root followed by F<cache>.

=item logdir

Return the distribution root followed by F<log>.

=item spooldir

Return the distribution root followed by F<spool>.

=item rundir

Return the distribution root followed by F<run>.

=item lockdir

Return the distribution root followed by F<lock>.

=item sharedstatedir

Return the distribution root followed by F<lib>.

=item webdir

Return the distribution root followed by F<www>.

=item srvdir

Return the distribution root followed by F<srv>.

=back

=cut
