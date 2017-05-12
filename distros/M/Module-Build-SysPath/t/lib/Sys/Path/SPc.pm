package Sys::Path::SPc;

=head1 NAME

Sys::Path::SPc - mock for testing

=cut

use warnings;
use strict;

our $VERSION = '0.14';

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

sub prefix        { File::Spec->catdir('/', 'usr') };
sub localstatedir { File::Spec->catdir('/', 'var') };

sub sysconfdir { File::Spec->catdir('/', 'etc') };
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
sub srvdir     { File::Spec->catdir('/', 'srv') };

1;
