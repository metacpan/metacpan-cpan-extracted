package Net::IP::Match::Bin;

use 5.007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::IP::Match::Bin ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	match_ip
);

our $VERSION = '0.14';

require XSLoader;
XSLoader::load('Net::IP::Match::Bin', $VERSION);

# Preloaded methods go here.


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::IP::Match::Bin - Perl extension for match IP addresses against Net ranges

=head1 SYNOPSIS

  use Net::IP::Match::Bin;

  my $ipm = Net::IP::Match::Bin->new();
  $ipm->add("10.1.1.0/25", ...);
  ...
  $ipm->add("192.168.2.128/26", ...);

  $cidr = $ipm->match_ip("192.168.2.131");
  $cidr = $ipm->match_ip("192.168.2.128/29");


=head1 DESCRIPTION

This module is XS implementation of matching IP addresses against Net ranges.
Using similar method to Net::IP::Match::Regexp in storing Net ranges into
memory. By implementing in XS C-code, and does not use regexp, more fast setup
time and less using memory.
This module is useful when Net ranges change often or reusing range data
won't be suitable.


=head1 METHODS

=over

=cut

=item new()

Create IP range object and initialize it.


=item $ipm->add( $net | $arrayref | $hashref, ... )

Add Network address (xxx.xxx.xxx.xxx/mask) into the object. mask is 1 .. 32 CIDR mask bit value.

    $ipm->add( [ "10.1.0.0/16", "10.2.2.128/25", "192.168.0.0/27" ] );

    $ipm->add( { "10.1.0.0/17" => "Net A", "10.2.2.0/24" => "Net B",
		"192.168.0.0/27" => "Net X" } );

When HASH ref is used as arguments, match_ip() returns the value when matched. Note that
CIDRs could be aggregated internaly, these values may be lost in aggregation.


=item $ipm->add_range( $range_str, ... )

Adds IP range into the object. $range_str would be

    $range_str = "1.2.3.4-10.20.30.41";

=item $cidr = $ipm->match_ip( $ip )

=item $cidr = $ipm->match_ip( $net )

Searches matching $ip or $net against previously setup networks. Returns matched
Network in CIDR format (xxx.xxx.xxx.xxx/mask). or undef unless matched.

=item $list = $ipm->list()

=item @list = $ipm->list()

Lists the current CIDR list which has been added previously. CIDRs are aggregated internaly and
the list shows this internal data. In scalar context, list() returns reference to the array. On
list context, returns array itself.

=item $ipm->clean()

Remove redundant CIDR data from the object. Note that this method does not free memories, so,
if you would like to, generate list() and create new object from it.

=back

=head1 FUNCTIONS

=over

=cut

=item match_ip($ip, $cidr1, $cidr2,...)

function call match_ip() acts like as Net::IP::Match 's same name function. searches IP of first
argument matches againsts others.
 

=back



=head1 SEE ALSO

=over

=item L<Net::IP::Match::Regexp>, L<Net::CIDR::Lite>, L<Net::IP::Match>

=back


=head1 AUTHOR

Tomo.M E<lt>tomo at cpan orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Tomo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
