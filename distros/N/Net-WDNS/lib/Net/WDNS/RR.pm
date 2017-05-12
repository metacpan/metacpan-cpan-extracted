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

package Net::WDNS::RR;

use strict;
use warnings;

use Net::WDNS qw(:func);

use overload ( '""' => \&as_str );

use constant NAME    => 0;
use constant RRCLASS => 1;
use constant RRTYPE  => 2;
use constant RRTTL   => 3;
use constant RDATA   => 4;

sub new {
  my($class, $name, $rrclass, $rrtype, $rrttl, @rdata) = @_;
  bless [$rrclass, $rrtype, $rrttl, @rdata], $class;
}

sub name    { domain_to_str (shift->[NAME] )   }
sub rrclass { rrclass_to_str(shift->[RRCLASS]) }
sub rrtype  { rrtype_to_str (shift->[RRTYPE] ) }

sub name_raw    { shift->[NAME]    }
sub rrclass_num { shift->[RRCLASS] }
sub rrtype_num  { shift->[RRTYPE]  }

sub rrttl   { shift->[RRTTL] }
*rrttl_raw = \&rrttl;

sub rdata   {
  my $self = shift;
  wantarray ? @{$self}[RDATA..$#$self] : [@{$self}[RDATA..$#$self]];
}

sub as_str {
  my $self = shift;
  my $prefix = sprintf(
    "%s %d %s %s ",
    domain_to_str ($self->[NAME]),
    $self->[RRTTL],
    rrclass_to_str($self->[RRCLASS]),
    rrtype_to_str ($self->[RRTYPE]),
  );
  join("\n", map { $prefix . $_->as_str() } @{$self}[RDATA..$#$self]);
}

###############################################################################

1;

__END__

=pod

=head1 NAME

Net::WDNS::RR - Perl interface for libwdns resource records

=head1 SYNOPSIS

  use Net::WDNS;

  ...

  my $msg = parse_message($pkt);
  for my $rr ($msg->answer) {
    print $rr->as_str, "\n";
  }

=head1 DESCRIPTION

Net::WDNS::RR is an object interface to the resource records
of dns messages.

=head1 CONSTRUCTOR

=over 4

=item new($name, $rrclass, $rrtype, $rrttl, @rdata)

Creates a new Net::WDNS::RR record from a raw (wire-format)
domain name, rrclass, rrtype, rrttl, and rdata entries. This
should never have to be called directly as record objects
are provided the Net::WDNS::Msg objects.

=back

=head1 METHODS

=over 4

=item name()

Return the human-readable string version of the domain name
of this record.

=item rrclass()

Return the string version of the rrclass of this record.

=item rrtype()

Return the string version of the rrtype of this record.

=item rrttl()

Return the TTL value of this record.

=item rdata()

Return as a list (array ref in scalar context) of the rdata
portions of the record as Net::WDNS::RD objects.

=item name_raw()

Return the raw (wire format) domain name of this record.

=item rrclass_num()

Return the numeric rrclass of this record.

=item rrtype_num()

Return the numeric rrtype of this record.

=item as_str()

Return a human-readable string representing the record. Objects
are also overloaded to render as strings when double-quoted.

=back

=head1 SEE ALSO

L<Net::WDNS>, L<Net::WDNS::Msg>, L<Net::WDNS::Question>, L<Net::WDNS::RD>, L<Net::Nmsg>

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
