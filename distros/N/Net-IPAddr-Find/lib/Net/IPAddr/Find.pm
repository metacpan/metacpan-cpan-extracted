package Net::IPAddr::Find;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = '0.02';

use base qw(Exporter);
@EXPORT = qw(find_ipaddrs);

use NetAddr::IP::Find;
*find_ipaddrs = \&NetAddr::IP::Find::find_ipaddrs;

1;
__END__

=head1 NAME

Net::IPAddr::Find - Find IP addresses in plain text

=head1 SYNOPSIS

B<THIS MODULE IS DEPRECATED>

Use NetAddr::IP::Find instead.

=head1 DESCRIPTION

This is a module for finding IP addresses in plain text.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<NetAddr::IP::Find>.

=cut
