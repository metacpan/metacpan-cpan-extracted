#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-loop.t 2 2013-04-02 10:51:49Z abalama $
#
#########################################################################

use Test::More tests => 7;
BEGIN { use_ok('TemplateM', 'galore'); };

my $tpl;
$tpl = new_ok(TemplateM=>[\*DATA],'TemplateM');
is($tpl && $tpl->scheme(),'galore','module checking');

my $box;
ok($box = $tpl->start('foo'), 'call start() method');
foreach (qw/foo bar baz qux quux corge grault garply waldo fred plugh/) {
    $box->loop(item=>$_)
}
ok($box->finish, 'call finish() method');
my $output;
ok($output = $tpl->output(), 'call output() method');
ok($output && $output=~/quux/,'string "quux" finded');

# print $output;
__DATA__
Loop:
<!-- do: foo -->
  <!-- val: item --><!-- loop: foo -->
