#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Display.pm,v 1.1.1.1 1997/10/22 21:35:09 ken Exp $
#

use Quilt;

use strict;

package Quilt::Flow::Display;
@Quilt::Flow::Display::ISA = qw{Quilt::Flow};

package Quilt::Flow::DisplaySpace;
@Quilt::Flow::DisplaySpace::ISA = qw{Quilt::Flow::Display};

#
# lines:                   wrap*, asis
# quadding:                start*, end, center, justify
# first-line-start-indent: (0pt*)
# start-indent:            (0pt*)
# end-indent:              (0pt*)
# space-before:            (0pt*)
# space-after:             (0pt*)
#

package Quilt::Flow::Paragraph;
@Quilt::Flow::Paragraph::ISA = qw{Quilt::Flow::Display};

1;
