package Net::FTPServer::PWP::DirHandle;

# $Id: DirHandle.pm,v 1.6 2002/11/15 23:55:43 lem Exp $

use 5.00500;
use strict;

require Exporter;
use vars qw($VERSION @ISA);

use Net::FTPServer::PWP::Handle;
use Net::FTPServer::Full::DirHandle;

@ISA = qw(
	Net::FTPServer::PWP::Handle 
	Net::FTPServer::Full::DirHandle
);

=pod

=head1 NAME

Net::FTPServer::PWP::DirHandle - Specialized ::DirHandle for Net::FTPServer::PWP

=head1 SYNOPSIS

  use Net::FTPServer::PWP::DirHandle;

=head1 DESCRIPTION

This module complements C<Net::FTPServer::PWP> by encapsulating
directory-handling methods. Currently, it implements the following
methods:

=over

=cut

$VERSION = '1.10';

=pod

=item C<-E<gt>new()>

Override the C<-E<gt>new> method found in
L<Net::FTPServer::Full::DirHandle> to support hiding the mount point
of the directory for the user.

=cut

sub new {
    my $class = shift;
    my $ftps = shift;
    my $path = shift || "/";

    my $self = Net::FTPServer::Full::DirHandle->new ($ftps, $path);

				# Fix the pathname

    if ($self->{ftps}->config('hide mount point')) {
	$self->{_pathname} = $self->{ftps}->{pwp_root_dir};
	$self->{_pathname} =~ s!/+$!! if $path =~ m!^/!;
    }

    $self->{_pathname} .= $path;

#    warn "DH new pathname = $self->{_pathname}\n";

    return bless $self, $class;
}

=pod

=item C<-E<gt>get($path, $self)>

Override the C<-E<gt>get> method found in
L<Net::FTPServer::Full::DirHandle> to support hiding the mount point
of the directory for the user.

=cut

sub get {
    my $self = shift;
    my $path = shift;
    my $s = shift;

    my $h = $self->SUPER::get($path, $s);

    return undef unless $h;

    return bless $h, 'Net::FTPServer::PWP::FileHandle'
	if $h->isa('Net::FTPServer::FileHandle');

    return bless $h, 'Net::FTPServer::PWP::DirHandle'
	if $h->isa('Net::FTPServer::DirHandle');

#    warn "DH get($path, $s) = $h\n";

    return undef;
}

=pod

=item C<-E<gt>is_root>

Override the C<-E<gt>is_root> method found in
L<Net::FTPServer::Full::DirHandle> to support hiding the mount point
of the directory for the user.

=cut

sub is_root {
    my $self = shift;

    if ($self->{ftps}->config('hide mount point')) {
	return $self->{_pathname} eq $self->{ftps}->{pwp_root_dir}
    }

    return $self->SUPER::is_root();
}

=pod

=item C<-E<gt>parent>

Override the C<-E<gt>parent> method found in
L<Net::FTPServer::Full::DirHandle> to support hiding the mount point
of the directory for the user.

=cut

sub parent {
    my $self = shift;

    return $self if $self->is_root;

    bless $self->SUPER::parent(), ref $self;
}

				# This method should not be here. We should
				# use Net::FTPServer::Full::delete, but the
				# (as of this writing) version, tickles a
				# bug in (so far), Darwin's rmdir().

=pod

=item C<-E<gt>delete>

Mac OS X 10.1.5 (darwin) seems to have a bug in C<rmdir()> when
its argument ends in a slash. This method works around this limitation
by retrying the C<rmdir()> without the slash in case of failure.

=cut

sub delete
{
    my $self = shift;

				# XXX - It looks like rmdir() with a
				# trailing slash, makes some OSes sick

    unless (rmdir $self->{_pathname}) {
	my $path = $self->{_pathname};
	$path =~ s!/+$!!;
	length $path && rmdir $path or return -1;
    }

    return 0;
}

1;

__END__

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Id: DirHandle.pm,v 1.6 2002/11/15 23:55:43 lem Exp $

=over 8

=item 1.00

Original version; created by h2xs 1.21 with options

  -ACOXcfkn
	Net::FTPServer::PWP
	-v1.00
	-b
	5.5.0

=item 1.10

Inherits from L<Net::FTPServer::PWP::Handle> and from
L<Net::FTPServer::Full::FileHandle> as suggested by Rob Brown.

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<Net::FTPServer::Full>, L<Net::FTPServer>, L<perl>.

=cut
