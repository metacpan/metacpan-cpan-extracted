#
# $Id: Intf.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Intf;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS = qw(
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:intf);
use Net::Libdnet::Entry::Intf;

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_intf_open() or die("Intf::new: unable to open");
   $self->_handle($handle);
   return $self;
}

sub get {
   my $self   = shift,
   my ($intf) = @_;
   my $h = dnet_intf_get($self->_handle, { intf_name => $intf })
      or return;
   return Net::Libdnet::Entry::Intf->newFromHash($h);
}

sub getSrc {
   my $self  = shift,
   my ($src) = @_;
   my $h = dnet_intf_get_src($self->_handle, $src)
      or return;
   return Net::Libdnet::Entry::Intf->newFromHash($h);
}

sub getDst {
   my $self  = shift,
   my ($dst) = @_;
   my $h = dnet_intf_get_dst($self->_handle, $dst)
      or return;
   return Net::Libdnet::Entry::Intf->newFromHash($h);
}

sub getSrcIntfFromDst {
   my $self = shift;
   my ($dst) = @_;
   my $e = $self->getDst($dst) or return;
   return $e->name;
}

sub getSrcIpFromDst {
   my $self = shift;
   my ($dst) = @_;
   my $e = $self->getDst($dst) or return;
   return $e->addr;
}

sub set {
   my $self = shift;
   my ($entry) = @_;
   my $r = dnet_intf_set($self->_handle, $entry)
      or return;
   return $self;
}

sub loop {
   my $self         = shift;
   my ($sub, $data) = @_;
   dnet_intf_loop($self->_handle, $sub, $data || \'');
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_intf_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Intf - high level API to access libdnet intf_* functions

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<get>

=item B<getSrc>

=item B<getDst>

=item B<set>

=item B<loop>

=back

=over 4

=item B<getSrcIntfFromDst>

=item B<getSrcIpFromDst>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
