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

package Net::WDNS::Question;

use strict;
use warnings;

use Net::WDNS qw(:func);

use overload ( '""' => \&as_str );

use constant NAME    => 0;
use constant RRCLASS => 1;
use constant RRTYPE  => 2;

sub new {
  my($class, $name, $rrclass, $rrtype) = @_;
  my $self = [$name, $rrclass, $rrtype];
  bless $self, $class;
}

sub name    { domain_to_str (shift->[NAME] )   }
sub rrclass { rrclass_to_str(shift->[RRCLASS]) }
sub rrtype  { rrtype_to_str (shift->[RRTYPE] ) }

sub name_raw    { shift->[NAME]    }
sub rrclass_num { shift->[RRCLASS] }
sub rrtype_num  { shift->[RRTYPE]  }

sub as_str {
  my $self = shift;
  sprintf("%s %s %s",
    domain_to_str ($self->[NAME]),
    rrclass_to_str($self->[RRCLASS]),
    rrtype_to_str ($self->[RRTYPE]),
  );
}

###############################################################################

1;

__END__

=pod

=head1 NAME

Net::WDNS::Question - Perl interface for libwdns question records

=head1 SYNOPSIS

  use Net::WDNS;

  ...

  my $msg = parse_message($pkt);
  for my $q ($msg->question) {
    print $q->as_str, "\n";
  }

=head1 DESCRIPTION

Net::WDNS::Question is an object interface to to the question
record of dns messages.

=head1 CONSTRUCTOR

=over 4

=item new($name, $rrclass, $rrtype)

Creates a new Net::WDNS::Question record from a raw (wire-format)
domain name, numeric rrclass and numeric rrtype. This should never
have to be called directly as question objects are provided by
Net::WDNS::Msg objects.

=back

=head1 METHODS

=over 4

=item name()

Return the human-readable string version of the domain name
of this query.

=item rrclass()

Return the string version of the rrclass of this query.

=item rrtype()

Return the string version of the rrtype of this query.

=item name_raw()

Return the raw (wire format) domain name of this query.

=item rrclass_num()

Return the numeric rrclass of this query.

=item rrtype_num()

Return the numeric rrtype of this query.

=item as_str()

Return a human-readable string representing the question. Objects
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
