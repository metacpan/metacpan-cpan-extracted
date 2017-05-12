# -*- perl -*-

# Net::FTPServer::PWP::Server - FTP server suitable for PWP services

# $Id: Server.pm,v 1.30 2003/04/01 15:50:42 lem Exp $

=pod

=head1 NAME

Net::FTPServer::PWP::Server - The FTP server for PWP (personal web pages) service.

=head1 SYNOPSIS

  ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::PWP::Server> is a FTP server
personality. This personality implements a complete
FTP server with special functionalities in order to 
provide a PWP service implementation.

The features provided include:

=over

=item *

Directory quotas

=item *

Authentication using the RADIUS protocol

=item *

Configurable root directory

=back

=head2 CONFIGURATION

A few config file entries have been added, as described below:

=over

=item B<pwp root subdir>

If specified, tacks its contents to the root directory obtained
through RADIUS. This allows the contraining of the user to a part of
her home directory.

=item B<default pwp quota>

Defaults to C<-1> or unlimited. Is the number of octets allocated
by default to users.

=item B<pwp quota cache secs>

Controls how often the FTP server will invalidate its notion of the
current space consumption. This allows performance tuning. Use a
larger value where a small number of concurrent (same user) sessions
are expected. Use a smaller value in the oposite case. Finding out
what 'larger' and 'smaller' means is left as an excercise for the
reader.

A smaller value causes each FTP server to scan the whole user
directory more often (actually, every time the number of seconds
specified passes).

=item B<pwp quota exceeded message>

The message to return to the user when her quota is exceeded. Defaults
to B<This operation would exceed your quota>.

=item B<pwp quota file>

The name of the quota file to use. Defaults to C<../$user-pwpquota>, which
places the quota file just above the PWP directory at the home dir of
each user using a name composed of the user name plus '-pwpquota'.

You can use variables such as C<$hostname>, C<$username>, etc. within
its specification. Note that the quota file is specified relative to
the PWP directory of the user, but is not subjected to the jail
limitations. This allows the quota file to be placed outside the PWP
directories.

=item B<pwp max quota file age>

Maximum age in seconds that the quota file can have, before requiring
it to be rebuilt.

=item B<pwp max quota file lines>

Maximum amount of entries in the quota file before forcing it to be
rebuilt.

=item B<radius realm>

The realm used for authenticating users. Defaults to 'pwp'.

=item B<radius server>

RADIUS server (or comma separated list of servers) to send requests
to. It is an error to not specify at least, a RADIUS server.

=item B<radius port>

The port to direct the RADIUS request. Defaults to 1645.

=item B<radius secret>

The secret used to authenticate against the RADIUS server. Not
specifying it is an error.

=item B<radius dictionary>

The RADIUS dictionary file used to encode and decode the RADIUS
request. It defaults to C</usr/local/lib/pwp-dictionary>.

=item B<radius timeout>

The amount of time we will wait for an answer from a RADIUS
server. After this many seconds, the server is skipped and the next
one is tried.

=item B<pwp radius vendor id>

The vendor-id used in the Vendor-Specific Attributes sent and received
from the RADIUS server. The dafault is 582. The value specified here
must match the one used in your dictionary files.

=item B<hide mount point>

When true, instructs the FTP server to attempt to hide the actual
mount point from the client. This forms a sort of jail similar to what
C<chroot()> imposes, but without the need to replicate system files to
the C<chroot()>-ed environment.

=back

=head1 METHODS

=over 4

=cut

package Net::FTPServer::PWP::Server;

use strict;

use vars qw($VERSION $t0);

# $t0 is used as a timestamp for the RADIUS response if debug is
# enabled

$VERSION = '1.21';

use IO::Select;
use Net::FTPServer;
use NetAddr::IP 3.00;
use IO::Socket::INET;
use Net::Radius::Packet;
use Net::Radius::Dictionary;
use Net::FTPServer::PWP::DirHandle;
use Net::FTPServer::PWP::FileHandle;
use Net::FTPServer::Full::DirHandle;
use Time::HiRes qw(gettimeofday tv_interval);;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

