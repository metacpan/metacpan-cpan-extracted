# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: Tidy.pm,v 1.2 2005/10/09 22:17:18 jhoblitt Exp $

package Test::Pod::Tidy;

use strict;

use Encode;
use Encode::Newlines;

use base qw( Exporter );

use vars qw(
    @EXPORT
    $MESSY_POD
    $TIDY_POD
    $VALID_POD
    $INVALID_POD
    $POD_WS_TAIL
    $POD_WS_TRIMMED
);

@EXPORT = qw(
    $MESSY_POD
    $TIDY_POD
    $VALID_POD
    $INVALID_POD
    $POD_WS_TAIL
    $POD_WS_TRIMMED
);

$MESSY_POD = encode( Native =><<END );
=head1 NAME

perlpodspec - Plain Old Documentation: format specification and notes

=head1 DESCRIPTION

This document is detailed notes on the Pod markup language.  Most
people will only have to read L<perlpod|perlpod> to know how to write
in Pod, but this document may answer some incidental questions to do
with parsing and rendering Pod.

In this document, "must" / "must not", "should" /
"should not", and "may" have their conventional (cf. RFC 2119)
meanings: "X must do Y" means that if X doesn't do Y, it's against
this specification, and should really be fixed.  "X should do Y"
means that it's recommended, but X may fail to do Y, if there's a
good reason.  "X may do Y" is merely a note that X can do Y at
will (although it is up to the reader to detect any connotation of
"and I think it would be I<nice> if X did Y" versus "it wouldn't
really I<bother> me if X did Y").

Notably, when I say "the parser should do Y", the
parser may fail to do Y, if the calling application explicitly
requests that the parser I<not> do Y.  I often phrase this as
"the parser should, by default, do Y."  This doesn't I<require>
the parser to provide an option for turning off whatever
feature Y is (like expanding tabs in verbatim paragraphs), although
it implicates that such an option I<may> be provided.

=cut
END

$TIDY_POD = encode( Native =><<END );
=head1 NAME

perlpodspec - Plain Old Documentation: format specification and notes

=head1 DESCRIPTION

This document is detailed notes on the Pod markup language.  Most people will
only have to read L<perlpod|perlpod> to know how to write in Pod, but this
document may answer some incidental questions to do with parsing and rendering
Pod.

In this document, "must" / "must not", "should" / "should not", and "may" have
their conventional (cf. RFC 2119) meanings: "X must do Y" means that if X
doesn't do Y, it's against this specification, and should really be fixed.  "X
should do Y" means that it's recommended, but X may fail to do Y, if there's a
good reason.  "X may do Y" is merely a note that X can do Y at will (although
it is up to the reader to detect any connotation of "and I think it would be
I<nice> if X did Y" versus "it wouldn't really I<bother> me if X did Y").

Notably, when I say "the parser should do Y", the parser may fail to do Y, if
the calling application explicitly requests that the parser I<not> do Y.  I
often phrase this as "the parser should, by default, do Y."  This doesn't
I<require> the parser to provide an option for turning off whatever feature Y
is (like expanding tabs in verbatim paragraphs), although it implicates that
such an option I<may> be provided.

=cut
END

$VALID_POD = encode( Native =><<END );
=pod

=head1 foo

bar baz.

=cut
END

$INVALID_POD = encode( Native =><<END );
=pod

=end

=begin

=bogustag

=back
END

$POD_WS_TAIL = encode( Native =><<END );
=head2 C source tests

C source tests are usually located in F<t/src/*.t>.  A simple test looks like:  

    c_output_is(<<'CODE', <<'OUTPUT', "name for test");
    #include <stdio.h>
    #include "parrot/parrot.h"
    #include "parrot/embed.h"

=cut
END

$POD_WS_TRIMMED = encode( Native =><<END );
=head2 C source tests

C source tests are usually located in F<t/src/*.t>.  A simple test looks like:

    c_output_is(<<'CODE', <<'OUTPUT', "name for test");
    #include <stdio.h>
    #include "parrot/parrot.h"
    #include "parrot/embed.h"

=cut
END

1;

__END__
