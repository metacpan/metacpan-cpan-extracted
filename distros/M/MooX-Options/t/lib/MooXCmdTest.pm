#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::MooXCmdTest;
use Moo;
use MooX::Cmd;
use MooX::Options
    authors     => 'Celogeek <me@celogeek.com>',
    description => 'This is a test sub command',
    synopsis    => 'This is a test synopsis';

sub execute {
    die "need a sub command !";
}

1;
