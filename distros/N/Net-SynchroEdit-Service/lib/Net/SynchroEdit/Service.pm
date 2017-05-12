package Net::SynchroEdit::Service;

use 5.008004;
use strict;
use warnings;
use IO::Select;
use IO::Socket;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::SynchroEdit ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
 
SE_ERR_CONNECTION_FAILED SE_ERR_INVALID_WELCOME SE_ERR_STREAM_CLOSED SE_ERR_DOCUMENT_NOT_FOUND SE_ERR_DOCUMENT_UNINITIALIZED SE_ERR_UNRECOGNIZED_REPLY SE_ERR_DOCUMENT_INITIALIZED SE_ERR_DOCUMENT_IN_SESSION SE_ERR_DOCUMENT_OPEN SE_ERR_FAILED_INSTANTIATION SE_ERR_FAILED_MOVING_UPLOAD SE_ERR_FAILED_SOURCE_COPY SE_ERR
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

# Error codes
use constant SE_ERR_CONNECTION_FAILED      => 1;
use constant SE_ERR_INVALID_WELCOME        => 2;
use constant SE_ERR_STREAM_CLOSED          => 3;
use constant SE_ERR_DOCUMENT_NOT_FOUND     => 4;
use constant SE_ERR_DOCUMENT_UNINITIALIZED => 5;
use constant SE_ERR_UNRECOGNIZED_REPLY     => 6;
use constant SE_ERR_DOCUMENT_INITIALIZED   => 7;
use constant SE_ERR_DOCUMENT_IN_SESSION    => 8;
use constant SE_ERR_DOCUMENT_OPEN          => 9;
use constant SE_ERR_FAILED_INSTANTIATION   => 10;
use constant SE_ERR_FAILED_MOVING_UPLOAD   => 11;
use constant SE_ERR_FAILED_SOURCE_COPY     => 12;
use constant SE_ERR                        => 999;


our $VERSION = '0.039';
our @buf     = ();
our %lastSessions;

# Constructor.
#
sub new {
    my $package = shift;
    return bless({}, $package);
}

# Connect to the service.
# Returns true on success and false on failure.
#
### connect([host[, port[, user[, pass]]]])
sub connect {
    my $self = shift;

    # Reset internal vars.
    $self->{'queries'} = 0;
    $self->{'connected'} = 0;
    @buf     = ();
    $self->{'bchop'} = "";
    $self->{'host'}  = "localhost"; 
    $self->{'port'}  = 7962;
    $self->{'user'}  = "root";
    $self->{'pass'}  = "secret";

    # Acquire arguments, if any.
    $self->{'host'} = shift if @_;
    $self->{'port'} = shift if @_;
    $self->{'user'} = shift if @_;
    $self->{'pass'} = shift if @_;

    # Create new socket to service.
    my $stream = new IO::Socket::INET
	(PeerAddr => $self->{'host'},
	 PeerPort => $self->{'port'},
	 Proto    => "tcp",
	 );
    return unless $stream;
    
    $self->{'stream'} = $stream;

    # Create select.
    $self->{'select'} = new IO::Select();
    $self->{'select'}->add($self->{'stream'});

    # Read welcome string.
    ($self->{'reader'}) = $self->{'select'}->can_read(10);
    return if not defined $self->{'reader'};
    $self->{'reader'}->sysread($self->{'welcome'}, 1024);

    # Mark us as connected.
    $self->{'connected'} = 1;

    # Send login information.
    print $stream "USER $self->{'user'}\nPASS $self->{'pass'}\n";

    # Fetch information about server.
    return unless $self->fetch_info;
    return 1;
}

# Shutdown a specific session by SID in $timer minutes.
#
### shutdown(SID[, timer])
sub shutdown {
    my $self  = shift;
    my $sid   = shift;
    my $timer = 0;
    $timer = shift if @_;

    return unless $self->query("SHUTDOWN $sid"); # XXX: $timer is currently ignored.
    # my @result = ;
    return unless $self->fetch_status eq "ACK";
    return 1;
}

# Disconnect from response service.
#
### disconnect()
sub disconnect {
    my $self = shift;

    return unless $self->{'connected'};
    close $self->{'stream'};
    undef $self->{'connected'};
    return 1;
}

