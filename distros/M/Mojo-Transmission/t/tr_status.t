use Mojo::Base -strict;
use Test::More;
use Mojo::Transmission 'tr_status';

is tr_status(0),  'stopped',       'tr_status 0';
is tr_status(1),  'check_wait',    'tr_status 1';
is tr_status(2),  'check',         'tr_status 2';
is tr_status(3),  'download_wait', 'tr_status 3';
is tr_status(4),  'download',      'tr_status 4';
is tr_status(5),  'seed_wait',     'tr_status 5';
is tr_status(6),  'seed',          'tr_status 6';
is tr_status(-1), '',              'tr_status -1';
is tr_status(10), '',              'tr_status 10';

done_testing;
