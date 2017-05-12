use strict;
use warnings;

use Test::More tests => 25;
use Test::Fatal;

BEGIN {
    use_ok('MooseX::Daemonize::Pid::File');
}

{
    my $f = MooseX::Daemonize::Pid::File->new(
        file => [ 't', 'foo.pid' ]
    );
    isa_ok($f, 'MooseX::Daemonize::Pid::File');

    isa_ok($f->file, 'Path::Class::File');

    is($f->pid, $$, '... the PID is our current process');

    is(
        exception { $f->write },
        undef,
        '... writing the PID file',
    );

    is($f->file->slurp(chomp => 1), $f->pid, '... the PID in the file is correct');

    ok($f->is_running, '... it is running too');

    is(
        exception { $f->remove },
        undef,
        '... removing the PID file',
    );

    ok(!-e $f->file, '... the PID file does not exist anymore');
}

{
    my $f = MooseX::Daemonize::Pid::File->new(
        file => [ 't', 'bar.pid' ]
    );
    isa_ok($f, 'MooseX::Daemonize::Pid::File');

    isa_ok($f->file, 'Path::Class::File');

    is(
        exception { $f->write },
        undef,
        '... writing the PID file',
    );

    is($f->file->slurp(chomp => 1), $f->pid, '... the PID in the file is correct');
    is($f->pid, $$, '... the PID is our current process');

    ok($f->is_running, '... it is running too');

    is(
        exception { $f->remove },
        undef,
        '... removing the PID file',
    );

    ok(!-e $f->file, '... the PID file does not exist anymore');
}

{
    # find a pid that doesn't currently exist - start by looking at our own
    # and going backwards (not 100% reliable but better than hardcoding one)
    my $PID = $$;
    do { $PID--; $PID = 2**32 if $PID < 1 } while kill(0, $PID);
    diag 'assigning the non-existent pid ' . $PID;

    my $f = MooseX::Daemonize::Pid::File->new(
        file => [ 't', 'baz.pid' ],
        pid  => $PID,
    );
    isa_ok($f, 'MooseX::Daemonize::Pid::File');

    isa_ok($f->file, 'Path::Class::File');

    is($f->pid, $PID, '... the PID is our made up PID');

    is(
        exception { $f->write },
        undef,
        '... writing the PID file',
    );

    is($f->file->slurp(chomp => 1), $f->pid, '... the PID in the file is correct');

    ok(!$f->is_running, '... it is not running (cause we made the PID up)');

    is(
        exception { $f->remove },
        undef,
        '... removing the PID file',
    );

    ok(!-e $f->file, '... the PID file does not exist anymore');
}
