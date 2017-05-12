package Net::SNMP::Mixin::Util;

use strict;
use warnings;

#
# this module import config
#
use Net::SNMP ();

#
# this module export config
#
use Sub::Exporter -setup =>
  { exports => [qw/idx2val hex2octet normalize_mac push_error get_init_slot/],
  };

=head1 NAME

Net::SNMP::Mixin::Util - helper class for Net::SNMP mixins

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

A helper class for Net::SNMP mixins.

  use Net::SNMP::Mixin::Util qw/idx2val hex2octet normalize_mac/;

=head1 EXPORTS

The following routines are exported by request:

=over 2

=item B<< idx2val($var_bind_list, $base_oid, [$pre], [$tail]) >> 

convert a var_bind_list into a index => value form,
removing the base_oid from oid.

e.g. if base_oid is '1.3.6.1.2.1.17.1.4.1.2',
convert from:
 
  '1.3.6.1.2.1.17.1.4.1.2.1' => 'foo'
  '1.3.6.1.2.1.17.1.4.1.2.2' => 'bar'

to:

  '1' => 'foo'
  '2' => 'bar'
  
or if base_oid is '1.0.8802.4.1.1.12' and pre == 1 and tail == 2,
convert from:

  '1.0.8802.4.1.1.12.0.10.0.0.2.99.185' => 'foo',
  '1.0.8802.4.1.1.12.0.10.0.0.3.99.186' => 'bar',
  '1.0.8802.4.1.1.12.0.10.0.0.4.99.187' => 'baz',
  ^                 ^ ^        ^      ^    ^     ^
  |.....base_oid....|.|.index..|.tail.|    |value|
                     ^
  pre ---------------|

to:

  '10.0.0.2' => 'foo',
  '10.0.0.3' => 'bar',
  '10.0.0.4' => 'baz',

Returns the hash reference with index => value. Dies on error.

=cut

sub idx2val {
  my ( $var_bind_list, $base_oid, $pre, $tail ) = @_;

  die "missing attribute 'var_bind_list'," unless defined $var_bind_list;
  die "missing attribute 'base_oid',"      unless defined $base_oid;

  $pre  ||= 0;
  $tail ||= 0;

  die "wrong format for 'pre',"  if $pre < 0;
  die "wrong format for 'tail'," if $tail < 0;

  my $idx;
  my $idx2val = {};
  foreach my $oid ( keys %$var_bind_list ) {
    next unless Net::SNMP::oid_base_match( $base_oid, $oid );

    $idx = $oid;

    # cutoff leading and trailing whitespace, bloody SNMP agents!
    $idx =~ s/^\s*//;
    $idx =~ s/\s*$//;

    # cutoff the basoid, get the idx
    $idx =~ s/^$base_oid//;

    # if the idx isn't at the front of the index
    # cut off the n fold pre
    $idx =~ s/^\.?(\d+\.?){$pre}// if $pre > 0;

    # if the idx isn't at the end of the oid
    # cut off the n fold tail
    $idx =~ s/(\d+\.?){$tail}$// if $tail > 0;

    # cut off remaining dangling '.'
    $idx =~ s/^\.//;
    $idx =~ s/\.$//;

    $idx2val->{$idx} = $var_bind_list->{$oid};
  }
  return $idx2val;
}

=item B<< hex2octet($hex_string) >>

Sometimes it's importend that the returned SNMP values were untranslated by Net::SNMP. If already translated, we must reconvert it to pure OCTET_STRINGs for some calculations. Returns the input parameter untranslated if it's no string in the form /^0x[0-9a-f]+$/i .

=cut

sub hex2octet {
  my $hex_string = shift;

  # don't touch, it's no hex_string
  return $hex_string unless $hex_string =~ m/^0x[0-9a-f]+$/i;

  # remove '0x' in front
  $hex_string = substr( $hex_string, 2 );

  # return octet_string
  return pack 'H*', $hex_string;
}

=item B<< normalize_mac($mac_address) >>

normalize MAC addresses to the IEEE form XX:XX:XX:XX:XX:XX

    normalize the different formats like,

              x:xx:x:xx:Xx:xx     to XX:XX:XX:XX:XX:XX
    or        xxxxxx-xxxxxx       to XX:XX:XX:XX:XX:XX
    or        xx-xx-xx-xx-xx-xx   to XX:XX:XX:XX:XX:XX
    or        xxxx.xxxx.xxxx      to XX:XX:XX:XX:XX:XX
    or     0x xxxxxxxxxxxx        to XX:XX:XX:XX:XX:XX
    or     plain packed '6C'      to XX:XX:XX:XX:XX:XX

or returns undef for format errors.

=cut

sub normalize_mac {
  my ($mac) = @_;
  return unless defined $mac;

  # translate this OCTET_STRING to hexadecimal, unless already translated
  if ( length $mac == 6 ) {
    $mac = unpack 'H*', $mac;
  }

  # to upper case
  my $norm_address = uc($mac);

  # remove '-' in bloody Microsoft format
  $norm_address =~ s/-//g;

  # remove '.' in bloody Cisco format
  $norm_address =~ s/\.//g;

  # remove '0X' in front of, we are already upper case
  $norm_address =~ s/^0X//;

  # we are already upper case
  my $hex_digit = qr/[A-F,0-9]/;

  # insert leading 0 in bloody Sun format
  $norm_address =~ s/\b($hex_digit)\b/0$1/g;

  # insert ':' aabbccddeeff -> aa:bb:cc:dd:ee:ff
  $norm_address =~ s/($hex_digit{2})(?=$hex_digit)/$1:/g;

  # wrong format
  return unless $norm_address =~ m /^($hex_digit{2}:){5}$hex_digit{2}$/;

  return $norm_address;
}

=item B<< push_error($session, $error_msg) >>

Net::SNMP has only one slot for errors. During nonblocking calls it's possible that an error followed by a successful transaction is cleared before the user gets the chance to see the error. At least for the mixin modules we use an array buffer for all seen errors until they are explicit cleared.

This utility routine helps the mixin authors to push an error into the buffer without the knowledge of the buffer internas.

Dies if session isn't a Net::SNMP object or error_msg is missing.

=cut

sub push_error {
  my ( $session, $error_msg ) = @_;

  die "missing attribute 'session',"   unless defined $session;
  die "missing attribute 'error_msg'," unless defined $error_msg;

  die "'session' isn't a Net::SNMP object,"
    unless ref $session && $session->isa('Net::SNMP');

  # prepare the error buffer if not already done
  $session->{'Net::SNMP::Mixin'}{errors} ||= [];
  my @errors = @{ $session->{'Net::SNMP::Mixin'}{errors} };

  # store the error_msg at the buffer end if not already in the buffer
  push @{ $session->{'Net::SNMP::Mixin'}{errors} }, $error_msg
      unless grep m/\Q$error_msg\E$/, @errors;
}

=item B<< get_init_slot() >>

Helper method, defines and returns the init hash slot for all mixin modules.

=back

=cut

sub get_init_slot {
  my ($session) = @_;

  die "missing attribute 'session'," unless defined $session;

  die "'session' isn't a Net::SNMP object,"
    unless ref $session && $session->isa('Net::SNMP');

  $session->{'Net::SNMP::Mixin'}{init_jobs_left} = {}
    unless exists $session->{'Net::SNMP::Mixin'}{init_jobs_left};

  return $session->{'Net::SNMP::Mixin'}{init_jobs_left};
}

unless ( caller() ) {
  print __PACKAGE__ . " compiles and initializes successful.\n";
}

=head1 REQUIREMENTS

L<Net::SNMP>, L<Sub::Exporter>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