=pod

=item $rv = $self->authentication_hook ($user, $pass, $user_is_anon)

Perform login authentication against a RADIUS server. We also take
this opportunity to insert our very own handler for the DELE
command. This is required to properly keep track of the disk usage of
the user. Our handler is called C<_DELE_command> and is documented
below.

We also hardcode the SITE QUOTA command to allow the user to check her
quota. This is done with C<_SITE_QUOTA_command>, documented
below. Note that this will conflict with locally defined handlers for
the SITE QUOTA command.

=cut
    
sub authentication_hook {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $anon = shift;

#      $self->log('err', "Authenticating as part of the test");
#      warn "Authenticating as part of the test\n";
#      $self->{pwp_root_dir} = '/h/R/e/n/t/lem';
#      $self->{pwp_quota} = 5_000_000;
#      $self->{pwp_root_dir} =~ s![^-/\w\._\d]!!g;
#      $self->{pwp_root_dir} =~ m!^(.*)$!;
#      $self->{pwp_root_dir} = $1;
#      $self->{pwp_root_dir} .= '/' unless $self->{pwp_root_dir} =~ m!/$!;
#      $self->{pwp_root_dir} .= $self->config('pwp root subdir') || '';
#      $self->{pwp_root_dir} .= '/' unless $self->{pwp_root_dir} =~ m!/$!;
#      $self->{command_table}{DELE} = \&_DELE_command;
#      $self->{site_command_table}{QUOTA} = \&_SITE_QUOTA_command;
#      return 0;

    $self->log('debug',"Authenticating PWP login $user")
	if $self->config('debug');

    return -1 if $anon;
    
    if ($self->_auth_client ($user, $pass) == -1) {
	$self->log('debug',"Authentication failed for $user")
	    if $self->config('debug');
	return -1;
    }

    if ($self->_auth_client ($user, $pass) < 0) {
	$self->log('debug',"Authentication problem for $user")
	    if $self->config('debug');
	return -2;
    }

    $self->log('debug',"Login $user authenticated")
	if ($self->config('debug'));

				# Since everything went well, add our very
				# own DELE and SITE QUOTA handlers, which
				# handle the quotas

    $self->{site_command_table}{QUOTA}	= \&_SITE_QUOTA_command;
    $self->{command_table}{DELE}	= \&_DELE_command;
    
    return 0;
}

# subroutine to make string of 16 random bytes
sub _bigrand() {
    pack "n8",
    rand(65536), rand(65536), rand(65536), rand(65536),
    rand(65536), rand(65536), rand(65536), rand(65536);
}

				# This is based in the authclient that
				# ships as an example with the Net::Radius
				# module.

