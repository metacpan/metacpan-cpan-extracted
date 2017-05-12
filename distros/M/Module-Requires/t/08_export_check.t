use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

sub export { 'NG' }

Module::Requires->import('ClassH');
is(export(), 'NG');

Module::Requires->import('-autoload', 'ClassH');
is(export(), 'OK');

done_testing;
