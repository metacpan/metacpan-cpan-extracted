package PheMail::Server;

use 5.006;
use strict;
use warnings;
use Net::Server::Fork;
use Digest::MD5 qw(md5 md5_hex);
use PheMail::General;
use Unix::Syslog qw(:macros :subs);
use Math::XOR;
use vars qw( $whatsaid %peers $port $debug $restrict
	     $timeout $previous_alarm $timeout_sec $xor);

require Exporter;

our @ISA = qw(Exporter Net::Server::Fork);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PheMail::Server ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.04';

# Debug level (Defaults to 0)
$debug = 0;

# use XOR encryption?
$xor = 1;

# Restrict connection to mainserver only?
$restrict = 1;

# Timeout for client
$timeout_sec = 20;

# Open syslog descriptor
openlog("phemaild",LOG_PID,LOG_MAIL);

# Define portnumber here. Get it from the configfile.
$port = ReadConfig("daemonport");

# Preloaded methods go here.

sub do_log($$) {
    my($level,$msg) = @_;
    if ($level <= $debug) {
	syslog (LOG_INFO, "%s",$msg);
    }
}

sub ResolveHost($) {
    my $ipaddr= shift;
    return $ipaddr;
}

sub exor($) {
    my $string = shift;
    if (!$xor) { return $string; }
    my $enc = xor_buf($string,ReadConfig("salt"));
    return $enc;
}
sub process_request {
    my $self = shift;
    do_log(0,"connect ".ResolveHost($self->{server}->{'peeraddr'}));
    print "PheMaild ".$VERSION.": Hello ".$self->{server}->{'peeraddr'}."\r\n";
    if ($restrict) {
	if ($self->{server}->{'peeraddr'} ne ReadConfig("serverhost")) {
	    print "I'm gonna have to cut you off.\r\n";
	    print "I am only accepting trusted hosts.\r\nGoodbye.\r\n";
	    return;
	}
    }
    print "PheMaild ".$VERSION.": Ready.\r\n";
    print ":FOO:\r\n";
    $peers{$self->{server}->{'peeraddr'}} = "on";
    eval {
	while (<STDIN>) {
	    local $SIG{ALRM} = sub { 
		die;
	    };
	    $timeout = $timeout_sec; # give the user 30 seconds
	    $previous_alarm = alarm($timeout);
	    $_ =~ s/\r?\n//g;
	    $whatsaid = $_;
	    if($_ eq 'requestsalt') {
		print "salt=|".md5_hex(ReadConfig("salt"))."|:FOO:\r\n";
		do_log(0,ResolveHost($self->{server}->{'peeraddr'})." requested serversalt.");
		next;
	    }
	    if($_ eq 'xor') {
		if ($xor) {
		    print "xor=|xor|:FOO:\r\n";
		} else {
		    print "xor=|foo|:FOO:\r\n";
		}
		next;
	    }
	    if($_ eq 'noop') {
		print exor("ok")."\r\n";
		next;
	    }
	    if($_ eq 'who') {
		do_log(0,ResolveHost($self->{server}->{'peeraddr'})." Requesting who-list");
		print "clients=|";
		foreach my $client (keys %peers) {
		    print $client.",";
		}
		print "|:FOO:\r\n";
		next;
	    }
	    if($_ eq 'username') {
		print "username=|".exor(getpwuid($<))."|:FOO:\r\n";
		next;
	    }
	    if($_ eq 'load') {
		open(LOAD,"uptime|") or print "Couldn't open uptime: $!\r\n";
		while(<LOAD>) {
		    if (/^$/) { next; }
		    print "load=|".exor($1)."|:FOO:\r\n" if /load\s*averages?:\s(.+)$/;
		}
		close(LOAD);
		next;
	    }
	    if($_ eq 'uptime') {
		open(UPTIME,"uptime|") or print "Couldn't open uptime: $!\r\n";
		while(<UPTIME>) {
		    if (/^$/) { next; }
		    print "uptime=|".exor($1)."|:FOO:\r\n" if /up +(.*), +\d+ users?,/;
		}
		close(UPTIME);
		next;
	    }
	    if($_ eq 'whoareyou') {
		print "iam=|".exor(ReadConfig("whoami"))."|:FOO:\r\n";
		next;
	    }
	    if($_ eq 'quit') {
		do_log(0,"disconnect ".ResolveHost($self->{server}->{'peeraddr'}));    
		print "PheMaild ".$VERSION.": Goodbye.\n";
		return;
	    } else {
		do_log(3,ResolveHost($self->{server}->{'peeraddr'})." sent: ".$whatsaid);
	    }
	}
    alarm($previous_alarm); # initialize previous alarm
    };
    if($@=~/timed out/i){
	return;
    }
}
sub RunServer {
    __PACKAGE__->run(port => $port);
}
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

PheMail::Server - PheMail slaveserver

=head1 SYNOPSIS

  use PheMail::Server;
  PheMail::Server->RunServer();

=head1 DESCRIPTION

  Runs a server on a specified port, listening for connections from the mothership.
  This server is used in project PheMail for slaveservers.
  They can receive instructions from the mothership, via this server.
  All communication between the servers are explicitly encrypted in XOR.
  PLEASE NOTE: !! This should not be used outside PheMail as it would be useless !!


=head2 EXPORT

RunServer();


=head1 AUTHOR

Jesper Noehr, E<lt>jesper@noehr.orgE<gt>

=head1 SEE ALSO

L<PheMail::General>.

=cut