sub _auth_client {
    my $self     = shift;
    my $user     = shift;
    my $passwd   = shift;
    
    my $realm    = $self->config("radius realm")      || 'pwp'; 
    my $servport = $self->config("radius port")       || 1645;
    my $secret   = $self->config("radius secret");
    my $timeout  = $self->config("radius timeout")    || 6;
    my @servers  = split(/\s*,\s*/,$self->config("radius server"));
    my $dictfile = $self->config("radius dictionary") || 
	'/usr/local/lib/pwp-dictionary';

    unless (@servers and $secret) {
	die "Must specify RADIUS server in config file using ",
	"'radius server:'\n";
    }
    
    # Parse the RADIUS dictionary file
    my $dict = new Net::Radius::Dictionary $dictfile
	or $self->log('err',"Couldn't read dictionary: $!") 
	    and return -2;
    
    my $ident = int(rand(256));

    foreach my $server (@servers) {

	my $ip = new NetAddr::IP $server;

	my $req;		# Our RADIUS request
	my $rec;		# Data from a recv() call
	my $resp;		# Response from the RADIUS server

	unless ($ip) {
	    $self->log('err', 
		       "Can't obtain IP address for $server");
	    next;
	}

	# Server socket
	my $s = new IO::Socket::INET ( PeerHost => $ip->addr,
				       PeerPort => $servport,
				       Proto => 'udp'
				      );

	unless ($s) {
	    $self->log('err', 
		       "Can't create socket for $server");
	    next;
	}

	my $sel = new IO::Select;
	$sel->add($s);

	# Create a request packet
	$req = new Net::Radius::Packet $dict;
	$req->set_code('Access-Request');

	$req->set_attr('User-Name' => $user . '@' . $realm);
	$req->set_vsattr($self->config('pwp radius vendor id') || 582, 
			 'realm', "$realm\0");

	$ident += 1;
	$ident %= 256;

	$req->set_identifier($ident);
	$req->set_authenticator(_bigrand);   # random authenticator required
	$req->set_password($passwd, $secret); # encode and store password


	# Show RADIUS packet to STDERR if debug is on

	$t0 = [gettimeofday];	# Used to time responses or lack of.

	if ($self->config("debug")) {
	    warn "Request RADIUS packet \n", $req->str_dump;
	}

	# Send to the server. Encoding with auth_resp is NOT required.
	unless ($s->send($req->pack)) {
	    $self->log('err', "Failed to send request to $server: $!");
	    next;
	}
	
	# wait for response and potentially, retry if too many time
	# elapses...

	unless ($sel->can_read($timeout))
	{
	    my $elapsed = sprintf("%0.04f", tv_interval ( $t0 ));
	    $self->log('warning', 
		       "Timeout on RADIUS server $server after " .
		       "$elapsed seconds");
	    next;
	}

	unless (defined $s->recv($rec, 8192)) {
	    $self->log('err', 
		       "Problem receiving packet from $server: $!");
	    next;
	}

	$resp = new Net::Radius::Packet $dict, $rec;
	
	# RADIUS packet debugging
	if ($self->config("debug")) {   
	    my $elapsed = sprintf("%0.04f", tv_interval ( $t0 ));
	    warn "Response RADIUS packet in $elapsed seconds\n", 
	    $resp->str_dump;
	}

				# XXX - Our check should be stronger than
				# this...

	if ($resp->identifier != $ident) {
	    $self->log('warning',
		       "Got answer from $server with invalid identifier");
	    next;
	}

	if ($resp->code eq 'Access-Accept') {
	    my $vsa;

				# Extract the home directory from the RADIUS
				# response

	    $vsa = $resp->vsattr($self->config('pwp radius vendor id') || 582, 
				 'homedir');

	    $self->{pwp_root_dir} = $vsa->[0] if $vsa;

				# Extract the quota from the RADIUS response

	    $vsa = $resp->vsattr($self->config('pwp radius vendor id') || 582, 
				 'quota');

	    $self->{pwp_quota} = $vsa->[0] * 1_000_000 if $vsa;
	    
	    unless ($self->{pwp_root_dir}) {
		$self->log('warning', 
			   "Did not receive home directory from RADIUS\n");
		return -1;
	    }
	    
				# This untaints the directory and insures
				# a sane path

	    $self->{pwp_root_dir} =~ s![^-/\w\._\d]!!g;
	    $self->{pwp_root_dir} =~ m!^(.*)$!;
	    $self->{pwp_root_dir} = $1;
	    
	    $self->{pwp_root_dir} .= '/' unless $self->{pwp_root_dir} =~ m!/$!;
	    $self->{pwp_root_dir} .= $self->config('pwp root subdir') || '';
	    $self->{pwp_root_dir} .= '/' unless $self->{pwp_root_dir} =~ m!/$!;
	    
	    return 0;
	}
    }
    return -1;
}

=pod

=item $self->user_login_hook ($user, $anon)

Hook: Called just after user C<$user> has successfully logged in.

