# $Id: SFTP.pm,v 1.35 2005/10/05 06:19:36 dbrobins Exp $

package Net::SFTP;
use strict;

use Net::SFTP::Constants qw( :fxp :flags :status :att SSH2_FILEXFER_VERSION );
use Net::SFTP::Util qw( fx2txt );
use Net::SFTP::Attributes;
use Net::SFTP::Buffer;
use Net::SSH::Perl::Constants qw( :msg2 );
use Net::SSH::Perl 2.12;
use Math::Int64 qw( :native_if_available uint64 );

use Carp qw( carp croak );

use vars qw( $VERSION );
$VERSION = '0.12';

use constant COPY_SIZE => 65536;

sub new {
    my $class = shift;
    my $sftp = bless { }, $class;
    $sftp->{host} = shift;
    $sftp->init(@_);
}

# call the warning handler with the object and message
sub warn {
    my ($sftp,$msg,$status) = @_;
    $msg .= ': '.fx2txt($status) if defined $status;
    $sftp->{status} = $status || SSH2_FX_OK;
    $sftp->{warn_h}->($sftp,$msg);
}

# returns last SSH error, or SSH2_FX_OK (only useful after failure)
sub status {
    my $sftp = shift;
    my $status = $sftp->{status};
    wantarray ? ($status,fx2txt($status)) : $status
}

# returns the new object
sub init {
    my $sftp = shift;
    my %param = @_;
    $sftp->{debug} = delete $param{debug};
    $sftp->{status} = SSH2_FX_OK;

    $param{ssh_args} ||= [];
    $param{ssh_args} = [%{$param{ssh_args}}]
     if UNIVERSAL::isa($param{ssh_args},'HASH');

    $param{warn} = 1 if not defined $param{warn};   # default
    $sftp->{warn_h} = delete $param{warn} || sub {};  # false => ignore
    $sftp->{warn_h} = sub { carp $_[1] }  # true  => emit warning
     if $sftp->{warn_h} and not ref $sftp->{warn_h};

    $sftp->{_msg_id} = 0;

    my $ssh = Net::SSH::Perl->new($sftp->{host}, protocol => 2,
        debug => $sftp->{debug}, @{ $param{ssh_args} });
    $ssh->login($param{user}, $param{password}, 'supress_shell');
    $sftp->{ssh} = $ssh;

    my $channel = $sftp->_open_channel;
    $sftp->{channel} = $channel;

    $sftp->do_init;

    $sftp;
}

# returns the new channel object
sub _open_channel {
    my $sftp = shift;
    my $ssh = $sftp->{ssh};

    my $channel = $ssh->_session_channel;
    $channel->open;

    $channel->register_handler(SSH2_MSG_CHANNEL_OPEN_CONFIRMATION, sub {
        my($c, $packet) = @_;
        $c->{ssh}->debug("Sending subsystem: sftp");
        my $r_packet = $c->request_start("subsystem", 1);
        $r_packet->put_str("sftp");
        $r_packet->send;
    });

    my $subsystem_reply = sub {
        my($c, $packet) = @_;
        my $id = $packet->get_int32;
        if ($packet->type == SSH2_MSG_CHANNEL_FAILURE) {
            $c->{ssh}->fatal_disconnect("Request for " .
                "subsystem 'sftp' failed on channel '$id'");
        }
        $c->{ssh}->break_client_loop;
    };

    my $cmgr = $ssh->channel_mgr;
    $cmgr->register_handler(SSH2_MSG_CHANNEL_FAILURE, $subsystem_reply);
    $cmgr->register_handler(SSH2_MSG_CHANNEL_SUCCESS, $subsystem_reply);

    $sftp->{incoming} = Net::SFTP::Buffer->new;
    my $incoming = $sftp->{incoming};
    $channel->register_handler("_output_buffer", sub {
        my($c, $buffer) = @_;
        $incoming->append($buffer->bytes);
        $c->{ssh}->break_client_loop;
    });

    ## Get channel confirmation, etc. Break once we get a response
    ## to subsystem execution.
    $ssh->client_loop;

    $channel;
}

