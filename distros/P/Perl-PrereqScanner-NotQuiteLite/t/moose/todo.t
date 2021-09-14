use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

plan skip_all => 'TODO';

test('too early extends', <<'END', {Moose => 0, 'UNIVERSAL::require' => 0, 'Test::Run::CmdLine' => 0, 'Test::Run::Base' => 0}); # SHLOMIF/Test-Run-CmdLine-0.0131/lib/Test/Run/CmdLine/Iface.pm
extends ('Test::Run::Base');

use UNIVERSAL::require;

use Test::Run::CmdLine;

use Moose;
END

done_testing;
