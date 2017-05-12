# *
# *     Copyright (c) 2000-2004 Alberto Reggiori <areggiori@webweaving.org>
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
# *     version 0.1 - Wed May 23 18:16:29 CEST 2001
# *

package RDFStore::Digest::Digestable;
{
use vars qw ($VERSION);
use strict;

$VERSION = '0.1';

sub new {
        bless {} , shift;
};

sub getDigest {
};

1;
};

__END__

=head1 NAME

RDFStore::Digest::Digestable - implementation of the Digestable RDF API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

Digest(3)

=head1 AUTHOR

        Alberto Reggiori <areggiori@webweaving.org>
