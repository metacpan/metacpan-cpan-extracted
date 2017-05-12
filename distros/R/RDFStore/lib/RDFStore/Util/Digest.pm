# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - Thu Feb  6 18:45:53 CET 2003
# *

package RDFStore::Util::Digest;
{
use strict;
use Carp;
use vars qw($VERSION);

use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file

$VERSION = '0.1';

1;
};

__END__

=head1 NAME

RDFStore::Util::Digest - Utility library to manage SHA-1 cryptographic digests

=head1 SYNOPSIS

	use RDFStore::Util::Digest;
	if( getDigestAlgorithm() eq 'SHA-1' ) {
		my $sha1_digest = computeDigest( $string );
		};

=head1 DESCRIPTION

Simple SHA-1 cryptographic digest generator

=head1 METHODS

=over 4

=item computeDigest ( STRING )

Return binary formatted cryptographic digest of give STRING

=item getDigestAlgorithm ()

Return 'SHA-1' - no other cryto method implemented for the moment

=head1 SEE ALSO

 Digest(1) Digest::SHA1(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