=cut

				# According to the doco, this is called
				# after a succesful login. We'll use this
				# oportunity to get the quota info

sub user_login_hook {

    my $self = shift;
    my $user = shift;
    my $anon = shift;

    $self->{pwp_quota} = $self->config('default pwp quota') || -1
	unless $self->{pwp_quota};

    $self->{pwp_qliveness} = $self->config('pwp quota cache secs') || 60
	unless $self->{pwp_qliveness};

    $self->{pwp_max_qfile_age} = $self->config('pwp max quota file age') 
	|| 48 * 3600;

    $self->{pwp_max_qfile_entries} = $self->config('pwp max quota file lines')
	|| 10;

				# Apply variable substitution to
				# the qfile spec so that they can be
				# placed anywhere

    $self->{pwp_qfile} = $self->config('pwp quota file') || '../pwpquota';
    $self->{pwp_qfile} =~ s!\$(\w+)!$self->{$1}!g;

    my $uid = $self->config('default pwp userid');
    my $gid = $self->config('default pwp groupid');

    if (defined $uid and defined $gid) {

				# XXX - This function is not documented

	eval { $self->_drop_privs($uid, $gid, $user); };
    }

}

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of Net::FTPServer::PWPDirHandle
corresponding to the root directory.

=cut

				# Set the root directory for this user and
				# also calc the usage if required
sub root_directory_hook {
    my $self = shift;

    $self->{pwp_root} = 
	new Net::FTPServer::PWP::DirHandle($self, '/');

    $self->log('debug',  "root_directory_hook: root is $self->{pwp_root_dir}")
	if $self->config('debug');

    $self->_add_space(0);	# If the quota file is too old, force
				# its rebuilding.

    return $self->{pwp_root};
}

				# Calculate current space utilization
				# and update post file
sub _calc_space {
    my $self = shift;

    $self->{pwp_space} = 0;

    unless ($self->{pwp_qhandle}) {
	$self->{pwp_qhandle} = $self->{pwp_root};

				# The quota file might be wanted outside
				# the current home directory. Therefore,
				# we need to be free from the hurdles
				# of 'hide mount point'...

	$self->{pwp_qhandle} = Net::FTPServer::Full::DirHandle 
	    -> new($self, $self->{pwp_qhandle}->{_pathname});

	my @parts = split m!/!, $self->{pwp_qfile};

	while (my $c = shift @parts) {
	    next if $c eq '' or $c eq '.';
	    if ($c eq "..") {
		$self->{pwp_qhandle} = $self->{pwp_qhandle}->parent;
	    }
	    else {
		my $h = $self->{pwp_qhandle}->get($c);

		if (!$h and !@parts) {
		    $h = $self->{pwp_qhandle}->open($c, "w");
		    unless ($h) {
			warn "Cannot create quota file ",
			$self->{pwp_qhandle}->pathname . "/$c: $!\n";
			delete $self->{pwp_qhandle};
			return undef;
		    }
		}

		$self->{pwp_qhandle} = $self->{pwp_qhandle}->get($c);

		unless 
		    ($self->{pwp_qhandle} and 
		     $self->{pwp_qhandle}->isa("Net::FTPServer::Handle"))
		{
		    warn "Invalid quota file: $self->{pwp_qfile} ($!)\n";
		    delete $self->{pwp_qhandle};
		    return undef;
		}
	    }
	}

	unless 
	    ($self->{pwp_qhandle} 
	     and $self->{pwp_qhandle}->isa("Net::FTPServer::FileHandle")) 
	{
	    warn "$self->{pwp_qhandle} Quota file seems invalid: $self->{pwp_qfile}\n";
	    delete $self->{pwp_qhandle};
	    return undef;
	}
    }

    my $fh = $self->{pwp_qhandle}->open("w");

    unless ($fh) {
	die "Failed to create ", $self->{pwp_qfile}, ": $!\n";
    }

    $self->visit($self->{pwp_root}, { 
	'f' => sub 
	{ 
#	    warn "quota f: ", $_->pathname, " adds ", ($_->status)[5], "\n";
	    $self->{pwp_space} += ($_->status)[5] 
		unless $_->pathname 
		    eq $self->{pwp_qhandle}->pathname;
	    return 1;
	},
	'd' => sub 
	{
#	    warn "quota d: ", $_->pathname, " adds ", ($_->status)[5], "\n";
	    $self->{pwp_space} += ($_->status)[5] 
		unless $_->pathname 
		    eq $self->{pwp_qhandle}->pathname;
	    return 1;
	},
	'l' => sub 
	{
#	    warn "quota l: ", $_->pathname, " adds ", ($_->status)[5], "\n";
	    $self->{pwp_space} += ($_->status)[5] 
		unless $_->pathname 
		    eq $self->{pwp_qhandle}->pathname;
	    return 1;
	}
    });
    
    print $fh $self->{pwp_space}, "\n";

#    warn "Quota file rebuilt. $self->{pwp_space} bytes seen\n";

    $fh->close;

    $self->{pwp_quota_stamp} = time;
}

				# Add $size bytes to the current space
				# utilization, potentially regenerating
				# the post file
