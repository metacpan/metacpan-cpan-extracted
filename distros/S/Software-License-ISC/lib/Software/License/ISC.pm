use strict;
use warnings;

package Software::License::ISC;

our $VERSION = '0.004';    # VERSION

use parent 'Software::License';

# ABSTRACT: The ISC License

sub name       { 'The ISC License' }
sub url        { 'about:blank' }
sub meta_name  { 'open_source' }
sub meta2_name { 'open_source' }

1;

=pod

=head1 NAME

Software::License::ISC - The ISC License

=head1 VERSION

version 0.004

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libsoftware-license-isc-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by David Zurborg.

This is free software, licensed under The ISC License.

=cut

__DATA__
__LICENSE__
Permission to use, copy, modify, and/or distribute this
software for any purpose with or without fee is hereby granted, provided
that the above copyright notice and this permission notice appear in all
copies.

The software is provided "as is" and the author disclaims all warranties
with regard to this software including all implied warranties of
merchantability and fitness.  In no event shall the author be liable for any
special, direct, indirect, or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an action
of contract, negligence or other tortious action, arising out of or in
connection with the use or performance of this software.
