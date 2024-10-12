package Net::RDAP::Notice;
use base qw(Net::RDAP::Remark);
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Notice> - a module representing an RDAP notice.

=head1 DESCRIPTION

This module represents a notice attached to an RDAP response. Since
notices are identical to remarks (they only differ in their position
in RDAP responses), this module inherits everything from
L<Net::RDAP::Remark>.

Any object which inherits from L<Net::RDAP::Object> will have an
C<notices()> method which will return an array of zero or more
L<Net::RDAP::Notice> objects; however, only the top-most object in an
RDAP response will have notices, since they relate to the RDAP
I<service> rather than the specific object contained in the
response.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
