package Net::Syslog;

use vars qw($VERSION);
use warnings;
use strict;
use IO::Socket;
use Sys::Hostname;

$VERSION = '0.04';

# Preloaded methods go here.

my %syslog_priorities = (
    emerg         => 0,
    emergency     => 0,
    alert         => 1,
    crit          => 2,
    critical      => 2,
    err           => 3,
    error         => 3,
    warning       => 4,
    notice        => 5,
    info          => 6,
    informational => 6,
    debug         => 7
);

my %syslog_facilities = (
    kern      => 0,
    kernel    => 0,
    user      => 1,
    mail      => 2,
    daemon    => 3,
    system    => 3,
    auth      => 4,
    syslog    => 5,
    internal  => 5,
    lpr       => 6,
    printer   => 6,
    news      => 7,
    uucp      => 8,
    cron      => 9,
    clock     => 9,
    authpriv  => 10,
    security2 => 10,
    ftp       => 11,
    FTP       => 11,
    NTP       => 11,
    audit     => 13,
    alert     => 14,
    clock2    => 15,
    local0    => 16,
    local1    => 17,
    local2    => 18,
    local3    => 19,
    local4    => 20,
    local5    => 21,
    local6    => 22,
    local7    => 23,
);

my @month = qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};

sub new {
    my $class = shift;
    my $name  = $0;
    if ( $name =~ /.+\/(.+)/ ) {
        $name = $1;
    }
    my $self = {
        Name       => $name,
        Facility   => 'local5',
        Priority   => 'error',
        Pid        => $$,
        SyslogPort => 514,
        SyslogHost => '127.0.0.1'
    };
    bless $self, $class;
    my %par = @_;
    foreach ( keys %par ) {
        $self->{$_} = $par{$_};
    }
    return $self;
}

sub send {
    my $self  = shift;
    my $msg   = shift;
    my %par   = @_;
    my %local = %$self;
    foreach ( keys %par ) {
        $local{$_} = $par{$_};
    }

    my $pid = ( $local{Pid} =~ /^\d+$/ ) ? "\[$local{Pid}\]" : "";
    my $facility_i = $syslog_facilities{ $local{Facility} } || 21;
    my $priority_i = $syslog_priorities{ $local{Priority} } || 3;

    my $d = ( ( $facility_i << 3 ) | ($priority_i) );

    my $host = inet_ntoa( ( gethostbyname(hostname) )[4] );
    my @time = localtime();
    my $ts =
        $month[ $time[4] ] . " "
      . ( ( $time[3] < 10 ) ? ( " " . $time[3] ) : $time[3] ) . " "
      . ( ( $time[2] < 10 ) ? ( "0" . $time[2] ) : $time[2] ) . ":"
      . ( ( $time[1] < 10 ) ? ( "0" . $time[1] ) : $time[1] ) . ":"
      . ( ( $time[0] < 10 ) ? ( "0" . $time[0] ) : $time[0] );
    my $message = '';

    if ( $local{rfc3164} ) {
        $message = "<$d>$ts $host $local{Name}$pid: $msg";
    }
    else {
        $message = "<$d>$local{Name}$pid: $msg";
    }

    my $sock = new IO::Socket::INET(
        PeerAddr => $local{SyslogHost},
        PeerPort => $local{SyslogPort},
        Proto    => 'udp'
    );
    die "Socket could not be created : $!\n" unless $sock;
    print $sock $message;
    $sock->close();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::Syslog - Perl extension for sending syslog messages directly to a remote syslogd.

=head1 SYNOPSIS

  use Net::Syslog;
  my $s=new Net::Syslog(Facility=>'local4',Priority=>'debug');
  $s->send('see this in syslog',Priority=>'info');

=head1 DESCRIPTION

Net::Syslog implements the intra-host syslog forwarding protocol.
It is not intended to replace the Sys::Syslog or
Unix::Syslog modules, but instead to provide a method of using syslog when a
local syslogd is unavailable or when you don't want to write syslog messages
to the local syslog.

The new call sets up default values, any of which can be overridden in the
send call.  Keys (listed with default values) are:

	Name		<calling script name>
	Facility 	local5
	Priority 	error
	Pid		$$
	SyslogPort    	514
	SyslogHost    	127.0.0.1

Valid Facilities are:
  kernel, user, mail, system, security, internal, printer, news,
  uucp, clock, security2, FTP, NTP, audit, alert, clock2, local0,
  local1, local2, local3, local4, local5, local6, local7

Valid Priorities are:
  emergency, alert, critical, error, warning, notice, informational,
         debug

Set Pid to any non numeric value to disable in the output.

Use:
         rfc3164 => 1
 to enable RFC 3164 messages including timestamp and hostname.



=head1 AUTHOR

Les Howard, les@lesandchris.com

=head1 SEE ALSO

syslog(3), Sys::Syslog(3), syslogd(8), Unix::Syslog(3), IO::Socket, perl(1)

=cut