sub do_init {
    my $sftp = shift;
    my $ssh = $sftp->{ssh};

    $sftp->debug("Sending SSH2_FXP_INIT");
    my $msg = $sftp->new_msg(SSH2_FXP_INIT);
    $msg->put_int32(SSH2_FILEXFER_VERSION);
    $sftp->send_msg($msg);

    $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    if ($type != SSH2_FXP_VERSION) {
        croak "Invalid packet back from SSH2_FXP_INIT (type $type)";
    }
    my $version = $msg->get_int32;
    $sftp->debug("Remote version: $version");

    ## XXX Check for extensions.
}

sub debug {
    my $sftp = shift;
    if ($sftp->{debug}) {
        $sftp->{ssh}->debug("sftp: @_");
    }
}

## Server -> client methods.

# reads SSH2_FXP_STATUS packet and returns Net::SFTP::Attributes object or undef
sub get_attrs {
    my $sftp = shift;
    my($expected_id) = @_;
    my $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    my $id = $msg->get_int32;
    $sftp->debug("Received stat reply T:$type I:$id");
    croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
    if ($type == SSH2_FXP_STATUS) {
        my $status = $msg->get_int32;
  $sftp->warn("Couldn't stat remote file",$status);
        return;
    }
    elsif ($type != SSH2_FXP_ATTRS) {
        croak "Expected SSH2_FXP_ATTRS packet, got $type";
    }
    $msg->get_attributes;
}

# reads SSH2_FXP_STATUS packet and returns SFTP status value
sub get_status {
    my $sftp = shift;
    my($expected_id) = @_;
    my $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    my $id = $msg->get_int32;

    croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
    if ($type != SSH2_FXP_STATUS) {
        croak "Expected SSH2_FXP_STATUS packet, got $type";
    }

    $msg->get_int32;
}

# reads SSH2_FXP_HANDLE packet and returns handle, or undef on failure
sub get_handle {
    my $sftp = shift;
    my($expected_id) = @_;

    my $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    my $id = $msg->get_int32;

    croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
    if ($type == SSH2_FXP_STATUS) {
        my $status = $msg->get_int32;
  $sftp->warn("Couldn't get handle",$status);
        return;
    }
    elsif ($type != SSH2_FXP_HANDLE) {
        croak "Expected SSH2_FXP_HANDLE packet, got $type";
    }

    $msg->get_str;
}

## Client -> server methods.

sub _send_str_request {
    my $sftp = shift;
    my($code, $str) = @_;
    my($msg, $id) = $sftp->new_msg_w_id($code);
    $msg->put_str($str);
    $sftp->send_msg($msg);
    $sftp->debug("Sent message T:$code I:$id");
    $id;
}

sub _send_str_attrs_request {
    my $sftp = shift;
    my($code, $str, $a) = @_;
    my($msg, $id) = $sftp->new_msg_w_id($code);
    $msg->put_str($str);
    $msg->put_attributes($a);
    $sftp->send_msg($msg);
    $sftp->debug("Sent message T:$code I:$id");
    $id;
}

sub _check_ok_status {
    my $status = $_[0]->get_status($_[1]);
    $_[0]->warn("Couldn't $_[2]",$status) unless $status == SSH2_FX_OK;
    $status;
}

## SSH2_FXP_OPEN (3)
# returns handle on success, undef on failure
sub do_open {
    my $sftp = shift;
    my($path, $flags, $a) = @_;
    $a ||= Net::SFTP::Attributes->new;
    my($msg, $id) = $sftp->new_msg_w_id(SSH2_FXP_OPEN);
    $msg->put_str($path);
    $msg->put_int32($flags);
    $msg->put_attributes($a);
    $sftp->send_msg($msg);
    $sftp->debug("Sent SSH2_FXP_OPEN I:$id P:$path");
    $sftp->get_handle($id);
}

