package Sys::Path::Example1::SPc;

=head1 NAME

Sys::Path::Example1::SPc - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use File::Spec;

sub _path_types {qw(
	prefix
    localstatedir
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
    srvdir
)};

=head1 PATHS

=head2 prefix

=head2 localstatedir

=head2 sysconfdir

=head2 datadir

=head2 docdir

=head2 localedir

=head2 cachedir

=head2 logdir

=head2 spooldir

=head2 rundir

=head2 lockdir

=head2 sharedstatedir

=head2 webdir

=head2 srvdir

=cut

sub prefix        { use Sys::Path; Sys::Path->find_distribution_root(__PACKAGE__); };
sub localstatedir { __PACKAGE__->prefix };

sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub docdir     { File::Spec->catdir(__PACKAGE__->prefix, 'doc') };
sub localedir  { File::Spec->catdir(__PACKAGE__->prefix, 'locale') };
sub cachedir   { File::Spec->catdir(__PACKAGE__->localstatedir, 'cache') };
sub logdir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'log') };
sub spooldir   { File::Spec->catdir(__PACKAGE__->localstatedir, 'spool') };
sub rundir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'run') };
sub lockdir    { File::Spec->catdir(__PACKAGE__->localstatedir, 'lock') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->localstatedir, 'state') };
sub webdir     { File::Spec->catdir(__PACKAGE__->localstatedir, 'www') };
sub srvdir     { File::Spec->catdir(__PACKAGE__->prefix, 'srv') };

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
