package OpenSMTPD::Password::XS;
use strict; use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('OpenSMTPD::Password::XS', $VERSION);

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

OpenSMTPD::Password::XS - OpenBSD XS backend for OpenSMTPD::Password

=head1 SYNOPSIS

  use OpenSMTPD::Password;

=head1 DESCRIPTION

Nothing to see here.

=head1 SEE ALSO

L<OpenSMTPD::Password>.

=head1 AUTHOR

Edgar Pettijohn, E<lt>edgar@pettijohn-web.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Edgar Pettijohn

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.

=cut
