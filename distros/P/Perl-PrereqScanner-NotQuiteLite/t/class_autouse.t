use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('as a pragma', <<'END', {'Class::Autouse' => 0}, {}, {'CGI' => 0});
use Class::Autouse qw{CGI};
END

test('method call', <<'END', {'Class::Autouse' => 0}, {}, {'CGI' => 0});
use Class::Autouse;
Class::Autouse->autouse('CGI');
END

done_testing;
