
# Tests for pid related code. See code block labeled "PID Fun"

use warnings;
use strict;
use POE;
use Data::Dumper;
use Test::More tests => 10;

use_ok('POE::API::Peek');


SKIP: {

  my $ver = $POE::VERSION;
  $ver =~ s/_.+$//;
  skip "POE version less than 1.350 required for these tests", 9 unless $ver < '1.350';

  my $api = POE::API::Peek->new();

  POE::Session->create(
    inline_states => {
        _start => \&_start,
        _stop => \&_stop,
        dummy => sub {},

    },
    heap => { api => $api },
  );

  POE::Kernel->run();
}

exit 0;

###############################################

sub _start {
    my $sess = $_[SESSION];
    my $api = $_[HEAP]->{api};

    my $pid_count = eval { $api->session_pid_count };
    ok(!$@, "session_pid_count() causes no exceptions" );
    ok( defined $pid_count, "session_pid_count() returns data" );
    is( $pid_count, 0, "session_pid_count() knows that this session hasn't registered a PID" );
	POE::Session->create(
		inline_states => {
			_start => sub {
                my $new_pid_count = eval { $api->session_pid_count($sess) };
                ok(!$@, "session_pid_count(session) causes no exceptions" );
                is( $new_pid_count, $pid_count, "session_pid_count(session) knows that this session hasn't registered a PID" );
                $new_pid_count = eval { $api->session_pid_count($sess->ID) };
                ok(!$@, "session_pid_count(ID) causes no exceptions" );
                is( $new_pid_count, $pid_count, "session_pid_count(ID) knows that this session hasn't registered a PID" );
            },
            _stop => sub {},
        }
    );

    $poe_kernel->sig_child( $$ => 'dummy' );
    $pid_count = eval { $api->session_pid_count };
    is( $pid_count, 1, "session_pid_count() now counts one PID" );

    $poe_kernel->sig_child( $$ );
    $pid_count = eval { $api->session_pid_count };
    is( $pid_count, 0, "session_pid_count() now counts zero" );

}

sub _stop {


}
