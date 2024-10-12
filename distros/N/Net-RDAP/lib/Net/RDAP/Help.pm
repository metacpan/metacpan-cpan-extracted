package Net::RDAP::Help;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

=head1 NAME

L<Net::RDAP::Help> - a module representing an RDAP help response.

=head1 DESCRIPTION

L<Net::RDAP::Help> represents an RDAP server's "help" query.

Help responses typically only contain notices, so use the C<notices()>
method to obtain them.

Otherwise, L<Net::RDAP::Help> inherits from L<Net::RDAP::Object>
so has access to all that module's methods.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
