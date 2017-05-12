package Net::DAV::UUID;

use strict;

our $VERSION = '1.305';
$VERSION = eval $VERSION;  # convert development version into a simpler version number.

use Digest::SHA1 qw(sha1);

my $counter = 0;

#
# Given a WebDAV resource path and lock requestor/owner, generate
# a UUID mostly compliant with RFC 4918 section 20.7.  Despite the
# lack of EUI64 identifier in the host portion of the UUID, the
# value generated is likely not cryptographically sound and should
# not be used in production code outside of the limited realm of a
# WebDAV server implementation.
#
# Note that due to the nature of the underlying libc function rand(),
# it would be best that any concurrent WebDAV services built upon
# this package synchronize upon usages of this method.
#
sub generate {
    return join '-', unpack('H8 H4 H4 H4 H12', sha1( join( ':', @_[0,1], time, rand, $<, $$, ++$counter ) ));
}

1;

__END__
Copyright (c) 2010, cPanel, Inc. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
