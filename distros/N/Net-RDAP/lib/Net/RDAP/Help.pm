package Net::RDAP::Help;
use base qw(Net::RDAP::Object);
use strict;

=head1 NAME

L<Net::RDAP::Help> - an RDAP object representing a help
response.

=head1 DESCRIPTION

L<Net::RDAP::Help> represents an RDAP server's "help" query.

Help responses typically only contain notices, so use the C<notices()>
method to obtain them.

Otherwise, L<Net::RDAP::Help> inherits from L<Net::RDAP::Object>
so has access to all that module's methods.

=head1 COPYRIGHT

Copyright 2022 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
