#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Inline.pm,v 1.1.1.1 1997/10/22 21:35:09 ken Exp $
#

use Quilt;

use strict;

package Quilt::Flow::Inline;
@Quilt::Flow::Inline::ISA = qw{Quilt::Flow};

#
# font-family-name:  iso-serif*, iso-sanserif, iso-monospace
# font-weight:       light, medium*, bold
# font-posture:      upright*, italic
# font-size:         (10pt*)
#

1;
