################################################################################
#
# Copyright (C) 2000, Ashley Winters <jql@accessone.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Qt::OpenGL;
require DynaLoader;
require Qt;

@ISA = qw(DynaLoader);
$VERSION = '0.02';

bootstrap Qt::OpenGL $VERSION;

1;
