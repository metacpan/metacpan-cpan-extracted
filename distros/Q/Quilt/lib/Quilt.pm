#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Quilt.pm,v 1.6 1998/03/09 03:18:14 ken Exp $
#

package Quilt;
use vars qw{$VERSION};

$VERSION = '0.08';

use Quilt::Objs;
use Quilt::Flow::Table;
use Quilt::DO::Author;
use Quilt::DO::List;
use Quilt::DO::Struct;
use Quilt::HTML;

1;
