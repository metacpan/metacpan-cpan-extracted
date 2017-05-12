#
# Copyright 2002-2003 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#ident	"@(#)Task.pm	1.2	03/03/13 SMI"
#
# Task.pm provides the bootstrap for the Sun::Solaris::Task module.
#

require 5.6.1;
use strict;
use warnings;

package Sun::Solaris::Task;

our $VERSION = '1.2';
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our (@EXPORT_OK, %EXPORT_TAGS);
my @constants = qw(TASK_NORMAL TASK_FINAL);
my @syscalls = qw(settaskid gettaskid);
@EXPORT_OK = (@constants, @syscalls);
%EXPORT_TAGS = (CONSTANTS => \@constants, SYSCALLS => \@syscalls,
    ALL => \@EXPORT_OK);

use base qw(Exporter);

1;
