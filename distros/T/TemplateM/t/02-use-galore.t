#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-use-galore.t 2 2013-04-02 10:51:49Z abalama $
#
#########################################################################

use Test::More tests => 3;
BEGIN { use_ok('TemplateM', 'galore') };
my $tpl;
$tpl = new_ok(TemplateM=>[-template=>''],'TemplateM');
is($tpl && $tpl->scheme(),'galore','module checking');