# Request a list of existing sessions. If $extended is true, an additional STATUS request is sent
# per document.
# On success, returns a map with a set of values. The "SIDS" key contains a list of the sessions,
# space-separated. The data of a particular session can be retrieved using the get() method.
# If $extended, each entry additionally contains AGE, USERS, CONTRIBUTORS, DOCSIZE.
#
### sessions([$extended = 0])
sub sessions {
    my $self = shift;
    
    my $extended = 0;
    $extended = shift if @_;

    return unless defined $self->query("QUERY");
    my @result = $self->fetch_result;
    my $ix     = $#result+1;
    return if $ix == 1;
    my %retval;
    my $i;
    for ($i = 0; $i < $ix; $i++) {
	my @docexpr = split(/ /, $result[$i++]);
	my @isexpr  = split(/ /, $result[$i]);
	shift @docexpr;
	my $doc     = join(" ", @docexpr);
	shift @isexpr;
	my $sid = shift @isexpr;
	$retval{"$sid-DOCUMENT"} = $doc;
	$retval{"$sid-PORT"} = shift @isexpr;
	$retval{"$sid-FLAGS"} = shift @isexpr;
	if ($extended) {
	    $self->query("STATUS $sid");
	    my %edata = $self->fetch_map;
	    $retval{"$sid-AGE"}          = $edata{'AGE'};
	    $retval{"$sid-USERS"}        = $edata{'USERS'};
	    $retval{"$sid-CONTRIBUTORS"} = $edata{'CONTRIBUTORS'};
	    $retval{"$sid-DOCSIZE"}      = $edata{'DOCSIZE'};
	}
	if (defined $retval{'SIDS'}) {
	    $retval{'SIDS'} = "$retval{'SIDS'} $sid";
	} else {
	    $retval{'SIDS'} = "$sid";
	}
    }
    %lastSessions = %retval;
    return %retval;
}

# Get the shortened variables for a particular sessions session.
#
### get($sid)
sub get {
    my $self = shift;
    my %hashmap = %lastSessions;
    my $sid = shift;

    my %result = ('DOCUMENT',     $hashmap{"$sid-DOCUMENT"},
		  'PORT',         $hashmap{"$sid-PORT"},
		  'FLAGS',        $hashmap{"$sid-FLAGS"},
		  'AGE',          $hashmap{"$sid-AGE"},
		  'USERS',        $hashmap{"$sid-USERS"},
		  'CONTRIBUTORS', $hashmap{"$sid-CONTRIBUTORS"},
		  'DOCSIZE',      $hashmap{"$sid-DOCSIZE"});
    return %result;
}

# Perform service query.
#
### query($cmd)
sub query {
    my $self = shift;

    # Acquire arguments, if any.
    return unless @_;
    my $cmd = shift;
    $self->{'queries'}++;
    return unless $self->{'connected'};
    my $stream = $self->{'stream'};
    print $stream "$cmd\n";
    return 1;
}

# Fill buffer.
sub _fillbuf {
    my $self  = shift;
    my $bchop = $self->{'bchop'};
    my $line  = "";
    $self->{'reader'}->sysread($line, 4096);
    $line = "$bchop$line";
    push(@buf, split(/\n/, $line));
    if (substr($line, (length $line)-1, 1) ne "\n") {
	$bchop = pop @buf;
	print "substr caught unended line; chopping off '$bchop' from '$line'\n";
    }
    $self->{'bchop'} = $bchop;
}

# Get next line.
# NOTE: This function requires that either 
# 1) a new line is buffered, or 
# 2) there is data from the server waiting.
# If neither 1 nor 2, the code will hang for a while,
# until new data is available, which probably is never.
sub _nextline {
    my $self = shift;
    if (!@buf) {
	$self->_fillbuf;
    }
    return shift @buf;
}

# Read the next pending result, if any.
#
### fetch_result()
sub fetch_result {
    my $self = shift;

    return unless $self->{'connected'};
    return unless $self->{'queries'} > 0;

    $self->{'queries'}--;
    my @result;
    my $line;
    while (($line = $self->_nextline) && $line ne "END") {
	push(@result, $line);
    }
    return @result;
}

# Fetch the first line only in a pending result.
# The remaining data, if any, is discarded.
#
### fetch_status()
sub fetch_status {
    my $self = shift;

    my @result = $self->fetch_result;
    return unless @result;
    return shift @result;
}

# Return the next pending result as a hashmap.
# This is only supported when the response is a list of keys
# and values in the format "KEY VALUE\nKEY2 VALUE2\n..."
#
### fetch_map()
sub fetch_map {
    my $self = shift;

    my @query  = $self->fetch_result;
    my %result;
    my $line;
    my @pair;
    while ($line = shift @query) {
	@pair = split(/ /, $line, 2);
	if ($#pair != 1) {
	    # The result most likely failed, so we set the _ key to $line.
	    $result{'_'} = $line;
	} else {
	    $result{$pair[0]} = $pair[1];
	}
    }
    return %result;
}