## SSH2_FXP_READ (4)
# returns data on success, (undef,$status) on failure
sub do_read {
    my $sftp = shift;
    my($handle, $offset, $size) = @_;
    $size ||= COPY_SIZE;
    my($msg, $expected_id) = $sftp->new_msg_w_id(SSH2_FXP_READ);
    $msg->put_str($handle);
    $msg->put_int64($offset);
    $msg->put_int32($size);
    $sftp->send_msg($msg);
    $sftp->debug("Sent message SSH2_FXP_READ I:$expected_id O:$offset");
    $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    my $id = $msg->get_int32;
    $sftp->debug("Received reply T:$type I:$id");
    croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
    if ($type == SSH2_FXP_STATUS) {
        my $status = $msg->get_int32;
        if ($status != SSH2_FX_EOF) {
            $sftp->warn("Couldn't read from remote file",$status);
            $sftp->do_close($handle);
        }
        return(undef, $status);
    }
    elsif ($type != SSH2_FXP_DATA) {
        croak "Expected SSH2_FXP_DATA packet, got $type";
    }
    $msg->get_str;
}

## SSH2_FXP_WRITE (6)
# returns status (SSH2_FX_OK on success)
sub do_write {
    my $sftp = shift;
    my($handle, $offset, $data) = @_;
    my($msg, $id) = $sftp->new_msg_w_id(SSH2_FXP_WRITE);
    $msg->put_str($handle);
    $msg->put_int64($offset);
    $msg->put_str($data);
    $sftp->send_msg($msg);
    $sftp->debug("Sent message SSH2_FXP_WRITE I:$id O:$offset");
    my $status = $sftp->_check_ok_status($id,'write to remote file');
    $sftp->do_close($handle) unless $status == SSH2_FX_OK;
    return $status;
}

## SSH2_FXP_LSTAT (7), SSH2_FXP_FSTAT (8), SSH2_FXP_STAT (17)
# these all return a Net::SFTP::Attributes object on success, undef on failure
sub do_lstat { $_[0]->_do_stat(SSH2_FXP_LSTAT, $_[1]) }
sub do_fstat { $_[0]->_do_stat(SSH2_FXP_FSTAT, $_[1]) }
sub do_stat  { $_[0]->_do_stat(SSH2_FXP_STAT , $_[1]) }
sub _do_stat {
    my $sftp = shift;
    my $id = $sftp->_send_str_request(@_);
    $sftp->get_attrs($id);
}

## SSH2_FXP_OPENDIR (11)
sub do_opendir {
    my $sftp = shift;
    my $id = $sftp->_send_str_request(SSH2_FXP_OPENDIR, @_);
    $sftp->get_handle($id);
}

## SSH2_FXP_CLOSE (4),   SSH2_FXP_REMOVE (13),
## SSH2_FXP_MKDIR (14),  SSH2_FXP_RMDIR (15),
## SSH2_FXP_SETSTAT (9), SSH2_FXP_FSETSTAT (10)
# all of these return a status (SSH2_FX_OK on success)
{
    no strict 'refs';
    *do_close    = _gen_simple_method(SSH2_FXP_CLOSE,  'close file');
    *do_remove   = _gen_simple_method(SSH2_FXP_REMOVE, 'delete file');
    *do_mkdir    = _gen_simple_method(SSH2_FXP_MKDIR,  'create directory');
    *do_rmdir    = _gen_simple_method(SSH2_FXP_RMDIR,  'remove directory');
    *do_setstat  = _gen_simple_method(SSH2_FXP_SETSTAT , 'setstat');
    *do_fsetstat = _gen_simple_method(SSH2_FXP_FSETSTAT , 'fsetstat');
}

sub _gen_simple_method {
    my($code, $msg) = @_;
    sub {
        my $sftp = shift;
        my $id = @_ > 1 ?
            $sftp->_send_str_attrs_request($code, @_) :
            $sftp->_send_str_request($code, @_);
        $sftp->_check_ok_status($id, $msg);
    };
}

