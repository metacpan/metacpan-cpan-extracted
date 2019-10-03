use strict;
use Test::More tests => 3;

use MySQL::Dump::Parser::XS;

my $parser = MySQL::Dump::Parser::XS->new;
while (my $line = <DATA>) {
    my @rows = $parser->parse($line);
    if (@rows == 1) {
        is $parser->current_target_table(), 'hoge';
    }
    elsif (@rows == 2) {
        is $parser->current_target_table(), 'fuga';
    }
    elsif (@rows == 3) {
        is $parser->current_target_table(), 'gfx';
    }
    else {
        fail 'unknwon case';
    }
}

__DATA__
INSERT INTO `hoge` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (1,1,NULL,0,'foo','2011-10-10 00:00:00','2011-10-11 11:22:33');
INSERT INTO `fuga` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (2,2,NULL,2,'bar','2011-10-10 11:00:00','2011-10-11 22:22:33'),(3,2,9,2,'baz','2011-10-10 11:00:00','2011-10-11 22:22:33');
INSERT INTO `gfx` (`id`,`foo_id`,`bar_id`,`baz_id`,`type`,`created_at`,`updated_at`) VALUES (4,5,NULL,0,'foo','2061-10-19 09:00:00','2061-10-19 19:22:33'),(5,6,NULL,7,'bar','2071-11-10 18:00:00','2071-11-11 22:22:39'),(6,1,12,0,'baz','2081-12-10 11:00:00','2081-12-11 22:22:33');
