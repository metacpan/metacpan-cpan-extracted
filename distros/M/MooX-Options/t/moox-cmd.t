#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use t::Test;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Capture::Tiny qw/capture/;

BEGIN {
    eval 'use MooX::Cmd 0.007';
    if ($@) {
        plan skip_all => 'Need MooX::Cmd (0.007) for this test';
        exit 0;
    }
}

use t::lib::MooXCmdTest;

trap {
    local @ARGV = ('-h');
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'base command help ok';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: test1, test3\E},
    'sub base command help ok';

trap {
    t::lib::MooXCmdTest->new->options_man( undef, *STDOUT );
};

like $trap->stdout, qr{NAME\s+\Qmoox-cmd.t\E}, 'pod name ok';
like $trap->stdout, qr{DESCRIPTION\s+\QThis is a test sub command\E},
    'pod description ok';
like $trap->stdout,
    qr{SYNOPSIS\s+\Qmoox-cmd.t [-h] [long options ...]\E\s+\QThis is a test synopsis\E},
    'pod synopsis ok';
like $trap->stdout, qr{AUTHORS\s+\QCelogeek <me\E\@\Qcelogeek.com>\E},
    'pod author ok';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_cmd();
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 [-h]\E},
    'subcommand 1 help ok';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: test2\E},
    'sub subcommand 1 help ok';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options( command_chain => [] );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no subcommand pass';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options( command_chain => [123] );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no ref params';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options( command_chain => [ {} ] );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'bad ref';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options(
        command_chain => [ bless {}, 'MooX::Cmd' ] );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'bad ref';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options(
        command_chain => [ t::lib::MooXCmdTest->new ] );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'no command_name filled';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_options(
        command_chain =>
            [ t::lib::MooXCmdTest->new( command_name => 'mySub' ) ],
        command_commands => { a => 1, b => 2 }
    );
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t mySub [-h]\E},
    'subcommand with mySub name';
like $trap->stdout, qr{\QSUB COMMANDS AVAILABLE: a, b\E},
    'sub subcommand with mySub name';

trap {
    local @ARGV = ( 'test1', 'test2', '-h' );
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 test2 [-h]\E},
    'subcommand 2 ok';

done_testing;
