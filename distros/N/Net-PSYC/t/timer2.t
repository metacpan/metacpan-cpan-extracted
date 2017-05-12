# vim:syntax=perl
#!/usr/bin/perl -w

use strict;
BEGIN {	
    unless (eval "require Event") {
	print "You don't have Event.pm installed. No Problem.\nSkipping this test.\n";
	exit;
    }
    require Test::Simple;
    import Test::Simple qw(tests 3);
    require Net::PSYC;
    import Net::PSYC qw(Event=Event);
}
my $c = 0;
my $f;

sub t {
    ok(1, 'Setting up timer-events with Event.pm.');
}

sub g {
    if ($c == 1) {
	ok(1, 'Setting up repeating timer-events.');
	$c++;
	add(2, 't', \&stop_loop);
	return 0;
    }
    ++$c;
}

add(0.5, 't', \&t);
add(1, 't', \&g, 1);
print "!\tIf nothing happens for more than 5 seconds,\n!\tterminate the test and report the failure!\n";
start_loop();
ok( $c == 2, 'Removing timer-event.');

__END__