# Re-fetch information from service. 
# Returns success boolean.
#
### fetch_info()
sub fetch_info {
    my $self = shift;
    
    return unless $self->query("INFO");

    my %result = $self->fetch_map;
    return if $result{'_'};
    $self->{'localPath'}   = $result{'LOCALPATH'};
    $self->{'uptime'}      = $result{'UPTIME'};
    $self->{'serverModel'} = $result{'SERVERMODEL'};
    return 1;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::SynchroEdit::Service - Perl extension for SynchroEdit response service functionality

=head1 SYNOPSIS

  use Net::SynchroEdit::Service;
  
  my $conn = new Net::SynchroEdit::Service;
  $conn->connect("localhost", 7962, "root", "secret");

=head1 DESCRIPTION

Net::SynchroEdit::Service provides a complete set of methods for manipulating a SynchroEdit server via the response service. The optional Net::SynchroEdit::Controller and Net::SynchroEdit::Session modules can be used in conjunction with the Service module to acquire e.g. the create_from_file method (Controller).

=head2 METHODS

=over 4

=item * $conn->connect([$host = "localhost"[, $port = 7962[, $user = "root"[, $pass = "secret"]]]])

Connect to a SynchroEdit response service. Returns 1 if connection established.

=item * $conn->disconnect()

Disconnect from connected response service.

=item * $conn->sessions([$extended = 0])

Request a list of existing sessions on the SynchroEdit server. If $extended is set (1), an additional STATUS
request is sent per document.
On success, returns a map with a set of values. The "SIDS" key contains a list of the sessions, space-separated.
The data of a particular session can be retrieved using the get() method.
If $extended, each entry additionally contains AGE, USERS, CONTRIBUTORS, and DOCSIZE.
See $conn->get() below for further information.

=item * $conn->get($sid)

Acquire a hashmap based on the most recently made sessions()-call for the specified session. 
The following keys will be available always (presuming the session identifier is valid): "DOCUMENT", "PORT", "FLAGS"
The following keys will be available if the sessions()-call was extended: "AGE", "USERS", "CONTRIBUTORS", "DOCSIZE"

=item * $conn->query($cmd)

Perform a query directly to the response service. For detailed information on what queries there are, how they work, and why they exist, see http://wiki.synchroedit.com/index.php/SessionProtocol

Note that the query() function returns 1 on success. No query handlers exist, but the results of each query is simply retrieved in the order they were made.

Wrong:
  my $qid = $conn->query("QUERY");
  my $status = $conn->fetch_status($qid);

Right:
  $conn->query("QUERY");
  my $status = $conn->fetch_status();

=item * $conn->fetch_result()

Get the next pending result as an array. Each element in the array corresponds to one line in the response service response. The "END" statement is not included in the resulting array but is used to determine where the array ends.

=item * $conn->fetch_status()

Fetch the first line only in a pending result.
The remaining data, if any, is discarded.

=item * $conn->fetch_map()

Return the next pending result as a hashmap.
This is only supported when the response is a list of keys and values in the format "KEY VALUE\nKEY2 VALUE2\n..."

=item * $conn->shutdown($SID[, $timer = 0])

Shut the specified session down in $timer minutes.

=item * $conn->fetch_info()

Re-fetch information from service, about service.
Returns 1 if successful. The information is stored in the instance itself, and is available as: $conn->{'localPath'}, $conn->{'uptime'} and $conn->{'serverModel'}

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

See the documentation page for Net::SynchroEdit::Controller and Net::SynchroEdit::Session.

This module was written by the SynchroEdit team who're at http://www.synchroedit.com/.

There is a wiki at: http://wiki.synchroedit.com/.

=head1 KNOWN BUGS

The $timer argument to the shutdown functionality is currently not working. Sessions are shut down immediately, regardless of its value.

=head1 AUTHOR

Kalle Alm <kalle@enrogue.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alacrity Management Corp.

Version: MPL 1.1/LGPL 2.1

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is SynchroEdit (www.synchroedit.com).

The Initial Developer of the Original Code is
Kalle Alm (kalle@enrogue.com).
Portions created by the Initial Developer are Copyright (C) 2006
Alacrity Management Corporations. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of
the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
in which case the provisions of the LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of the LGPL, and not to allow others to
use your version of this file under the terms of the MPL, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the LGPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the MPL or the LGPL.

=cut