sub _add_space {
    my $self = shift;
    my $size = shift;

				# Try to find the quota file in the fs

#    warn "_add_space $size\n";


    $self->_calc_space unless $self->{pwp_qhandle};

    my $fh = $self->{pwp_qhandle};

    if ($fh) {

	my $lines = 0;

	$self->{pwp_space} = 0;

	my $stamp = ($fh->status)[6];

				# Update the quota info if the stamp
				# expires or is updated behind our back

	$self->{pwp_quota_stamp} = $stamp 
	    unless $self->{pwp_quota_stamp};

#	warn "qstamp=$self->{pwp_quota_stamp}\n";
#	warn "qmax=$self->{pwp_max_qfile_age}\n";
#	warn "stamp=$stamp\n";
#	warn "time=", time, "\n";

	if ($stamp + $self->{pwp_max_qfile_age} < time
	    or $stamp > $self->{pwp_quota_stamp}) 
	{
#	    warn "case 1\n";
	    $self->_calc_space;
	}
	else {
	    my $f = $fh->open("r");
	    while (my $bytes = <$f>) {
		chomp $bytes;
		next unless $bytes;
		$self->{pwp_space} += $bytes;
		if ($self->{pwp_max_qfile_entries} > 0
		    and ++$lines > $self->{pwp_max_qfile_entries})
		{
#		    warn "case 2\n";
		    $self->_calc_space;
		    last;
		}
	    }
	    $f->close;
	}
    }
    else {
#	warn "case 3\n";
	$self->_calc_space;
    }

    if ($size != 0) {
				# Add the space to the quota file only
				# if non-zero.

	$fh = $self->{pwp_qhandle}->open("a");

	die "Failed to append quota file ", $self->{pwp_qfile}, ": $!\n"
	    unless $fh;

	print $fh $size, "\n";

	$fh->close;
	$self->{pwp_quota_stamp} 
	= ($self->{pwp_qhandle}->status)[6];

    }

    $self->{pwp_space} += $size;
}

=pod

=item $dirh = $self->pre_command_hook;

Hook: Insures that our quotas look sane enough. Otherwise, have them
recalculated.

=cut

sub pre_command_hook {
    my $self = shift;
    return unless defined $self->{pwp_quota} and $self->{pwp_quota} > 0;
    $self->_calc_space if $self->{pwp_space} <= 0;
}

=pod

=item $dirh = $self->transfer_hook;

Hook: Enforce the quota mechanism by seeing that no transfer exceed
the allocated quota.

=cut


				# This hook is used to enforce the quotas
				# XXX - When this hook is called, there is
				# already a file created in the VFS. We
				# seem to be unable to access it, so we
				# cannot erase it.
