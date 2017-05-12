package Net::FTPServer::PWP::Handle;

# $Id: Handle.pm,v 1.1 2002/11/15 23:55:43 lem Exp $


use 5.00500;
use strict;

use vars qw($VERSION @ISA);

use Net::FTPServer::Handle;

#@ISA = qw(Net::FTPServer::Handle);

$VERSION = '1.00';

=pod

=head1 NAME

Net::FTPServer::PWP::Handle - Base class for Net::FTPServer::PWP file or dir handles

=head1 SYNOPSIS

  use Net::FTPServer::PWP::Handle;

=head1 DESCRIPTION

This is the base class for C<Net::FTPServer::PWP::FileHandle> and
C<Net::FTPServer::PWP::DirHandle>.

=over

=back

=head2 EXPORT

None by default.

=head1 METHODS

The following methods are defined. Note that these override the
methods found in L<Net::FTPServer::Full>.

=over 4

=item C<-E<gt>pathname()>

Returns the pathname of the handle. If the mount point must be hidden
from the user, it is automatically removed.

=cut

sub pathname {
    my $self = shift;

#    warn "pathname = $self->{_pathname}\n";

    if ($self->{ftps}->config('hide mount point')) {
	return substr($self->{_pathname}, 
		      length($self->{ftps}->{pwp_root_dir}) - 1);
    }

    return $self->{_pathname};
}

1;
__END__

=pod

=back

=head1 HISTORY

$Id: Handle.pm,v 1.1 2002/11/15 23:55:43 lem Exp $

=over 8

=item 1.00

Introduces the capability of blocking access outside the PWP home
directory. This module was written as a suggestion by Rob Brown.

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<Net::FTPServer::Full>, L<Net::FTPServer>, L<perl>.

=cut
