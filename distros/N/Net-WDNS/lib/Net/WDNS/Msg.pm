# Copyright (C) 2014 by Carnegie Mellon University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, as published by
# the Free Software Foundation, under the terms pursuant to Version 2,
# June 1991.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

package Net::WDNS::Msg;

use strict;
use warnings;

use Net::WDNS qw(:func);

# need to use these to set up their namespaces (WDNS.xs blesses
# references into them regardless of whether they've been loaded)
use Net::WDNS::Msg;
use Net::WDNS::Question;
use Net::WDNS::RR;
use Net::WDNS::RD;

use overload ( '""' => \&as_str );
 
use constant MSG        => 0;
use constant ID         => 1;
use constant FLAGS      => 2;
use constant RCODE      => 3;
use constant OPCODE     => 4;
use constant QUESTION   => 5;
use constant ANSWER     => 6;
use constant AUTHORITY  => 7;
use constant ADDITIONAL => 8;

sub new {
  my($class, $pkt) = @_;
  my $msg = parse_message_raw($pkt);
  bless [$msg], $class;
}

sub msg { shift->[MSG] }

sub id {
  my $self = shift;
  $self->[ID] ||= get_id($self->[MSG]);
}

sub flags_raw { get_flags(shift->[MSG]) }

sub flags {
  my $self = shift;
  if (! $self->[FLAGS]) {
    my %decode;
    my $flags = $self->flags_raw;
    $decode{qr} = ($flags >> 15) & 0x01;
    $decode{aa} = ($flags >> 10) & 0x01;
    $decode{tc} = ($flags >>  9) & 0x01;
    $decode{rd} = ($flags >>  8) & 0x01;
    $decode{ra} = ($flags >>  7) & 0x01;
    $decode{ad} = ($flags >>  5) & 0x01;
    $decode{cd} = ($flags >>  4) & 0x01;
    $self->[FLAGS] = \%decode;
  }
  wantarray ? %{$self->[FLAGS]} : $self->[FLAGS];
}

sub rcode_num {
  my $self = shift;
  if (! defined $self->[RCODE]) {
    $self->[RCODE] = get_rcode($self->[MSG]);
  }
  $self->[RCODE];
}

sub opcode_num {
  my $self = shift;
  if (! defined $self->[OPCODE]) {
    $self->[OPCODE] = get_opcode($self->[MSG]);
  }
  $self->[OPCODE];
}

sub rcode { rcode_to_str(shift->rcode_num) }

sub opcode { opcode_to_str(shift->opcode_num) }

sub question {
  my $self = shift;
  $self->[QUESTION] ||= Net::WDNS::get_section($self->[MSG], 0);
  wantarray ? @{$self->[QUESTION]} : $self->[QUESTION];
}

sub answer {
  my $self = shift;
  $self->[ANSWER] ||= Net::WDNS::get_section($self->[MSG], 1);
  wantarray ? @{$self->[ANSWER]} : $self->[ANSWER];
}

sub authority {
  my $self = shift;
  $self->[AUTHORITY] ||= Net::WDNS::get_section($self->[MSG], 2);
  wantarray ? @{$self->[AUTHORITY]} : $self->[AUTHORITY];
}

sub additional {
  my $self = shift;
  $self->[ADDITIONAL] ||= Net::WDNS::get_section($self->[MSG], 3);
  wantarray ? @{$self->[ADDITIONAL]} : $self->[ADDITIONAL];
}

sub as_str { message_to_str(shift->[MSG]) }

sub DESTROY { clear_message(shift->[MSG]) }

###############################################################################

1;

__END__

=pod

=head1 NAME

Net::WDNS::Msg - Perl interface for libwdns messages

=head1 SYNOPSIS

  use Net::WDNS qw(:func);

  ... # get raw DNS packet

  my $msg = parse_message($pkt);
  print $msg->as_str, "\n";

=head1 DESCRIPTION

Net::WDNS::Msg is an object interface to libwdns messages that
allows introspection and rendering as human-readable strings.

=head1 CONSTRUCTOR

=over 4

=item new($pkt)

Creates a new Net::WDNS::Msg object from a raw (wire-format) DNS packet.
A slightly faster way to get message objects is to use the C<parse_message()>
function provided by Net::WDNS.

=back

=head1 METHODS

=over 4

=item id()

Return the numeric id of this message.

=item flags()

Return a hash of flags and their statuses (0 or 1) for this message.
Flags include qr, aa, tc, rd, ra, ad, and cd.

=item flags_raw()

Return the raw bit-encoded integer reprenting the flags.

=item rcode()

Return the string version of the rcode.

=item rcode_num()

Return the numeric rcode.

=item opcode()

Return the string version of the rcode.

=item opcode_num()

Return the numeric opcode.

=item question()

Return the QUESTION section of this message as an array (array ref
in scalar context) containing Net::WDNS::Question objects.

=item answer()

Return the ANSWER section of this message as an array (array ref in
scalar context) containing Net::WDNS::RR objects.

=item authority()

Return the AUTHORITY section of this message as an array (array ref in
scalar context) containing Net::WDNS::RR objects.

=item additional()

Return the ADDITIONAL section of this message as an array (array ref in
scalar context) containing Net::WDNS::RR objects.

=item as_str()

Return a human-readable string representing this message. Message objects
are also overloaded to render as strings when double-quoted.

=item msg()

Return the underlying raw message structure, suitable for passing to
some utility functions provided by Net::WDNS.

=back

=head1 SEE ALSO

L<Net::WDNS>, L<Net::WDNS::Question>, L<Net::WDNS::RR>, L<Net::Nmsg>

The wdns library can be downloaded from: https://github.com/farsightsec/wdns

=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Carnegie Mellon University

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, as published by
the Free Software Foundation, under the terms pursuant to Version 2,
June 1991.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

=cut
