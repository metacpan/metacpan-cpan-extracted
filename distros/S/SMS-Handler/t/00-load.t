
# $Id: 00-load.t,v 1.4 2002/12/27 19:43:42 lem Exp $

use Test::More tests => 6;

use_ok('SMS::Handler');
use_ok('SMS::Handler::Ping');
use_ok('SMS::Handler::Utils');
use_ok('SMS::Handler::Email');
use_ok('SMS::Handler::Blackhole');
use_ok('SMS::Handler::Dispatcher');

