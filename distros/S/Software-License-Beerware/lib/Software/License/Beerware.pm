use strict;
use warnings;

package Software::License::Beerware;
BEGIN {
  $Software::License::Beerware::VERSION = '0.1';
}
BEGIN {
  $Software::License::Beerware::VERSION = '0.1';
}
# ABSTRACT: "THE BEER-WARE LICENSE" (Revision 42)

use base 'Software::License';

sub name      { 'THE BEER-WARE LICENSE' }
sub url       { 'http://people.freebsd.org/~phk/' }
sub meta_name { 'unrestricted' }

1;

=head1 NAME

Software::License::Beerware - "THE BEER-WARE LICENSE" (Revision 42)

=head1 VERSION

version 0.1

=head1 DESCRIPTION

 /*
  * ----------------------------------------------------------------------------
  * "THE BEER-WARE LICENSE" (Revision 42):
  * <phk@FreeBSD.ORG> wrote this file. As long as you retain this notice you
  * can do whatever you want with this stuff. If we meet some day, and you think
  * this stuff is worth it, you can buy me a beer in return Poul-Henning Kamp
  * ----------------------------------------------------------------------------
  */

=head1 SEE ALSO

L<http://people.freebsd.org/~phk/>, L<http://en.wikipedia.org/wiki/Beerware>.

=head1 AUTHOR & COPYRIGHT

Copyright 2011 David Leadbeater E<lt>dgl(at)dgl.cxE<gt>

The Beer-ware license was written by Poul-Henning Kamp.

=cut

__DATA__
__NOTICE__
This software is copyright (c) {{$self->year}} by {{$self->holder}}.

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Beer-ware license revision 42.
__LICENSE__
"THE BEER-WARE LICENSE" (Revision 42):
{{$self->holder}} wrote this file. As long as you retain this notice you
can do whatever you want with this stuff. If we meet some day, and you think
this stuff is worth it, you can buy me a beer in return.