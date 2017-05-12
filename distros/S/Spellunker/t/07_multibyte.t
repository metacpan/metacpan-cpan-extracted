use strict;
use warnings;
use Test::More;

use Spellunker;

my $spell= Spellunker->new();
ok !$spell->check_line('testあああああああああああああああああああああああああああああああああああああああ');
ok !$spell->check_line('ppcode内ではこのグローバルなスタックポインタを一旦ローカルにコピーします');
ok !$spell->check_line('I am a pen.');

done_testing;

