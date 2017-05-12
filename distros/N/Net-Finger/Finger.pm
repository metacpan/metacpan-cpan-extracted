##################################################################
#                                                                #
#  Net::Finger, a Perl implementation of a finger client.        #
#                                                                #
#  By Dennis "FIMM" Taylor, <corbeau@execpc.com>                 #
#                                                                #
#  This module may be used and distributed under the same terms  #
#  as Perl itself. See your Perl distribution for details.       #
#                                                                #
##################################################################
# $Id$

package Net::Finger;

use strict;
use Socket;
use Carp;
use vars qw($VERSION @ISA @EXPORT $error $debug);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( &finger );

$VERSION = '1.06';
$debug = 0;


# I know the if ($debug) crap gets in the way of the code a bit, but
# it's a worthy sacrifice as far as I'm concerned.

sub finger {
    my ($addr, $verbose) = @_;
    my ($host, $port, $request, @lines, $line);

    unless (@_) {
        carp "Not enough arguments to Net::Finger::finger()";
    }

    # Set the error indicator to something innocuous.
    $error = "";

    $addr ||= '';
    if (index( $addr, '@' ) >= 0) {
        my @tokens = split /\@/, $addr;
        $host = pop @tokens;
        $request = join '@', @tokens;
        
    } else {
        $host = 'localhost';
        $request = $addr;
    }

    if ($verbose) {
        $request = "/W $request";
    }

    if ($debug) {
        warn "Creating a new socket.\n";
    }

    unless (socket( SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
        $error = "Can\'t create a new socket: $!";
        return;
    }
    select SOCK;  $| = 1;  select STDOUT;

    $port = ($host =~ s/:([0-9]*)$// && $1) ? $1 :
	                (getservbyname('finger', 'tcp'))[2];
	
    if ($debug) {
        warn "Connecting to $host, port $port.\n";
    }

    unless (connect( SOCK, sockaddr_in($port, inet_aton($host)) ))
    {
        $error = "Can\'t connect to $host: $!";
        return;
    }

    if ($debug) {
        warn "Sending request: \"$request\"\n";
    }

    print SOCK "$request\015\012";

    if ($debug) {
        warn "Waiting for response.\n";
    }

    while (defined( $line = <SOCK> )) {
	$line =~ s/\015?\012/\n/g;    # thanks (again), Pudge!
	push @lines, $line;
    }

    if ($debug) {
        warn "Response received. Closing connection.\n";
    }

    close SOCK;
    return( wantarray ? @lines : join('', @lines) );
}



1;
__END__

=head1 NAME

Net::Finger - a Perl implementation of a finger client.

=head1 SYNOPSIS

  use Net::Finger;

  # You can put the response in a scalar...
  $response = finger('corbeau@execpc.com');
  unless ($response) {
      warn "Finger problem: $Net::Finger::error";
  }

  # ...or an array.
  @lines = finger('corbeau@execpc.com', 1);

=head1 DESCRIPTION

Net::Finger is a simple, straightforward implementation of a finger client
in Perl -- so simple, in fact, that writing this documentation is almost
unnecessary.

This module has one automatically exported function, appropriately
entitled C<finger()>. It takes two arguments:

=over

=item *

A username or email address to finger. (Yes, it does support the
vaguely deprecated "user@host@host" syntax.) If you need to use a port
other than the default finger port (79), you can specify it like so:
"username@hostname:port".

=item *

(Optional) A boolean value for verbosity. True == verbose output. If
you don't give it a value, it defaults to false. Actually, whether
this output will differ from the non-verbose version at all is up to
the finger server.

=back

C<finger()> is context-sensitive. If it's used in a scalar context, it
will return the server's response in one large string. If it's used in
an array context, it will return the response as a list, line by
line. If an error of some sort occurs, it returns undef and puts a
string describing the error into the package global variable
C<$Net::Finger::error>. If you'd like to see some excessively verbose
output describing every step C<finger()> takes while talking to the
other server, put a true value in the variable C<$Net::Finger::debug>.

Here's a sample program that implements a very tiny, stripped-down
finger(1):

    #!/usr/bin/perl -w

    use Net::Finger;
    use Getopt::Std;
    use vars qw($opt_l);

    getopts('l');
    $x = finger($ARGV[0], $opt_l);

    if ($x) {
        print $x;
    } else {
        warn "$0: error: $Net::Finger::error\n";
    }

=head1 BUGS

=over

=item *

Doesn't yet do non-blocking requests. (FITNR. Really.)

=item *

Doesn't do local requests unless there's a finger server running on localhost.

=item *

Contrary to the name's implications, this module involves no teledildonics.

=back

=head1 AUTHOR

Dennis Taylor, E<lt>corbeau@execpc.comE<gt>

=head1 SEE ALSO

perl(1), finger(1), RFC 1288.

=cut
