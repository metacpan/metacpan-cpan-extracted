#
# This file is part of PerlIO-via-GnuPG
#
# This software is Copyright (c) 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package PerlIO::via::GnuPG::Maybe;
our $AUTHORITY = 'cpan:RSRCHBOY';
$PerlIO::via::GnuPG::Maybe::VERSION = '0.006';
# ABSTRACT: Layer to decrypt or pass-through unencrypted data on read

use strict;
use warnings;

use parent 'PerlIO::via::GnuPG';

sub _passthrough_unencrypted { 1 }

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl decrypt

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

PerlIO::via::GnuPG::Maybe - Layer to decrypt or pass-through unencrypted data on read

=head1 VERSION

This document describes version 0.006 of PerlIO::via::GnuPG::Maybe - released August 10, 2015 as part of PerlIO-via-GnuPG.

=head1 SYNOPSIS

    use PerlIO::via::GnuPG::Maybe;

    # cleartext.txt may or may not be encrypted;
    # returns the content or dies on any other error.
    open(my $fh, '<:via(GnuPG::Maybe)', 'cleartext.txt')
        or die "cannot open! $!";

    my @in = <$fh>; # or whatever...

=head1 DESCRIPTION

This is a L<PerlIO> module to decrypt files transparently.  If you try to
open and read a file that is not encrypted, we will simply pass that file
through unmolested.  If you try to open and read one that is encrypted,
it tries to decrypt it and pass it back along to you.

If you're looking for a stricter implementation, see L<PerlIO::via::GnuPG>;
it will die if the file is unencrypted.

It's pretty simple and does not support writing, but works.

...and if it doesn't, please file an issue :)

=for Pod::Coverage FILL PUSHED

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PerlIO::via::GnuPG|PerlIO::via::GnuPG>

=item *

L<PerlIO|PerlIO>

=item *

L<PerlIO::via|PerlIO::via>

=item *

L<PerlIO::via::GnuPG|PerlIO::via::GnuPG>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/perlio-via-gnupg/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fperlio-via-gnupg&title=RsrchBoy's%20CPAN%20PerlIO-via-GnuPG&tags=%22RsrchBoy's%20PerlIO-via-GnuPG%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fperlio-via-gnupg&title=RsrchBoy's%20CPAN%20PerlIO-via-GnuPG&tags=%22RsrchBoy's%20PerlIO-via-GnuPG%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
