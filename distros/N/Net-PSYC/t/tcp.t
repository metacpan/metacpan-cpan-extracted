# vim:syntax=perl
#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 7;
# udp does not work yet.. fuck the system!

my $p_num = 0;
my $s_num = 0;
#use Net::PSYC qw(:event :base make_psyc send_mmp setDEBUG);
use Net::PSYC qw(Event=Event :base make_psyc send_mmp setDEBUG);

setDEBUG(0);

ok( register_uniform(), 'registering main::msg for all incoming packets' );
my $c = bind_uniform('psyc://127.0.0.1:c/'); 
ok( $c, 'binding a tcp port' );
exit unless($c);
my $target = sprintf('psyc://%s:%s', $c->{'IP'}, $c->{'PORT'});
print STDERR "\tI am $target\n";
sendmsg($target, '_notice_test_tcp', 'Hey there! That is a message for testing [_thing].', {_thing=>'tcp'});
# STATE
foreach (1 .. 6) {
    sendmsg($target, '_notice_test_state', 'testing state', {}, {_identification=>'YEAH!'});
}
sendmsg($target, '_notice_test_state', 'testing state', {}, {_identification=>'miuh'});
sendmsg($target, '_notice_test_state', 'testing state');
sendmsg($target, '_notice_test_state', 'testing state', {}, {_identification=>'YEAH!'});
# FRAGMENTS
my $data = make_psyc('_notice_test_fragments', "irgendwaslangesnichtsowichtig,nurnichtzukurz\n\n\rmitnewlinesdrin...\n");
my $l = int((length($data)/5) + 1);
send_mmp($target, [unpack("a$l a$l a$l a$l a$l", $data)], {_identification=>'lolli'});

ok( start_loop(), 'starting/stopping event loop' );
ok( $s_num == -1, 'MMP state' );

sub msg {
    my ($source, $mc, $data, $vars) = @_;
    $p_num++;

    if ($mc eq '_notice_test_tcp') {
	ok(1, 'sending/receiving psyc packets via tcp');
	ok( psyctext($data, $vars) eq 'Hey there! That is a message for testing tcp.', 'rendering psyc messages with psyctext()' );
    } elsif ($mc eq '_notice_test_state') {
	$s_num-= 2 if (!exists $vars->{'_identification'});
	$s_num++ if (exists $vars->{'_identification'} && $vars->{'_identification'} eq 'YEAH!');
	$s_num-= 6 if (exists $vars->{'_identification'} && $vars->{'_identification'} eq 'miuh');
    } elsif ($mc eq '_notice_test_fragments') {
	ok( $data eq "irgendwaslangesnichtsowichtig,nurnichtzukurz\n\n\rmitnewlinesdrin...\n"
	    && $vars->{'_identification'} eq 'lolli', 'sending fragments' );
	stop_loop();
    }
    return 1;
}

exit;
__END__
