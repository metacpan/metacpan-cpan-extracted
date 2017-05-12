# P2P::pDonkey::Util.pm
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Util;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    addr2ip ip2addr 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

# Preloaded methods go here.

use Socket qw (inet_aton inet_ntoa);

sub addr2ip {
    my $ip;
    $ip = inet_aton($_[0]);
    defined $ip || return 0;
    return unpack('L', $ip);
}

sub ip2addr {
    return inet_ntoa(pack('L', $_[0]));
}

1;
__END__

=head1 NAME

P2P::pDonkey::Util - Utility functions for P2P::pDonkey extensions.

=head1 SYNOPSIS

  use P2P::pDonkey::Util ':all';
  print ip2addr(addr2ip('176.16.5.33')), "\n";

=head1 DESCRIPTION

=over

=item addr2ip HOSTNAME

    Analog for inet_aton, but returns unpacked ip number.

=item ip2addr IP_NUMBER

    Analog inet_ntoa, take as argument unpacked ip number.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>, L<Socket>.

=cut
