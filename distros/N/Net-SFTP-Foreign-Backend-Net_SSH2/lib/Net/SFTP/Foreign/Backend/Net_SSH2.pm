package Net::SFTP::Foreign::Backend::Net_SSH2;

our $VERSION = '0.09';

use strict;
use warnings;
use Time::HiRes qw(sleep);

use Carp;
our @CARP_NOT = qw(Net::SFTP::Foreign);

use Net::SFTP::Foreign::Helpers;
use Net::SFTP::Foreign::Constants qw(SSH2_FX_BAD_MESSAGE
				     SFTP_ERR_REMOTE_BAD_MESSAGE);
use Net::SSH2;

my $eagain_error = do {
    local ($@, $SIG{__DIE__}, $SIG{__WARN__});
    eval { Net::SSH2::LIBSSH2_ERROR_EAGAIN() };
};
unless (defined $eagain_error) {
    $eagain_error = -1;
    $debug and $debug & 131072 and _debug "The installed version of Net::SSH2 does not support LIBSSH2_ERROR_EGAIN";
}

sub _new {
    $debug and
        _debug "Using Net_SSH2 backend, Net::SSH2 version $Net::SSH2::VERSION compiled against libssh2 "
            . Net::SSH2->version;
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

sub _defaults {
    ( queue_size => 32 )
}

sub _conn_failed {
    my ($self, $sftp, $msg) = @_;
    $sftp->_conn_failed(sprintf("%s: %s (%d): %s",
				$msg,
				($self->{_ssh2}->error)[1, 0, 2]));
}

sub _conn_lost {
    my ($self, $sftp, $msg) = @_;
    $sftp->_conn_lost(undef, undef,
                      sprintf("%s: %s (%d): %s",
                              $msg,
                              ($self->{_ssh2}->error)[1, 0, 2]));
}

my %auth_arg_map = qw(host hostname
		      user username
                      passphrase password
		      local_user local_username
                      key_path privatekey);

sub _init_transport {
    my ($self, $sftp, $opts) = @_;
    my $ssh2 = delete $opts->{ssh2};
    if (defined $ssh2) {
        $debug and $debug & 131072 and $ssh2->debug(1);
	unless ($ssh2->auth_ok) {
	    $sftp->_conn_failed("Net::SSH2 object is not authenticated");
	    return;
	}
    }
    else {
	my %auth_args;
	for (qw(rank username passphrase password publickey privatekey
		hostname key_path local_user local_username interact
		cb_keyboard cb_password user host)) {
	    my $map = $auth_arg_map{$_} || $_;
            next if defined $auth_args{$map};
	    $auth_args{$map} = delete $opts->{$_} if exists $opts->{$_}
	}

        if (defined $auth_args{privatekey} and not defined $auth_args{publickey}) {
            $auth_args{publickey} = "$auth_args{privatekey}.pub";
        }

	my $host = $auth_args{hostname};
	defined $host or croak "sftp target host not defined";
	my $port = delete $opts->{port} || 22;
	%$opts and return;

        unless (defined $auth_args{username}) {
            local $SIG{__DIE__};
            $auth_args{username} = eval { scalar getpwuid $< };
            defined $auth_args{username} or croak "required option 'user' missing";
        }

	$ssh2 = $self->{_ssh2} = Net::SSH2->new();
        $debug and $debug & 131072 and $ssh2->debug(1);

	unless ($ssh2->connect($host, $port)) {
	    $self->_conn_failed($sftp, "connection to remote host $host failed");
	    return;
	}

	unless ($ssh2->auth(%auth_args)) {
	    $self->_conn_failed($sftp, "authentication failed");
	    return;
	}
    }

    my $channel = $self->{_channel} = $ssh2->channel;
    unless (defined $channel) {
	$self->_conn_failed($sftp, "unable to create new session channel");
	return;
    }
    $channel->ext_data('ignore');
    $self->{_ssh2} = $ssh2;
    $channel->subsystem('sftp');
}

sub _sysreadn {
    my ($self, $sftp, $n) = @_;
    my $channel = $self->{_channel};
    my $bin = \$sftp->{_bin};
    while (1) {
	my $len = length $$bin;
	return 1 if $len >= $n;
	my $buf = '';
	my $read = $channel->read($buf, $n - $len);
	unless (defined $read) {
            $debug and $debug & 32 and _debug("read failed: " . $self->{_ssh2}->error . ", n: $n, len: $len");
            if ($self->{_ssh2}->error == $eagain_error) {
                $debug and $debug & 32 and _debug "read error: EAGAIN, delaying before retrying";
                sleep 0.01;
                redo;
            }
	    $self->_conn_lost($sftp, "read failed: " . $self->{_ssh2}->error);
	    return undef;
	}
        $sftp->{_read_total} += $read;
        if ($debug and $debug & 32) {
            _debug "$read bytes read from SSH channel, total $sftp->{_read_total}";
            $debug & 2048 and $read and _hexdump($buf);
        }
	$$bin .= $buf;
    }
    return $n;
}

sub _do_io {
    my ($self, $sftp, $timeout) = @_;
    my $channel = $self->{_channel};
    return undef unless $sftp->{_connected};

    my $bin = \$sftp->{_bin};
    my $bout = \$sftp->{_bout};

    while (length $$bout) {
	my $buf = substr($$bout, 0, 20480);
	my $written = $channel->write($buf);
	unless ($written) {
            if ($self->{_ssh2}->error == Net::SSH2::LIBSSH2_ERROR_EAGAIN()) {
                $debug and $debug & 32 and _debug "write error: EAGAIN, delaying before retrying";
                sleep 0.01;
                redo;
            }
	    $self->_conn_lost($sftp, "write failed: " . $self->{_ssh2}->error);
	    return undef;
	}
        $sftp->{_written_total} += $written;
        if ($debug and $debug & 32) {
            _debug("$written bytes written to SSH channel, total $sftp->{_written_total}");
            $debug & 2048 and $written and _hexdump($$bout, 0, $written);
        }
	substr($$bout, 0, $written, "");
    }

    defined $timeout and $timeout <= 0 and return;

    $self->_sysreadn($sftp, 4) or return undef;

    my $len = 4 + unpack N => $$bin;
    if ($len > 256 * 1024) {
	$sftp->_set_status(SSH2_FX_BAD_MESSAGE);
	$sftp->_set_error(SFTP_ERR_REMOTE_BAD_MESSAGE,
			  "bad remote message received, len=$len");
	return undef;
    }
    $self->_sysreadn($sftp, $len);
}

sub _after_init {};

sub DESTROY {
    my $self = shift;
    local ($@, $!, $?, $SIG{__DIE__});
    eval {
        $self->{_channel}->close;
        undef $self->{_channel};
   };
}

1;

__END__

=head1 NAME

Net::SFTP::Foreign::Backend::Net_SSH2 - Run Net::SFTP::Foreign on top of Net::SSH2

=head1 SYNOPSIS

  use Net::SFTP::Foreign;

  my $sftp = Net::SFTP::Foreign->new($host,
                                     backend => 'Net_SSH2',
                                     username => $user,
                                     password => $pass);
  $sftp->error and
    die "Unable to stablish SFTP connection: ". $sftp->error;


  # or...

  use Net::SSH2;

  my $ssh2 = Net::SSH2->new();
  $ssh2->connect($host)
    or die "connect failed";
  $ssh2->auth_password($user, $pass)
    or die "password auth failed";
  my $sftp = Net::SFTP::Foreign->new(ssh2 => $ssh2,
                                     backend => 'Net_SSH2');
  $sftp->error and
    die "Unable to stablish SFTP connection: ". $sftp->error;

  $sftp->get("foo", "foo") or die "get failed: " . $sftp->error;

=head1 DESCRIPTION

This module implements a L<Net::SFTP::Foreign> backend that uses
L<Net::SSH2> as the SSH transport layer.

To use it, include the argument C<backend =E<gt> 'Net_SSH2'> when
calling Net::SFTP::Foreign constructor.

The constructor will them accept the following options:

=over

=item ssh2 => $ssh2

A L<Net::SSH2> object already connected to the remote host and
authenticated.

=item host => $host

=item hostname => $host

=item port => $port

=item user => $user

=item username => $username

=item rank => $rank

=item password => $password

=item publickey => $publickey

=item privatekey => $privatekey

=item local_username => $local_username

=item interact => $interact

=item cb_keyboard => $cb_keyboard

=item cv_password => $cb_password

These options are passed to L<Net::SSH2> C<connect> and C<auth>
methods in order to stablish an SSH authenticated connection with the
remote host.

=back

=head1 SUPPORT

This backend is completely experimental!

To report bugs, send me and email or use the CPAN bug tracking system
at L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Net::SFTP::Foreign> and L<Net::SSH2> documentation.

L<Net::SSH2> contains its own SFTP client, L<Net::SSH2::SFTP>, but it
is rather limited and its performance very poor.

=head1 COPYRIGHT

Copyright (c) 2009-2012 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
as part of this package.

