use warnings;
use strict;
use feature ':5.10';
use Test::More;
use Test::Exception;

use Narada::Config qw( :ALL );


my @res;
lives_ok { @res = get_config('var')     }   'get_config do no throw';
is_deeply \@res, [undef],                   'get_config return undef';
lives_ok { @res = get_config_line('var')}   'get_config_line do no throw';
is_deeply \@res, [undef],                   'get_config_line return undef';
lives_ok { @res = get_db_config()       }   'get_db_config do no throw';
is_deeply \@res, [],                        'get_db_config return nothing';
throws_ok { set_config('var', 'val') } qr/directory/ims, 'set_config throws';


done_testing();
