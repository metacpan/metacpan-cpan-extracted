#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 05-ifelse.t 2 2013-04-02 10:51:49Z abalama $
#
#########################################################################

use Test::More tests => 8;
BEGIN { use_ok('TemplateM', 'galore'); };

my $tpl;
$tpl = new_ok(TemplateM=>[\*DATA],'TemplateM');
is($tpl && $tpl->scheme(),'galore','module checking');

ok($tpl->cast_if(foo=>1), 'call cast_if(foo=>1) method');
ok($tpl->cast_if(bar=>0), 'call cast_if(bar=>0) method');
my $output;
ok($output = $tpl->output(), 'call output() method');
ok($output && $output=~/IF\s*\:\s*OK/,'string "IF: OK" finded');
ok($output && $output=~/ELSE\s*\:\s*OK/,'string "ELSE: OK" finded');

# print $output;
__DATA__
IF   : <!-- if: foo -->OK<!-- endif: foo --><!-- else: foo -->ERROR<!-- endelse: foo -->
ELSE : <!-- else: bar -->OK<!-- endelse: bar --><!-- if: bar -->ERROR<!-- endif: bar -->