sub transfer_hook {
    my $self = shift;
    my $mode = shift;
    my $file = shift;
    my $sock = shift;
    my $rbuf = shift;

    return undef unless $mode eq 'w';

    if ($self->{pwp_quota} > 0) {
	unless (defined $self->{pwp_space}
		and defined $self->{pwp_quota_stamp}
		and defined $self->{pwp_qliveness}
		and $self->{pwp_quota_stamp} 
		+ $self->{pwp_qliveness} > time)
	{
				# Update the quota information

	    $self->_add_space(0);
	}

	my $len = length $$rbuf;

	if ($self->{pwp_space} + $len > $self->{pwp_quota}) {
	    return $self->config('pwp quota exceeded message') 
		|| "This operation would exceed your quota";
	}
	$self->_add_space($len);
    }

    return undef;		# OK by default

}

=pod

=item _SITE_QUOTA_command();

This method handles the C<SITE QUOTA> command, that allows the user to
check at a glance, what the server thinks of its space usage.

=cut

sub _SITE_QUOTA_command {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if ($self->{pwp_quota} > 0) {
	$self->reply(200, $self->{pwp_space}
		     . " out of " . $self->{pwp_quota} 
		     . " bytes of quota used.");
    } else {
	$self->reply(200, "No quotas for this account.");
    }
    return;
}

=pod

=item _DELE_command();

This is supposed to intercept C<Net::FTPServer::_DELE_command> before it
is called. What we do here, is to note the size of the
soon-to-be-deleted file and apply the change in the quota file if the
operation was succesful.

Note that this might be somewhat dangerous or un-portable as
traditionally, method names starting with C<_> mean internal things
that should not be messed from the outside. Yet it seems we do not have
a better solution to this issue.

The code contains a race condition: If two different sessions try to
delete the same file at the same time, probably both will think they
did and will attempt to reflect this in the quota file. There's a
chance for both of the updates to make it to the quota file, thus
over-reducing the user's space allocation. This will correct
automatically after either a few more operations or some time.

=cut

sub _DELE_command {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($o_fileh) = ($self->_get ($rest))[1];

    my $size = 0;
    my $mode;

    if ($o_fileh) {
	($mode, $size) = ($o_fileh->status)[0, 5];
    }
    
    $self->SUPER::_DELE_command($cmd, $rest);

    my ($n_fileh) = ($self->_get ($rest))[1];

    if ($o_fileh and not $n_fileh and $mode ne 'd') {
				# File was actually deleted
	$self->_add_space(-$size);
    }

    return;
}

1;

__END__

=back 4

=head1 FILES

  /etc/ftpd.conf

=head1 HISTORY

$Id: Server.pm,v 1.30 2003/04/01 15:50:42 lem Exp $

=over 8

=item 1.00

Original version; created by h2xs 1.21 with options

  -ACOXcfkn
	Net::FTPServer::PWP
	-v1.00
	-b
	5.5.0

=item 1.10

PWD will return the path minus the current root. This allows for the
hidding of the home directory.

=item 1.20

As per Rob Brown suggestion, the quota file will no longer be within
the home directory. Any arbitrary pathname can be specified in the
config file. Include the directory size in the quota calculation to
avoid abuses.

The quota file specification has variable interpolation performed.

SITE QUOTA was broken in 1.10. Fixed.

=item 1.21

Added code to avoid this error

    Argument "" isn't numeric in addition (+) at
    /usr/lib/perl5/site_perl/5.6.1/Net/FTPServer/PWP
    /Server.pm line 636, <GEN28979> line 2.

=back

=head1 AUTHORS

Luis Munoz <luismunoz@cpan.org>, Manuel Picone <mpicone@cantv.net>

=head1 COPYRIGHT

Copyright (c) 2002, Luis Munoz and Manuel Picone

=head1 SEE ALSO

L<Net::FTPServer(3)>,
L<Net::FTPServer::PWP(3)>,
L<perl(1)>

=cut
