package Net::OAuth::RequestTokenRequest;
use warnings;
use strict;
use base 'Net::OAuth::Request';

sub sign_message {1}

=head1 NAME

Net::OAuth::RequestTokenRequest - An OAuth protocol request for a Request Token

=head1 SEE ALSO

L<Net::OAuth>, L<http://oauth.net>

=head1 AUTHOR

Originally by Keith Grennan <foss@nearlyfree.org>

Currently maintained by Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2012, 2024-2026 Keith Grennan

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
