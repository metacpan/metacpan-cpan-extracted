use strict;
use warnings;

package Software::License::WTFPL_2;
BEGIN {
  $Software::License::WTFPL_2::VERSION = '0.03';
}
# ABSTRACT: The Do What The Fuck You Want To Public License, Version 2

use base 'Software::License';


sub name      { 'DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004' }
sub url       { 'http://sam.zoy.org/wtfpl/COPYING' }
sub meta_name { 'unrestricted' }

1;



=pod

=head1 NAME

Software::License::WTFPL_2 - The Do What The Fuck You Want To Public License, Version 2

=head1 DESCRIPTION

There is a long ongoing battle between GPL zealots and BSD fanatics,
about which license type is the most free of the two. In fact, both
license types have unacceptable obnoxious clauses (such as reproducing
a huge disclaimer that is written in all caps) that severely restrain
our freedoms. The WTFPL can solve this problem.

When analysing whether a license is free or not, you usually check
that it allows free usage, modification and redistribution. Then you
check that the additional restrictions do not impair fundamental
freedoms. The WTFPL renders this task trivial: it allows everything
and has no additional restrictions. How could life be easier? You just
DO WHAT THE FUCK YOU WANT TO.

=encoding utf8

=head1 FAQ

=over 4

=item Is the WTFPL a valid license?

Although the validity of the WTFPL has not been tested in courts, it
is widely accepted as a valid license. Every major Linux distribution
(Debian, Red Hat, Gentoo, SuSE, Mandrake, etc.) ships software
licensed under the WTFPL, version 1 or 2. Bradley Kuhn (executive
director of the Free Software Foundation) was quoted saying that the
FSF’s folks agree the WTFPL is a valid free software license.

=item Why is there no “no warranty” clause?

The WTFPL is an all-purpose license and does not cover only computer
programs; it can be used for artwork, documentation and so on. As
such, it only covers copying, distribution and modification. If you
want to add a no warranty clause for a program, you may use the
following wording in your source code:

  /* This program is free software. It comes without any warranty, to
   * the extent permitted by applicable law. You can redistribute it
   * and/or modify it under the terms of the Do What The Fuck You Want
   * To Public License, Version 2, as published by Sam Hocevar. See
   * http://sam.zoy.org/wtfpl/COPYING for more details. */

=item Isn’t this license basically public domain?

There is no such thing as “putting a work in the public domain”, you
America-centered, Commonwealth-biased individual. Public domain varies
with the jurisdictions, and it is in some places debatable whether
someone who has not been dead for the last seventy years is entitled
to put his own work in the public domain.

=item Can’t you change the wording? It’s inappropriate / childish / not corporate-compliant.

What the fuck is not clear in “DO WHAT THE FUCK YOU WANT TO”? If you
do not like the license terms, just relicense the work under another
license.

=item Who uses the WTFPL?

The WTFPL on this website is version 2. Version 1 of the WTFPL was
written by Banlu Kemiyatorn, who used it for some WindowMaker artwork.

L<Freshmeat|http://freshmeat.net/browse/1008/> has a WTFPL license
category.

=item By the way, with the WTFPL, can I also…

Oh but yes, of course you can.

=item But can I…

Yes you can.

=item Can…

Yes!

=back

=head1 SEE ALSO

L<http://sam.zoy.org/wtfpl/>

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Florian Ragwitz.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut


__DATA__
__LICENSE__
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.
