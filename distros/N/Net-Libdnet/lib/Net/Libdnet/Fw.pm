#
# $Id: Fw.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Fw;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:fw :consts);

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_fw_open() or die("Fw::new: unable to open");
   $self->_handle($handle);
   $self;
}

#
# block out eth1 tcp 127.0.0.1:4000-4100 127.0.0.2:4300-4400
# block out eth1 icmp 127.0.0.1:4000-4100 127.0.0.2:4300-4400 0/0
#
sub _to_hash {
   my ($rule) = @_;
   my @toks = split(/ +/, $rule);
   my ($op, $dir, $device, $proto, $src, $dst, $sport, $dport, $type, $code);
   my $srcOk;
   for (@toks) {
         if (/^block$|^allow$/i)   { $op    = $_ }
      elsif (/^in$|^out$/i)        { $dir   = $_ }
      elsif (/^tcp$|^udp$|^icmp$/) { $proto = $_ }
      elsif (!$srcOk && /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
         my @src = split(/:/);
         $src = $src[0] if defined($src[0]);
         if (defined($src[1])) {
            my @port = split(/-/, $src[1]);
            push @$sport, $port[0] if defined($port[0]);
            push @$sport, $port[1] if defined($port[1]);
         }
         $srcOk++;
      }
      elsif ($srcOk && /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
         my @dst = split(/:/);
         $dst = $dst[0] if defined($dst[0]);
         if (defined($dst[1])) {
            my @port = split(/-/, $dst[1]);
            push @$dport, $port[0] if defined($port[0]);
            push @$dport, $port[1] if defined($port[1]);
         }
      }
      else {
         $device  = $_;
      }
   }
   if (defined($op)) {
         if ($op =~ /block/i) { $op = DNET_FW_OP_BLOCK }
      elsif ($op =~ /allow/i) { $op = DNET_FW_OP_ALLOW }
   }
   if (defined($dir)) {
         if ($dir =~ /in/i)  { $dir = DNET_FW_DIR_IN  }
      elsif ($dir =~ /out/i) { $dir = DNET_FW_DIR_OUT }
   }
   if (defined($proto)) {
         if ($proto =~ /tcp/i)  { $proto = 0x06 }
      elsif ($proto =~ /udp/i)  { $proto = 0x11 }
      elsif ($proto =~ /icmp/i) { $proto = 0x01 }
   }
   my $h = {
      fw_device => $device || 'any',
      fw_op     => $op     || DNET_FW_OP_BLOCK,
      fw_dir    => $dir    || DNET_FW_DIR_IN,
      fw_proto  => $proto  || 0,
      fw_src    => $src    || '0.0.0.0/0',
      fw_dst    => $dst    || '0.0.0.0/0',
      fw_sport  => $sport  || [0, 0],
      fw_dport  => $dport  || [0, 0],
   };
}

sub add {
   my $self   = shift;
   my ($rule) = @_;
   dnet_fw_add($self->_handle, _to_hash($rule));
}

sub delete {
   my $self   = shift;
   my ($rule) = @_;
   dnet_fw_delete($self->_handle, _to_hash($rule));
}

sub loop {
   my $self         = shift;
   my ($sub, $data) = @_;
   dnet_fw_loop($self->_handle, $sub, $data || \'');
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_fw_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Fw - high level API to access libdnet fw_* functions

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<add>

=item B<delete>

=item B<loop>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