## SSH2_FXP_REALPATH (16)
sub do_realpath {
    my $sftp = shift;
    my($path) = @_;
    my $expected_id = $sftp->_send_str_request(SSH2_FXP_REALPATH, $path);
    my $msg = $sftp->get_msg;
    my $type = $msg->get_int8;
    my $id = $msg->get_int32;
    croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
    if ($type == SSH2_FXP_STATUS) {
        my $status = $msg->get_int32;
  $sftp->warn("Couldn't canonicalise $path",$status);
        return;
    }
    elsif ($type != SSH2_FXP_NAME) {
        croak "Expected SSH2_FXP_NAME packet, got $type";
    }
    my $count = $msg->get_int32;
    croak "Got multiple names ($count) from SSH2_FXP_REALPATH"
        unless $count == 1;
    $msg->get_str;   ## Filename.
}

## SSH2_FXP_RENAME (18)
sub do_rename {
    my $sftp = shift;
    my($old, $new) = @_;
    my($msg, $id) = $sftp->new_msg_w_id(SSH2_FXP_RENAME);
    $msg->put_str($old);
    $msg->put_str($new);
    $sftp->send_msg($msg);
    $sftp->debug("Sent message SSH2_FXP_RENAME '$old' => '$new'");
    $sftp->_check_ok_status($id, "rename '$old' to '$new'");
}

## High-level client -> server methods.

# always returns undef on failure
# if local filename is provided, returns '' on success, else file contents
sub get {
    my $sftp = shift;
    my($remote, $local, $cb) = @_;
    my $ssh = $sftp->{ssh};
    my $want = defined wantarray ? 1 : 0;

    my $a = $sftp->do_stat($remote) or return;
    my $handle = $sftp->do_open($remote, SSH2_FXF_READ);
    return unless defined $handle;

    local *FH;
    if ($local) {
        open FH, ">$local" or
         $sftp->do_close($handle), croak "Can't open $local: $!";
        binmode FH or
         $sftp->do_close($handle), croak "Can't binmode FH: $!";
    }

    my $offset = uint64(0);
    my $ret = '';
    while (1) {
        my($data, $status) = $sftp->do_read($handle, $offset, COPY_SIZE);
        last if defined $status && $status == SSH2_FX_EOF;
        return unless $data;
        my $len = length($data);
        croak "Received more data than asked for $len > " . COPY_SIZE
            if $len > COPY_SIZE;
        $sftp->debug("In read loop, got $len offset $offset");
        $cb->($sftp, $data, $offset, $a->size) if defined $cb;
        if ($local) {
            print FH $data;
        }
        elsif ($want) {
            $ret .= $data;
        }
        $offset += $len;
    }
    $sftp->do_close($handle);

    if ($local) {
        close FH;
        my $flags = $a->flags;
        my $mode = $flags & SSH2_FILEXFER_ATTR_PERMISSIONS ?
            $a->perm & 0777 : 0666;
        chmod $mode, $local or croak "Can't chmod $local: $!";

        if ($flags & SSH2_FILEXFER_ATTR_ACMODTIME) {
            utime $a->atime, $a->mtime, $local or
                croak "Can't utime $local: $!";
        }
    }
    $ret;
}

