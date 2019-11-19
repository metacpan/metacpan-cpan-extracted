# Copyright (c) 2019 Tomasz Konojacki
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package Software::License::BSD_1_Clause;

use strict;
use warnings;

our $VERSION = '0.003';

use parent 'Software::License';

sub name { 'The 1-Clause BSD License' }
sub url  { 'https://spdx.org/licenses/BSD-1-Clause.html' }

sub meta_name  { 'unrestricted' }
sub spdx_expression  { 'BSD-1-Clause' }

1;

=pod

=encoding UTF-8

=head1 NAME

Software::License::BSD_1_Clause - The 1-Clause BSD License

=head1 VERSION

version 0.003

=head1 SEE ALSO

=over 4

=item *

L<Software::License>

=item *

L<https://spdx.org/licenses/BSD-1-Clause.html>

=back

=head1 AUTHOR

Tomasz Konojacki <me@xenu.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Tomasz Konojacki

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__LICENSE__
The 1-Clause BSD License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
