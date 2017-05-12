package Net::FTPServer::PWP::FileHandle;

# $Id: FileHandle.pm,v 1.5 2002/11/15 23:55:43 lem Exp $

use 5.00500;
use strict;

require Exporter;
use vars qw($VERSION @ISA);

use Net::FTPServer::PWP::Handle;
use Net::FTPServer::Full::FileHandle;

@ISA = qw(Net::FTPServer::PWP::Handle Net::FTPServer::Full::FileHandle);

$VERSION = '1.00';

=pod

=head1 NAME

Net::FTPServer::PWP::FileHandle - Specialized ::FileHandle for Net::FTPServer::PWP

=head1 SYNOPSIS

  use Net::FTPServer::PWP::FileHandle;

=head1 DESCRIPTION

This module complements C<Net::FTPServer::PWP> by encapsulating
eventual file-handling methods.

=over

=back

=head2 EXPORT

None by default.

=head1 METHODS

None

=cut

1;

__END__

=pod

=head1 HISTORY

$Id: FileHandle.pm,v 1.5 2002/11/15 23:55:43 lem Exp $

=over 8

=item 1.00

Original version; created by h2xs 1.21 with options

  -ACOXcfkn
	Net::FTPServer::PWP
	-v1.00
	-b
	5.5.0

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<Net::FTPServer::Full>, L<Net::FTPServer>, L<perl>.

=cut
