#-*-perl-*-
#
# Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
# Copyright (c) 2001 Rob Brown <rob@roobik.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Utils.pm,v 1.6 2002/04/18 02:22:47 rob Exp $

package Net::Bind::Utils;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Carp;
use Exporter;

$VERSION = '0.05';
@ISA = qw(Exporter);
@EXPORT_OK = qw(valid_domain valid_domain_rfc1035 valid_ip valid_netmask);

=head1 NAME

Net::Bind::Utils - various routines common across Net::Bind packages.

=head1 SYNOPSIS

  use Net::Bind::Utils qw(valid_domain valid_ip);

=head1 DESCRIPTION

A catch-all place for various routines that are useful across most,
if not all, of the C<Net::Bind> interfaces.

This module is not designed to be subclassable.

=head1 ROUTINES

=head2 valid_domain($domain)

Returns C<1> if the given C<$domain> string is defined
and is a domain that bind is capable of resolving,
otherwise returns C<0>.

=cut

sub valid_domain {
  my $domain = shift;

  return 0 unless defined($domain);
  # Root domain is okay
  return 1 if $domain eq ".";
  # empty label is illegal
  return 0 if $domain =~ /\.\./;
  # Force rooting if not already done
  $domain =~ s/([^\.])$/$1./;
  # A preceeding "-" in any section is illegal
  return 0 if $domain =~ /(^|\.)\-/;
  # A trailing "-" in any section is illegal
  return 0 if $domain =~ /\-\./;
  # Make sure each section has between 1 and 63 characters
  return 1 if $domain =~ /^([a-zA-Z0-9\-]{1,63}\.)+$/;
  return 0;
}

=head2 valid_domain_rfc1035($domain)

Returns C<1> if the given C<$domain> string is defined and is a valid
rfc1035 domain name, otherwise returns C<0>.

=cut

sub valid_domain_rfc1035 {
  my $domain = shift;

  return 0 unless defined($domain);

  # from RFC1035:
  # <domain> ::= <subdomain> | " "
  # <subdomain> ::= <label> | <subdomain> "." <label>
  # <label> ::= <letter> [ [ <ldh-str> ] <let-dig> ]
  # <ldh-str> ::= <let-dig-hyp> | <let-dig-hyp> <ldh-str>
  # <let-dig-hyp> ::= <let-dig> | "-"
  # <let-dig> ::= <letter> | <digit>
  # <letter> ::= any one of the 52 alphabetic characters A through Z in
  # upper case and a through z in lower case
  # <digit> ::= any one of the ten digits 0 through 9
  my $label = '(?:[a-zA-Z](?:(?:[a-zA-Z\d\-]+)?[a-zA-Z\d])?)';
  my $dom = "(?:(?:$label\.?)*$label)";

  return ($domain =~ /^$dom$/);
}

=head2 valid_ip($ip)

Returns C<1> if the given C<$ip> string is defined and is an ip
address, otherwise returns C<0>.

The check for a valid ip address is currently very simple minded.  It
merely checks for a dotted-quad with all non-negative numbers with no
number larger than 254.

=cut

sub valid_ip {
  my $ip = shift;

  return 0 unless defined($ip);

  return 0 if ($ip !~ /^[0-9\.]+$/);
  return 0 if ($ip !~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  for my $num ($1, $2, $3, $4) { return 0 if ($num > 254) }
  return 1;
}

=head2 valid_netmask($netmask)

Returns C<1> if the given C<$netmask> string is defined and is a
netmask, otherwise return C<0>.

The check for a valid netmask is currently very simple minded.  It
merely checks for a dotted-quad with all non-negative numbers with no
number larger than 255.

=cut

sub valid_netmask {
  my $mask = shift;

  return 0 unless defined($mask);

  return 0 if ($mask !~ /^[0-9\.]+$/);
  return 0 if ($mask !~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  for my $num ($1, $2, $3, $4) { return 0 if ($num > 255) }
  return 1;
}

=head1 AUTHORS

Kevin Johnson <kjj@pobox.com>
Rob Brown <rob@roobik.com>

=head1 COPYRIGHT

Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
Copyright (c) 2001 Rob Brown <rob@roobik.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
