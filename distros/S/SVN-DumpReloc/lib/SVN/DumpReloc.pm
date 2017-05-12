package SVN::DumpReloc;

use strict;
use warnings;

our $VERSION = '0.02';


1;
__END__

=head1 NAME

SVN::DumpReloc - Perl script to rewrite paths inside a Subversion dump

=head1 SYNOPSIS

  $ svn-dump-reloc from-path to-path <in-sv-dump >out-sv-dump


=head1 DESCRIPTION

This package is just a wrapper for the script L<svn-dump-reloc>.

If you are interested in having the same funcionality available as a
Perl module, drop me a mail and I would move it here... or even
better, send me a patch :-)))


=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Qindel Formacion y Servicios S.L.


Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