sub put {
    my $sftp = shift;
    my($local, $remote, $cb) = @_;
    my $ssh = $sftp->{ssh};

    my @stat = stat $local or croak "Can't stat local $local: $!";
    my $size = $stat[7];
    my $a = Net::SFTP::Attributes->new(Stat => \@stat);
    my $flags = $a->flags;
    $flags &= ~SSH2_FILEXFER_ATTR_SIZE;
    $flags &= ~SSH2_FILEXFER_ATTR_UIDGID;
    $a->flags($flags);
    $a->perm( $a->perm & 0777 );

    local *FH;
    open FH, $local or croak "Can't open local file $local: $!";
    binmode FH or croak "Can't binmode FH: $!";

    my $handle = $sftp->do_open($remote, SSH2_FXF_WRITE | SSH2_FXF_CREAT |
     SSH2_FXF_TRUNC, $a);  # check status for info
    return unless defined $handle;

    my $offset = uint64(0);
    while (1) {
        my($len, $data, $msg, $id);
        $len = read FH, $data, 8192;
        last unless $len;
        $cb->($sftp, $data, $offset, $size) if defined $cb;
        my $status = $sftp->do_write($handle, $offset, $data);
        if ($status != SSH2_FX_OK) {
            close FH;
            return;
        }
        $sftp->debug("In write loop, got $len offset $offset");
        $offset += $len;
    }

    close FH or $sftp->warn("Can't close local file $local: $!");

    # ignore failures here, the transmission is the important part
    $sftp->do_fsetstat($handle, $a);
    $sftp->do_close($handle);
    return 1;
}

# returns ()/undef on error, directory list/reference to same otherwise
sub ls {
    my $sftp = shift;
    my($remote, $code) = @_;
    my @dir;
    my $handle = $sftp->do_opendir($remote);
    return unless defined $handle;

    while (1) {
        my $expected_id = $sftp->_send_str_request(SSH2_FXP_READDIR, $handle);
        my $msg = $sftp->get_msg;
        my $type = $msg->get_int8;
        my $id = $msg->get_int32;
        $sftp->debug("Received reply T:$type I:$id");

        croak "ID mismatch ($id != $expected_id)" unless $id == $expected_id;
        if ($type == SSH2_FXP_STATUS) {
            my $status = $msg->get_int32;
            $sftp->debug("Received SSH2_FXP_STATUS $status");
            if ($status == SSH2_FX_EOF) {
                last;
            }
            else {
    $sftp->warn("Couldn't read directory",$status);
                $sftp->do_close($handle);
                return;
            }
        }
        elsif ($type != SSH2_FXP_NAME) {
            croak "Expected SSH2_FXP_NAME packet, got $type";
        }

        my $count = $msg->get_int32;
        last unless $count;
        $sftp->debug("Received $count SSH2_FXP_NAME responses");
        for my $i (0..$count-1) {
            my $fname = $msg->get_str;
            my $lname = $msg->get_str;
            my $a = $msg->get_attributes;
            my $rec = {
                filename => $fname,
                longname => $lname,
                a        => $a,
            };
            if ($code && ref($code) eq "CODE") {
                $code->($rec);
            }
            else {
                push @dir, $rec;
            }
        }
    }
    $sftp->do_close($handle);
    wantarray ? @dir : \@dir;
}

## Messaging methods--messages are essentially sub-packets.

sub msg_id { $_[0]->{_msg_id}++ }

sub new_msg {
    my $sftp = shift;
    my($code) = @_;
    my $msg = Net::SFTP::Buffer->new;
    $msg->put_int8($code);
    $msg;
}

sub new_msg_w_id {
    my $sftp = shift;
    my($code, $sid) = @_;
    my $msg = $sftp->new_msg($code);
    my $id = defined $sid ? $sid : $sftp->msg_id;
    $msg->put_int32($id);
    ($msg, $id);
}

sub send_msg {
    my $sftp = shift;
    my($buf) = @_;
    my $b = Net::SFTP::Buffer->new;
    $b->put_int32($buf->length);
    $b->append($buf->bytes);
    $sftp->{channel}->send_data($b->bytes);
}

sub get_msg {
    my $sftp = shift;
    my $buf = $sftp->{incoming};
    my $len;
    unless ($buf->length > 4) {
        $sftp->{ssh}->client_loop;
        croak "Connection closed" unless $buf->length > 4;
        $len = unpack "N", $buf->bytes(0, 4, '');
        croak "Received message too long $len" if $len > 256 * 1024;
        while ($buf->length < $len) {
            $sftp->{ssh}->client_loop;
        }
    }
    my $b = Net::SFTP::Buffer->new;
    $b->append( $buf->bytes(0, $len, '') );
    $b;
}

1;
__END__

=head1 NAME

