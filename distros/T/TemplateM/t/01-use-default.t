#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
# 
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use-default.t 10 2013-07-08 14:37:29Z abalama $
#
#########################################################################

use Test::More tests => 2;
BEGIN { use_ok('TemplateM'); };
is(TemplateM->VERSION,'3.03','version checking');
