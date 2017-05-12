package Acme::NewModule::SPc;

=head1 NAME

Acme::NewModule::SPc - system path configuration

=cut

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

=head1 PATHS

=over 4

=item sysconfdir

FIXME desc

=item datadir

FIXME desc

=item docdir

FIXME desc

=item localedir

FIXME desc

=item cachedir

FIXME desc

=item logdir

FIXME desc

=item spooldir

FIXME desc

=item rundir

FIXME desc

=item lockdir

FIXME desc

=item sharedstatedir

FIXME desc

=item webdir

FIXME desc

=back

=cut

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
