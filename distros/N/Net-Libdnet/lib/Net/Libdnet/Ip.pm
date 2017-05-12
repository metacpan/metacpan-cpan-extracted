#
# $Id: Ip.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Ip;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:ip);

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_ip_open()
      or die("Ip::new: unable to open");
   $self->_handle($handle);
   $self;
}

sub checksum {
   my $self  = shift;
   my ($buf) = @_;
   dnet_ip_checksum($buf, length($buf));
}

sub send {
   my $self  = shift;
   my ($buf) = @_;
   dnet_ip_send($self->_handle, $buf, length($buf));
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_ip_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Ip - high level API to access libdnet ip_* functions

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<checksum>

=item B<send>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
