################################################################################
#
# Copyright (C) 2000, Ashley Winters <jql@accessone.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package KDE;
use Qt 2.0;
require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '0.004';

bootstrap KDE $VERSION;

1;
