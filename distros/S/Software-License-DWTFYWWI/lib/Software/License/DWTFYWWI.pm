package Software::License::DWTFYWWI;
BEGIN {
  $Software::License::DWTFYWWI::VERSION = '0.01';
}

use strict;
use warnings;

use base 'Software::License';

=head1 NAME

Software::License::DWTFYWWI - The "Do Whatever The Fuck You Want With It" license

=head1 DESCRIPTION

The DWTFYWWI license is a way to effectively place your software into
the public domain, but in a humorous way.

If you want something with more legal backing you might want to use
the L<"public domain"-like CC0 license|Software::License::CC0_1_0>
instead, or maybe L<The MIT (X11) License|Software::License::MIT>.

=head1 AUTHOR

The author of this package and of the DWTFYWWI license itself is
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=cut

sub name      { q(DWTFYWWI) }
sub url       { q{http://github.com/avar/DWTFYWWI/raw/master/DWTFYWWI} }

sub meta_name { 'unrestricted' }

1;
__DATA__
__NOTICE__
{{$self->holder}} grants everyone permission to do whatever the fuck
they want with the software, whatever the fuck that may be.
__LICENSE__
                          DWTFYWWI LICENSE
                       Version 1, January 2006

 Copyright (C) 2006 Ævar Arnfjörð Bjarmason

                            Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the DWTFYWWI or Do
Whatever The Fuck You Want With It license is intended to guarantee
your freedom to share and change the software--to make sure the
software is free for all its users.

                         DWTFYWWI LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
0. The author grants everyone permission to do whatever the fuck they
want with the software, whatever the fuck that may be.
