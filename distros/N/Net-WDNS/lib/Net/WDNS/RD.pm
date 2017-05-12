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

package Net::WDNS::RD;

use strict;
use warnings;

use Net::WDNS qw(:func);

use overload ( '""' => \&as_str );

use constant RDATA   => 0;
use constant RRCLASS => 1;
use constant RRTYPE  => 2;

sub new {
  my($class, $rdata, $rrtype, $rrclass) = @_;
  bless [$rdata, $rrtype, $rrclass], $class;
}

sub rrclass { rrclass_to_str(shift->[RRCLASS]) }
sub rrtype  { rrtype_to_str (shift->[RRTYPE] ) }

sub rrclass_num { shift->[RRCLASS] }
sub rrtype_num  { shift->[RRTYPE]  }
sub rdata_raw   { shift->[RDATA]   }

sub as_str {
  my $self = shift;
  rdata_to_str($self->[RDATA], $self->[RRTYPE], $self->[RRCLASS]);
}

###############################################################################

1;

__END__

=pod

=head1 NAME

Net::WDNS::RD - Perl interface for libwdns rdata

=head1 SYNOPSIS

  use Net::WDNS;

  ...

  my $msg = parse_message($pkt);
  for my $rr ($msg->answer) {
    for my $rd ($rr->rdata) {
      print $rd->as_str, "\n";
    }
  }

=head1 DESCRIPTION

Net::WDNS::RD is an object interface to the rdata portions
of dns messages.

=head1 CONSTRUCTOR

=over 4

=item new($rdata, $rrtype, $rrclass)

Creates a new Net::WDNS::RD object from raw rdata, numeric rrtype,
and numeric rrclass. This should never have to be called directly as
rdata objects are provided the Net::WDNS::RR objects.

=back

=head1 METHODS

=over 4

=item rrclass()

Return the string version of the rrclass of this rdata.

=item rrtype()

Return the string version of the rrtype of this rdata.

=item rrclass_num()

Return the numeric rrclass of this rdata.

=item rrtype_num()

Return the numeric rrtype of this rdata.

=item rdata_raw()

Return the raw (wire-formatted) rdata.

=item as_str()

Return a human-readable string representing the rdata. Objects
are also overloaded to render as strings when double-quoted.

=back

=head1 SEE ALSO

L<Net::WDNS>, L<Net::WDNS::Msg>, L<Net::WDNS::RR>, L<Net::Nmsg>

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
