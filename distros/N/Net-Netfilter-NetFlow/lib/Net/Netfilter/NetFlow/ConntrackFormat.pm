package Net::Netfilter::NetFlow::ConntrackFormat;
{
  $Net::Netfilter::NetFlow::ConntrackFormat::VERSION = '1.113260';
}

use strict;
use warnings FATAL => 'all';

use base 'Exporter';
our @EXPORT = qw(
    %ct_new_key
    %ct_destroy_key
    %ct_mask_fields
);

# TODO document and make user configurable

# 1:icmp - src,src,dst,id
# 6:tcp  - src,sport,src,sport,dst,dport
# 17:udp - src,sport,src,sport,dst,dport
# first src is private, second is public (post SNAT)

our %ct_new_key = (
    1  => [4,11,5,8],
    6  => [5,7,11,13,6,8],
    17 => [4,6,10,12,5,7],
);

our %ct_destroy_key = (
    1  => [3,11,4,7],
    6  => [3,5,10,12,4,6],
    17 => [3,5,10,12,4,6],
);

# dpkts, doctets, srcaddr, dstaddr, srcport, dstport
our %ct_mask_fields = (
    1 => {
        # field 17 does not exist
        private_src => [8,9,3,4,17,17],
        public_src  => [8,9,11,10,17,17],
        dst => [15,16,10,11,17,17],
    },
    6 => {
        private_src => [7,8,3,4,5,6],
        public_src  => [7,8,10,9,12,11],
        dst => [13,14,9,10,11,12],
    },
    17 => {
        private_src => [7,8,3,4,5,6],
        public_src  => [7,8,10,9,12,11],
        dst => [13,14,9,10,11,12],
    },
);

__END__

=head1 AUTHOR

Oliver Gorwits C<< <oliver@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2009.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

