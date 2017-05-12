#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::MooXCmdTest::Cmd::test1::Cmd::test2;

use Moo;
use MooX::Cmd;
use MooX::Options;

sub execute {
    die "test2";
}
1;

