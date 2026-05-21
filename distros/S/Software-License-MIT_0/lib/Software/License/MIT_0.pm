package Software::License::MIT_0;

use v5.12.0;

use strict;
use warnings;

use parent qw< Software::License >;

our $VERSION = 'v1.0.1';

sub name            { 'MIT No Attribution License' }
sub url             { 'https://raw.githubusercontent.com/aws/mit-0/feadea429356d82c9bc82cce0c76894892683c3b/MIT-0' }
sub version         { undef }
sub meta_name       { 'open_source' }
sub meta2_name      { 'open_source' }
sub spdx_expression { 'MIT-0' }

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

Software::License::MIT_0 - MIT No Attribution License (MIT-0)

=head1 SYNOPSIS

    use Software::License::MIT_0;

    my $license = Software::License::MIT_0->new(
        {
            holder => 'COPYRIGHT HOLDER',
        }
    );

    print $license->license;

=head1 DESCRIPTION

This module is a L<Software::License> subclass implementation of the MIT No Attribution
License. The "MIT No Attribution" or "MIT-0" license is a variant of the permissive
MIT license that removes the requirement for attribution.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/Software-License-MIT_0/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<Software::License>

=item *

L<https://github.com/aws/mit-0>

=item *

L<https://spdx.org/licenses/MIT-0.html>

=item *

L<https://opensource.org/license/mit-0>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut

1;

__DATA__
__LICENSE__
MIT No Attribution

Copyright {{$self->year}} {{$self->_dotless_holder}}

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
