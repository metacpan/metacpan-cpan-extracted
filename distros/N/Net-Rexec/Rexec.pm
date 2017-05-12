package Net::Rexec;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

use IO::Socket;
use Net::Netrc;
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(rexec);
$VERSION = '0.12';

# Preloaded methods go here.
sub rexec {
    my($host) = shift;
    my($sock) = IO::Socket::INET->new(PeerAddr => $host,
				      PeerPort => 'exec(512)',
				      Proto => 'tcp');
    die "Error opening sock $!" if (!defined($sock));
    $sock->syswrite("0\0", 2);
    my($cmd) = shift;
    my($user, $pswd);
    $user = shift if @_;
    $pswd = shift if @_;
    if (!defined($pswd)) {
	my $mach;
	if (defined($user)) {
	    $mach = Net::Netrc->lookup($host, $user);
	    die "Cannot find entry for $host, $user in netrc $!" if !defined($mach);
	    $pswd = $mach->password;
	} else {
	    $mach = Net::Netrc->lookup($host);
	    die "Cannot find $host in netrc $!" if !defined($mach);
	    $user = $mach->login;
	    $pswd = $mach->password;
	}
    }
    $sock->syswrite($user . "\0", length($user) + 1);
    $sock->syswrite($pswd . "\0", length($pswd) + 1);
    $sock->syswrite($cmd . "\0", length($cmd) + 1);
    my($result, $output, @return);
    $result = $sock->sysread($output, 1);
    if ($output eq chr(1)) {
	@return = (1, $sock->getline);
    } elsif ($output eq chr(0)) {
	@return = (0, $sock->getlines);
    } else {
	$output .= $sock->getline;
	@return = (2, $output);
    }
    wantarray ? @return : $return[0];
}

1;
__END__

=head1 NAME

Net::Rexec - Perl extension for the client side of the REXEC protocol.

=head1 SYNOPSIS

  use Net::Rexec 'rexec';
  ($rc, @output) = rexec(host, command, [userid, [password]]); 
  

=head1 DESCRIPTION

Invokes REXEC protocol to execute command on host using userid and password.
If userid or password are omitted then they are retrieved from the netrc file.
$rc is 0 if command was invoked on host, 1 otherwise unless the fork to invoke
command fails in which case it is 2.
Output is put into @output.

=head1 AUTHOR

Fila Kolodny <fila@ibi.com>.

=head1 SEE ALSO

Net::Netrc(3pm).

=cut
