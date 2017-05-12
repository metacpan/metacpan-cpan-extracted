#!perl -T

use Test::More tests => 9;
use File::Spec;
use Script::Daemonizer;

my $gid = (split " ", $( )[0];
my $user  = getpwuid($<);
my $euser = getpwuid($>);
my $group = getgrgid($gid);

# ------------------------------------------------------------------------------
# Call drop_privileges() with parameters passed to the function
# ------------------------------------------------------------------------------
eval qq(
    my \$daemon = new Script::Daemonizer();

    \$daemon->drop_privileges(
        euid => $>,
        egid => $gid,
        uid  => $<,
        gid  => $gid,
    );

);

ok (! $@, "call to drop_privileges() with explicit parameters failed: $@");


# ------------------------------------------------------------------------------
# Call drop_privileges() with parameters passed to the constructor
# ------------------------------------------------------------------------------
eval qq(
    my \$daemon = new Script::Daemonizer(
        drop_privileges => {
            euid => $>,
            egid => $gid,
            uid  => $<,
            gid  => $gid,
        },
    );

    \$daemon->drop_privileges();
);

ok (! $@, "call to drop_privileges() with implicit parameters failed: $@");

# ------------------------------------------------------------------------------
# Call drop_privileges() with names instead of numerical values
# ------------------------------------------------------------------------------
SKIP: {

    skip("No login name, skipping drop_privileges() test with names", 1)
        unless defined $user && defined $euser && defined $group;

    eval qq(
        my \$daemon = new Script::Daemonizer(
            drop_privileges => {
                euser  => '$user',
                egroup => '$group',
                user   => '$euser',
                group  => '$group',
            },
        );

        \$daemon->drop_privileges();
    );

    ok (! $@, "call to drop_privileges() with names failed: $@");
}

# ------------------------------------------------------------------------------
# Call _write_pidfile()
# ------------------------------------------------------------------------------
my $pidfile = File::Spec->catfile( File::Spec->curdir, "test_pid_file.pid" );
eval qq(
    my \$daemon = new Script::Daemonizer (
        pidfile => '$pidfile',
    );

    \$daemon->_write_pidfile();
);

ok (! $@, "method _write_pidfile fails: $@");
unlink $pidfile
    if -f $pidfile;


# ------------------------------------------------------------------------------
# Call _set_umask()
# ------------------------------------------------------------------------------
eval q(
    Script::Daemonizer->new->_set_umask();
);

ok (! $@, "method _set_umask fails: $@");


# ------------------------------------------------------------------------------
# Call fork() - cannot test _fork(), we would detach from this process
# ------------------------------------------------------------------------------
$SIG{CHLD} = 'IGNORE';
my $pid = fork();

if (defined( $pid )) {
    exit 0 unless $pid;     # Child exits here
    pass("fork() works");   # Parent passes the test
} else {
    fail("unable to fork(): $!");
}


# ------------------------------------------------------------------------------
# Call _setsid()
# ------------------------------------------------------------------------------
eval q(
    Script::Daemonizer->new->_setsid();
);

ok (! $@, "method _setsid fails: $@");


# ------------------------------------------------------------------------------
# Call _manage_stdhandles()
# ------------------------------------------------------------------------------
my $output = File::Spec->catfile( File::Spec->curdir, "test.out" );
eval qq(
    my \$daemon = new Script::Daemonizer (
         output_file => '$output',
    );
    \$daemon->_manage_stdhandles();
);

ok (! $@, "method _manage_stdhandles fails: $@");
unlink $output
    if -f $output;

# ------------------------------------------------------------------------------
# Call _chkdir() - last, because we change directory and won't come back
# ------------------------------------------------------------------------------
eval q(
    Script::Daemonizer->new->_chdir();
);

ok (! $@, "method _chdir fails: $@");