Net::SFTP - Secure File Transfer Protocol client

=head1 SYNOPSIS

    use Net::SFTP;
    my $sftp = Net::SFTP->new($host);
    $sftp->get("foo", "bar");
    $sftp->put("bar", "baz");

=head1 DESCRIPTION

I<Net::SFTP> is a pure-Perl implementation of the Secure File
Transfer Protocol (SFTP) - file transfer built on top of the
SSH2 protocol. I<Net::SFTP> uses I<Net::SSH::Perl> to build a
secure, encrypted tunnel through which files can be transferred
and managed. It provides a subset of the commands listed in
the SSH File Transfer Protocol IETF draft, which can be found
at I<http://www.openssh.com/txt/draft-ietf-secsh-filexfer-00.txt>.

SFTP stands for Secure File Transfer Protocol and is a method of
transferring files between machines over a secure, encrypted
connection (as opposed to regular FTP, which functions over an
insecure connection). The security in SFTP comes through its
integration with SSH, which provides an encrypted transport
layer over which the SFTP commands are executed, and over which
files can be transferred. The SFTP protocol defines a client
and a server; only the client, not the server, is implemented
in I<Net::SFTP>.

Because it is built upon SSH, SFTP inherits all of the built-in
functionality provided by I<Net::SSH::Perl>: encrypted
communications between client and server, multiple supported
authentication methods (eg. password, public key, etc.).

=head1 USAGE

=head2 Net::SFTP->new($host, %args)

Opens a new SFTP connection with a remote host I<$host>, and
returns a I<Net::SFTP> object representing that open
connection.

I<%args> can contain:

=over 4

=item * user

The username to use to log in to the remote server. This should
be your SSH login, and can be empty, in which case the username
is drawn from the user executing the process.

See the I<login> method in I<Net::SSH::Perl> for more details.

=item * password

The password to use to log in to the remote server. This should
be your SSH password, if you use password authentication in
SSH; if you use public key authentication, this argument is
unused.

See the I<login> method in I<Net::SSH::Perl> for more details.

=item * debug

If set to a true value, debugging messages will be printed out
for both the SSH and SFTP protocols. This automatically turns
on the I<debug> parameter in I<Net::SSH::Perl>.

The default is false.

=item * warn

If given a sub ref, the sub is called with $self and any warning
message; if set to false, warnings are supressed; otherwise they
are output with 'warn' (default).

=item * ssh_args

Specifies a reference to a list or hash of named arguments that
should be given to the constructor of the I<Net::SSH::Perl> object
underlying the I<Net::SFTP> connection.

For example, you could use this to set up your authentication
identity files, to set a specific cipher for encryption, etc.,
e.g. C<ssh_args =E<gt> [ cipher =E<gt> 'aes256-cbc', options =<gt> 
[ "MACs +hmac-sha1", "HashKnownHosts yes" ] ]>.

See the I<new> method in I<Net::SSH::Perl> for more details.

=back

=head2 $sftp->status

Returns the last remote SFTP status value.  Only useful after one
of the following methods has failed.  Returns SSH2_FX_OK if there
is no remote error (e.g. local file not found).  In list context,
returns a list of (status code, status text from C<fx2txt>).

If a low-level protocol error or unexpected local error occurs,
we die with an error message.

=head2 $sftp->get($remote [, $local [, \&callback ] ])

Downloads a file I<$remote> from the remote host. If I<$local>
is specified, it is opened/created, and the contents of the
remote file I<$remote> are written to I<$local>. In addition,
its filesystem attributes (atime, mtime, permissions, etc.)
will be set to those of the remote file.

