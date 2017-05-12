#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright 2006 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#ident	"@(#)Makefile.PL	1.4	06/05/31 SMI"
#
#
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

#
# If not building as part of ON.
#
if (! exists($ENV{CODEMGR_WS})) {
	#
	# Suppress the setting of LD_RUN_PATH.  The ON build environment
	# contains a modified MakeMaker that does this automatically, so we
	# only need to do this if we are building outside of ON.
	#
	package MY;
	no warnings qw(once);

	# Override const_loadlibs to remove LD_RUN_PATH cruft.
	*const_loadlibs = sub
	{
		my $self = shift(@_);
		delete($self->{LD_RUN_PATH});
		return($self->SUPER::const_loadlibs(@_));
	};

	# Override dynamic_lib to get rid of LD_RUN_PATH cruft.
	*dynamic_lib = sub
	{
		my $self = shift(@_);
		my $txt = $self->SUPER::dynamic_lib(@_);
		$txt =~ s/LD_RUN_PATH=\S*\s*//;
		return($txt);
	};
}

WriteMakefile(
    NAME              => 'Solaris::Lgrp',
    ABSTRACT_FROM     => 'pod/Lgrp.pod',
    VERSION_FROM      => 'Lgrp.pm',
    LIBS              => ['-llgrp '],
    AUTHOR	      => 'Alexander Kolbasov <alexander.kolbasov@sun.com>',
    EXE_FILES	      => ['bin/lgrpinfo'],
);
