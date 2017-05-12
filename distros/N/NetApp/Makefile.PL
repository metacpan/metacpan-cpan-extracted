
use strict;
use warnings;
use English;

use inc::Module::Install;

name         q{NetApp};
abstract     q{The EFS project, NetApp API};
author       q{Phillip Moore <wpm@openefs.org>};
perl_version q{5.010};
license      q{unknown};
all_from     q{lib/NetApp.pm};

test_requires q{Test::Exception};

requires q{IPC::Cmd};
requires q{Class::Std};
requires q{Params::Validate};
requires q{Regexp::Common};
requires q{Memoize};
requires q{Net::Telnet};
requires q{Clone};

tests_recursive;

WriteAll;