If I<get> is called in a non-void context, returns the contents
of I<$remote> (as well as writing them to I<$local>, if I<$local>
is provided.  Undef is returned on failure.

I<$local> is optional. If not provided, the contents of the
remote file I<$remote> will be either discarded, if I<get> is
called in void context, or returned from I<get> if called in
a non-void context. Presumably, in the former case, you will
use the callback function I<\&callback> to "do something" with
the contents of I<$remote>.

If I<\&callback> is specified, it should be a reference to a
subroutine. The subroutine will be executed at each iteration
of the read loop (files are generally read in 8192-byte
blocks, although this depends on the server implementation).
The callback function will receive as arguments: a
I<Net::SFTP> object with an open SFTP connection; the data
read from the SFTP server; the offset from the beginning of
the file (in bytes); and the total size of the file (in
bytes). You can use this mechanism to provide status messages,
download progress meters, etc.:

    sub callback {
        my($sftp, $data, $offset, $size) = @_;
        print "Read $offset / $size bytes\r";
    }

=head2 $sftp->put($local, $remote [, \&callback ])

Uploads a file I<$local> from the local host to the remote
host, and saves it as I<$remote>.

If I<\&callback> is specified, it should be a reference to a
subroutine. The subroutine will be executed at each iteration
of the write loop, directly after the data has been read from
the local file. The callback function will receive as arguments:
a I<Net::SFTP> object with an open SFTP connection; the data
read from I<$local>, generally in 8192-byte chunks;; the offset
from the beginning of the file (in bytes); and the total size
of the file (in bytes). You can use this mechanism to provide
status messages, upload progress meters, etc.:

    sub callback {
        my($sftp, $data, $offset, $size) = @_;
        print "Wrote $offset / $size bytes\r";
    }

Returns true on success, undef on error.

=head2 $sftp->ls($remote [, $subref ])

Fetches a directory listing of I<$remote>.

If I<$subref> is specified, for each entry in the directory,
I<$subref> will be called and given a reference to a hash
with three keys: I<filename>, the name of the entry in the
directory listing; I<longname>, an entry in a "long" listing
like C<ls -l>; and I<a>, a I<Net::SFTP::Attributes> object,
which contains the file attributes of the entry (atime, mtime,
permissions, etc.).

If I<$subref> is not specified, returns a list of directory
entries, each of which is a reference to a hash as described
in the previous paragraph.

=head1 COMMAND METHODS

I<Net::SFTP> supports all of the commands listed in the SFTP
version 3 protocol specification. Each command is available
for execution as a separate method, with a few exceptions:
I<SSH_FXP_INIT>, I<SSH_FXP_VERSION>, and I<SSH_FXP_READDIR>.

These are the available command methods:

=head2 $sftp->do_open($path, $flags [, $attrs ])

Sends the I<SSH_FXP_OPEN> command to open a remote file I<$path>,
and returns an open handle on success. On failure returns
I<undef>. The "open handle" is not a Perl filehandle, nor is
it a file descriptor; it is merely a marker used to identify
the open file between the client and the server.

I<$flags> should be a bitmask of open flags, whose values can
be obtained from I<Net::SFTP::Constants>:

    use Net::SFTP::Constants qw( :flags );

I<$attrs> should be a I<Net::SFTP::Attributes> object,
specifying the initial attributes for the file I<$path>. If
you're opening the file for reading only, I<$attrs> can be
left blank, in which case it will be initialized to an
empty set of attributes.

=head2 $sftp->do_read($handle, $offset, $copy_size)

Sends the I<SSH_FXP_READ> command to read from an open file
handle I<$handle>, starting at I<$offset>, and reading at most
I<$copy_size> bytes.

Returns a two-element list consisting of the data read from
the SFTP server in the first slot, and the status code (if any)
in the second. In the case of a successful read, the status code
will be I<undef>, and the data will be defined and true. In the
case of EOF, the status code will be I<SSH2_FX_EOF>, and the
data will be I<undef>. And in the case of an error in the read,
a warning will be emitted, the status code will contain the
error code, and the data will be I<undef>.

=head2 $sftp->do_write($handle, $offset, $data)

Sends the I<SSH_FXP_WRITE> command to write to an open file handle
I<$handle>, starting at I<$offset>, and where the data to be
written is in I<$data>.

Returns the status code. On a successful write, the status code
will be equal to SSH2_FX_OK; in the case of an unsuccessful
write, a warning will be emitted, and the status code will
contain the error returned from the server.

=head2 $sftp->do_close($handle)

Sends the I<SSH_FXP_CLOSE> command to close either an open
file or open directory, identified by I<$handle> (the handle
returned from either I<do_open> or I<do_opendir>).

Emits a warning if the I<CLOSE> fails.

Returns the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head2 $sftp->do_lstat($path)

=head2 $sftp->do_fstat($handle)

=head2 $sftp->do_stat($path)

These three methods all perform similar functionality: they
run a I<stat> on a remote file and return the results in a
I<Net::SFTP::Attributes> object on success.

On failure, all three methods return I<undef>, and emit a
warning.

I<do_lstat> sends a I<SSH_FXP_LSTAT> command to obtain file
attributes for a named file I<$path>. I<do_stat> sends a
I<SSH_FXP_STAT> command, and differs from I<do_lstat> only
in that I<do_stat> follows symbolic links on the server,
whereas I<do_lstat> does not follow symbolic links.

I<do_fstat> sends a I<SSH_FXP_FSTAT> command to obtain file
attributes for an open file handle I<$handle>.

=head2 $sftp->do_setstat($path, $attrs)

=head2 $sftp->do_fsetstat($handle, $attrs)

These two methods both perform similar functionality: they
set the file attributes of a remote file. In both cases
I<$attrs> should be a I<Net::SFTP::Attributes> object.

I<do_setstat> sends a I<SSH_FXP_SETSTAT> command to set file
attributes for a remote named file I<$path> to I<$attrs>.

I<do_fsetstat> sends a I<SSH_FXP_FSETSTAT> command to set the
attributes of an open file handle I<$handle> to I<$attrs>.

Both methods emit a warning if the operation failes, and
both return the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head2 $sftp->do_opendir($path)

Sends a I<SSH_FXP_OPENDIR> command to open the remote
directory I<$path>, and returns an open handle on success.
On failure returns I<undef>.

=head2 $sftp->do_remove($path)

Sends a I<SSH_FXP_REMOVE> command to remove the remote file
I<$path>.

Emits a warning if the operation fails.

Returns the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head2 $sftp->do_mkdir($path, $attrs)

Sends a I<SSH_FXP_MKDIR> command to create a remote directory
I<$path> whose attributes should be initialized to I<$attrs>,
a I<Net::SFTP::Attributes> object.

Emits a warning if the operation fails.

Returns the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head2 $sftp->do_rmdir($path)

Sends a I<SSH_FXP_RMDIR> command to remove a remote directory
I<$path>.

Emits a warning if the operation fails.

Returns the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head2 $sftp->do_realpath($path)

Sends a I<SSH_FXP_REALPATH> command to canonicalise I<$path>
to an absolute path. This can be useful for turning paths
containing I<'..'> into absolute paths.

Returns the absolute path on success, I<undef> on failure.

=head2 $sftp->do_rename($old, $new)

Sends a I<SSH_FXP_RENAME> command to rename I<$old> to I<$new>.

Emits a warning if the operation fails.

Returns the status code for the operation. To turn the
status code into a text message, take a look at the C<fx2txt>
function in I<Net::SFTP::Util>.

=head1 SUPPORT

For samples/tutorials, take a look at the scripts in F<eg/> in
the distribution directory.

There is a mailing list for development discussion and usage
questions.  Posting is limited to subscribers only.  You can sign up
at http://lists.sourceforge.net/lists/listinfo/ssh-sftp-perl-users

Please report all bugs via rt.cpan.org at
https://rt.cpan.org/NoAuth/ReportBug.html?Queue=net%3A%3Asftp

=head1 AUTHOR

Current maintainer is David Robins, dbrobins@cpan.org.

Previous maintainer was Dave Rolsky, autarch@urth.org.

Originally written by Benjamin Trott.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Benjamin Trott, Copyright (c) 2003-2004 David
Rolsky.  Copyright (c) David Robins.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
