package Sys::Path::SPc;

use warnings;
use strict;

our $VERSION = '0.16';

use File::Spec;

sub _path_types {qw(
	prefix
	localstatedir
	sysconfdir
	datadir
	docdir
	cachedir
	logdir
	spooldir
	rundir
	lockdir
	localedir
	sharedstatedir
	webdir
	srvdir
)};

# Accessor names follow GNU autoconf installation-directory variables.
use Config;                                                  # remove after install
my $prefix = $Config::Config{'prefix'};                      # remove after install
my $localstatedir =                                          # remove after install
	$Config::Config{'prefix'} eq '/usr'                      # remove after install
	? '/var'                                                 # remove after install
	: File::Spec->catdir($Config::Config{'prefix'}, 'var')   # remove after install
;                                                            # remove after install
my $sysconfdir =                                             # remove after install
	$Config::Config{'prefix'} eq '/usr'                      # remove after install
	? '/etc'                                                 # remove after install
	: File::Spec->catdir($Config::Config{'prefix'}, 'etc')   # remove after install
;                                                            # remove after install
my $srvdir =                                                 # remove after install
	$Config::Config{'prefix'} eq '/usr'                      # remove after install
	? '/srv'                                                 # remove after install
	: File::Spec->catdir($Config::Config{'prefix'}, 'srv')   # remove after install
;                                                            # remove after install

sub prefix        { shift; $prefix = $_[0] if @_; return $prefix; };
sub localstatedir { shift; $localstatedir = $_[0] if @_; return $localstatedir; };

sub sysconfdir { shift; $sysconfdir = $_[0] if @_; return $sysconfdir; };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub docdir     { File::Spec->catdir(__PACKAGE__->prefix, 'share', 'doc') };
sub localedir  { File::Spec->catdir(__PACKAGE__->prefix, 'share', 'locale') };
sub cachedir   { File::Spec->catdir(__PACKAGE__->localstatedir, 'cache') };
sub logdir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'log') };
sub spooldir   { File::Spec->catdir(__PACKAGE__->localstatedir, 'spool') };
sub rundir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'run') };
sub lockdir    { File::Spec->catdir(__PACKAGE__->localstatedir, 'lock') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->localstatedir, 'lib') };
sub webdir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'www') };
sub srvdir     { shift; $srvdir = $_[0] if @_; return $srvdir; };

1;


__END__

=head1 NAME

Sys::Path::SPc - store build-time installation paths

=head1 PATHS

This module defines the path accessors documented in L<Sys::Path/PATHS>. In a
source checkout, C<prefix>, C<localstatedir>, C<sysconfdir>, and C<srvdir>
accept a new value; the remaining accessors derive their values from those base
paths and ignore arguments.

During C<perl Build.PL>, C<inc::MyBuilder> replaces every accessor in the built
copy with a constant containing the selected path. Consequently, accessors in
an installed copy ignore arguments and cannot be reconfigured at runtime.

=head2 _path_types

Return the ordered accessor names used by the build configuration.

=head2 prefix

Return C<prefix>; see L<Sys::Path/prefix>.

=head2 localstatedir

Return C<localstatedir>; see L<Sys::Path/localstatedir>.

=head2 sysconfdir

Return C<sysconfdir>; see L<Sys::Path/sysconfdir>.

=head2 datadir

Return C<datadir>; see L<Sys::Path/datadir>.

=head2 docdir

Return C<docdir>; see L<Sys::Path/docdir>.

=head2 localedir

Return C<localedir>; see L<Sys::Path/localedir>.

=head2 cachedir

Return C<cachedir>; see L<Sys::Path/cachedir>.

=head2 logdir

Return C<logdir>; see L<Sys::Path/logdir>.

=head2 spooldir

Return C<spooldir>; see L<Sys::Path/spooldir>.

=head2 rundir

Return C<rundir>; see L<Sys::Path/rundir>.

=head2 lockdir

Return C<lockdir>; see L<Sys::Path/lockdir>.

=head2 sharedstatedir

Return C<sharedstatedir>; see L<Sys::Path/sharedstatedir>.

=head2 webdir

Return C<webdir>; see L<Sys::Path/webdir>.

=head2 srvdir

Return C<srvdir>; see L<Sys::Path/srvdir>.

=head1 AUTHOR

Jozef Kutej

=cut
