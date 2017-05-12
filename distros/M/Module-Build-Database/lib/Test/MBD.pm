package Test::MBD;

use Module::Build::Database;

use strict;
use warnings;

our $VERSION = '0.57';

sub import {
    my $class = shift;

    start() if grep { /^-autostart$/ } @_;
}

sub start {
    # NB: we could also just put this into ACTION_test, but then every test would start a db
    # instance (including e.g. pod-coverage).
    my $mbd = Module::Build::Database->current;
    $mbd->notes( leave_running => 1 );
    $ENV{MBD_QUIET} = 1;
    return if $mbd->notes("already_started") && $mbd->notes("dbtest_host");

    $mbd->depends_on("dbtest"); # runs ACTION_dbtest
    $mbd->notes(already_started => 1);
}

sub stop {
    warn "# stopping and cleaning test database\n";
    my $mbd = Module::Build::Database->current;
    $ENV{MBD_QUIET} = 1;
    $mbd->depends_on("dbclean");  # runs ACTION_dbclean
    $mbd->notes(already_started => 0);
    return 1;
}

1;

__END__

=head1 NAME

Test::MBD - Helper for testing Module::Build::Database apps

=head1 SYNOPSIS

 use Test::MBD '-autostart';  # Pass in autostart to auto start

 Test::MBD->start; # Starts a test database if not already up
 Test::MBD->stop;  # Stop and clean up the test database

=head1 DESCRIPTION

For L<Module::Build::Database> application tests, use Test::MBD in
each test case that needs the database.  Invokes C<./Build dbtest
--leave_running=1> to start up the test database if it isn't already
running and leaves it running.

Run C<Test::MBD-E<gt>stop> in your very last test case to shut down and clean
up after the test database with C<Build dbclean>.

=head1 SEE ALSO

L<Module::Build::Database>

=cut
