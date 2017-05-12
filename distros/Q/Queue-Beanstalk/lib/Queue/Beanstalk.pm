package Queue::Beanstalk;

use 5.006002;
use Carp;
use Socket qw( MSG_NOSIGNAL PF_INET PF_UNIX IPPROTO_TCP SOCK_STREAM );
use IO::Handle ();
use Errno qw( EINPROGRESS EWOULDBLOCK EISCONN );
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw();
our @EXPORT = qw();

our $VERSION = '0.02';

our $FLAG_NOSIGNAL = 0;
eval { $FLAG_NOSIGNAL = MSG_NOSIGNAL; };

sub new {
	my $classname = shift();

	my $self = {
		# Defaults
		'report_errors' => 1,
		'random_servers' => 1,
		'connect_timeout' => 0.25,
		'select_timeout' => 1.0,
		'reserve_timeout' => 10, # if there is no job to do, wait a bit
		'auto_next_server' => 0, # usually not what you want
		'servers' => [ '127.0.0.1:11300' ],

		# Internals
		'errstr' => '',
		'warnstr' => '',
		'_connect_retries' => 0,
		'sock' => undef,
	};

	my $args = (@_ == 1) ? shift : { @_ }; # hashref-ify args

	# Default: Retry one for each server (problems with connecting will do a
	# round robin connect for this many times.)
	$self->{'max_autoretry'} = scalar(@{$args->{'servers'}||$self->{'servers'}});

	$self->{$_} = $args->{$_} foreach (keys %$args); # update options


	bless $self, $classname;

	# Connect to first/random server
	$self->next_server();

	$self;
}

sub warn {
	my ($self, $message) = @_;
	$self->{'warnstr'} = $message;
	carp $message if ($self->{'report_errors'});
}

sub die {
	my ($self, $message) = @_;
	$self->{'errstr'} = $message;
	croak $message if ($self->{'report_errors'});
}

sub next_server {
	my $self = shift;
	my $internal = shift || 0;

	if ($self->{'random_servers'} && !$internal) {
		# get random server
		$self->{'current_server'} = int( rand( scalar(@{$self->{'servers'}}) ) );
	} else {
		if (!defined $self->{'current_server'}) {
			# First connection
			$self->{'current_server'} = 0;
		} else {
			# round robin 'election'
			$self->{'current_server'}++;
			$self->{'current_server'} %= scalar(@{$self->{'servers'}});
		}
	}

	# In case of connection errors or if all servers is in "draining mode",
	# reconnect only this many times
	# NOTE: Will try to reconnect 'for ever' if no servers responds
	# and report_errors are nontrue.
	if ($internal && ($self->{'_connect_retries'}++ >= $self->{'max_autoretry'})) {
		$self->die('Could not connect to servers after ' . $self->{'max_autoretry'} . ' attempts.');
	}
	$self->connect();
}

sub connect {
	my $self = shift;
	my $sock = $self->{'sock'};

	if (defined $sock) {
		# A socket was already open
		close $sock;
	}

	my ($ip,$port) = split /:/, @{$self->{'servers'}}[ $self->{'current_server'} ];

	my $proto = getprotobyname('tcp');
	socket($sock, PF_INET, SOCK_STREAM, $proto);
	my $sin = Socket::sockaddr_in($port,Socket::inet_aton($ip));

	# The following code is borrowed heavily from Cache::Memcached

	if ($self->{'connect_timeout'}) {
		IO::Handle::blocking($sock, 0);
	} else {
		IO::Handle::blocking($sock, 1);
	}

	my $ret = connect($sock, $sin);

	if (!$ret && $self->{'connect_timeout'} && $! == EINPROGRESS) {

		my $win='';
		vec($win, fileno($sock), 1) = 1;

		if (select(undef, $win, undef, $self->{'connect_timeout'}) > 0) {
			$ret = connect($sock, $sin);
			# EISCONN means connected & won't re-connect, so success
			$ret = 1 if !$ret && $!==EISCONN;
		}
	}

	unless ($self->{'connect_timeout'}) { # socket was temporarily blocking, now revert
		IO::Handle::blocking($sock, 0);
	}

	# from here on, we use non-blocking (async) IO for the duration
	# of the socket's life

	# disable buffering
	my $old = select($sock);
	$| = 1;
	select($old);

	$self->{'sock'} = $sock;

	$self->next_server(1) unless $ret;

	return $ret;
}

# based upon _write_and_read() found in Cache::Memcached
sub _write_and_read_data {
	my ($self, $line, $check_header) = @_;
	my $sock = $self->{'sock'};
	my ($res,$ret,$offset,$toread) = (undef, undef, 0, 0);
	my @return;

	# default: stats handler
	$check_header ||= sub {
		if (m/OK (\d+)/) {
			return $1;
		} else {
			return 0;
		}
	};

	# state: 0 - writing, 1 - reading header, 2 - reading data, 3 - done
	my $state = 0; # writing 

	# the bitsets for select
	my ($rin, $rout, $win, $wout);
	my $nfound;

	my $last_state = -1;
	local $SIG{'PIPE'} = "IGNORE" unless $FLAG_NOSIGNAL;

	IO::Handle::blocking($sock, 1) if (!$self->{'select_timeout'});

	# select loop
	while (1) {
		if ($last_state != $state) {
			last if $state == 3; # done
			($rin, $win) = ('','');
			vec($rin, fileno($sock), 1) = 1 if $state == 1 || $state == 2; # reading
			vec($win, fileno($sock), 1) = 1 if $state == 0; # writing
			$last_state = $state;
		}

		$nfound = select($rout=$rin, $wout=$win, undef, $self->{'select_timeout'});
		last unless $nfound;

		if (vec($wout, fileno($sock), 1)) {
			$res = send($sock, $line, $FLAG_NOSIGNAL);
			
			next if not defined $res and $! == EWOULDBLOCK;

			if (!defined $res || $res <= 0) {
				$self->next_server(1); # disconnected, reconnect
				return undef;
			}

			if ($res == length($line)) { # all data sent
				$state = 1; # start reading
			} else {
				substr($line, 0, $res, ''); # delete the part we sent
			}
		}

		if (vec($rout, fileno($sock), 1)) {

			$res = sysread($sock, $ret, 255, $offset);

			next if not defined $res and $! == EWOULDBLOCK;

			if ($res <= 0) {
				$self->next_server(1); # disconnected, reconnect
				return undef;
			}

			$offset += $res; # read $res bytes

			if ($state == 1 && $ret =~ m/\r\n/) {
				@return = ($check_header->($ret));
				return undef unless defined $return[0];

				$state = 2; # read data

				$ret =~ s/.+?\r\n//;    # remove header
				$offset = length($ret); # update offset

				$toread = $return[0]; # Number of bytes to read
			}

			if ($state == 2 && (($offset - 2) == $toread)) { # $toread = number of bytes to read, minus \r\n
				substr($ret,$offset - 2,2) = '';
				$state = 3;
			}

		}
	}

	unless ($state == 3) { # done
		$self->next_server(1); # improperly finished, reconnect
		return undef;
	}

	IO::Handle::blocking($sock, 0) if (!$self->{'select_timeout'});

	return $ret, @return;
}

# heavily based upon the same function found in Cache::Memcached
sub _write_and_read {
	my ($self, $line, $check_complete) = @_;
	my $sock = $self->{'sock'};
	my ($res,$ret,$offset) = (undef, undef, 0);

	$check_complete ||= sub {
		return (rindex($ret, "\r\n") + 2 == length($ret));
	};

	# state: 0 - writing, 1 - reading, 2 - done
	my $state = 0; # writing 

	# the bitsets for select
	my ($rin, $rout, $win, $wout);
	my $nfound;

	my $last_state = -1;
	local $SIG{'PIPE'} = "IGNORE" unless $FLAG_NOSIGNAL;

	# select loop
	while (1) {
		if ($last_state != $state) {
			last if $state == 2; # done
			($rin, $win) = ('','');
			vec($rin, fileno($sock), 1) = 1 if $state == 1; # reading
			vec($win, fileno($sock), 1) = 1 if $state == 0; # writing
			$last_state = $state;
		}

		$nfound = select($rout=$rin, $wout=$win, undef, $self->{'select_timeout'});
		last unless $nfound;

		if (vec($wout, fileno($sock), 1)) {
			$res = send($sock, $line, $FLAG_NOSIGNAL);
			
			next if not defined $res and $! == EWOULDBLOCK;

			if (!defined $res || $res <= 0) {
				$self->next_server(1); # disconnected, reconnect
				return undef;
			}

			if ($res == length($line)) { # all data sent
				$state = 1; # start reading
			} else {
				substr($line, 0, $res, ''); # delete the part we sent
			}
		}

		if (vec($rout, fileno($sock), 1)) {
			$res = sysread($sock, $ret, 255, $offset);

			next if not defined $res and $! == EWOULDBLOCK;

			if ($res <= 0) {
				$self->next_server(1); # disconnected, reconnect
				return undef;
			}

			$offset += $res; # read $res bytes

			$state = 2 if $check_complete->(\$ret); # are we done reading?
		}
	}

	unless ($state == 2) { # done
		$self->next_server(1); # improperly finished, reconnect
		return undef;
	}

	$self->{'last_message'} = $ret;

	return $ret;
}

sub handle_errors ($$$@) {
	my ($self, $message, $command, @args) = @_;

	# Try next server if possible
	if ($message =~ m/DRAINING/i) {
		$self->next_server(1);
		shift @args;
		return $self->$command(@args);
	}
	return undef;
}

sub put {
        my ($self, $data, $pri, $delay, $ttr) = @_;

	$pri ||= 4294967295;
	$pri %= 2**32;
	$delay ||= 0;
	$delay = int($delay);
        $ttr = defined $ttr ? int($ttr) : 120;

	my $ret = $self->_write_and_read("put $pri $delay $ttr " . length($data) . "\r\n$data\r\n");

	return undef unless defined $ret;

	$self->next_server if $self->{'auto_next_server'};

        if ($ret =~ m/INSERTED (\d+)/) {
                $self->{'last_insert_id'} = $1;
                return 'inserted';
        }
	return 'buried' if $ret =~ m/BURIED/;

	

	$self->warn('Invalid data returned from server') unless $self->handle_errors($ret,'put',@_);
	return undef;
}

sub stats {
	my $self = shift;
	my $id = defined $_[0] ? ' ' . int(shift()) : '';

	my ($data, $bytes) = $self->_write_and_read_data("stats$id\r\n", sub {
		if ($_[0] =~ m/ok (\d+)/i) {
			return ($1);
		} else {
			return undef;
		}
	});

	my $result = eval "use YAML; return 1;";
	if ($result) {
		return YAML::Load($data);
	} else {
		$self->warn('YAML module missing');
		return $data;
	}
}

sub reserve {
	my ($self) = @_;

	if ($self->{'job_id'}) {

		# Unfinished job, let someone else have it
		$self->_write_and_read("release " . $self->{'job_id'} . " " . $self->{'job_pri'} . " 0\r\n");
		$self->{'job_id'} = undef;
		$self->{'job_pri'} = undef;
		$self->{'job_data'} = undef;	

	}

	my $old_timeout = $self->{'select_timeout'};
	$self->{'select_timeout'} = $self->{'reserve_timeout'}; # set temporary timeout for reserve-request

	# Send request
	my ($data, $bytes, $id, $pri) = $self->_write_and_read_data("reserve\r\n", sub {
		if ($_[0] =~ m/reserved (\d+) (\d+) (\d+)/i) {
			return ($3,$1,$2); # "bytes" value must be first return-parameter
		} else {
			return undef;
		}
	});

	return undef unless defined $bytes;

	$self->{'select_timeout'} = $old_timeout;

	$self->{'job_id'} = $id;
	$self->{'job_pri'} = $pri;
	$self->{'job_data'} = $data;

	return $data;
}

sub release {
	my ($self, $pri, $delay) = @_;

	if ($self->{'job_id'}) {
		$self->warn('no job reserved yet');
		return undef;
	}
	my $res = $self->_write_and_read("release " .
		$self->{'job_id'} . " " .
		( ($pri % 2**32) || $self->{'job_pri'} ) . " " . # priority
		( defined $delay ? int($delay) : 0 ) .           # delay
	"\r\n");

	if ($res =~ m/RELEASED|BURIED/) {
		$self->{'job_id'} = undef;
		$self->{'job_pri'} = undef;
		$self->{'job_data'} = undef;

		$self->next_server if $self->{'auto_next_server'};

		return 'released' if ($res =~ m/RELEASED/i);
		return 'buried' if ($res =~ m/BURIED/i);
	}
	return undef;
}


sub delete {
	my $self = shift;

	if (!defined $self->{'job_id'} || !$self->{'job_id'}) {
		$self->warn('no job reserved yet');
		return undef;
	}

	my $res = $self->_write_and_read("delete " . $self->{'job_id'} . "\r\n");

	if ($res =~ m/DELETED/) {
		$self->{'job_id'} = undef;
		$self->{'job_pri'} = undef;
		$self->{'job_data'} = undef;

		$self->next_server if $self->{'auto_next_server'};

		return 1;
	}
	return 0;
}

1;
__END__

=head1 NAME

Queue::Beanstalk - Client library for the beanstalkd server

=head1 SYNOPSIS

Producer example:

  use Queue::Beanstalk;
  
  $jobs = Queue::Beanstalk->new(
                                 'servers' =>  [ '127.0.0.1:11300' ],
                                 'connect_timeout' => 2,
  );
  
  # Adds a job with priority 4294967295 and 0 delay  
  $jobs->put('do:something');
  
  # Adds a job with 0 (highest) priority and 1 second delay
  $jobs->put(('do:somethingelse', 0, 1);

Worker example:

  use Queue::Beanstalk;
  
  $jobs = Queue::Beanstalk->new(
                                 'servers' =>  [ '127.0.0.1:11300' ],
                                 'connect_timeout' => 2,
  );
  
  while (1) {
    my $data;
    
    if ($data = $jobs->reserve()) {
  
      if (do_something($data)) {
        $jobs->delete();  # done with the job
      } else {
        $jobs->release(); # i failed, let someone else take it
      }
      $jobs->next_server(); # optional, if you have several servers
  
    }
  
    sleep(1); # prevent cpu intensive loop (just in case)
  }

B<WARNING!> This module is marked as being in the alpha stage, and is therefore subject to change in near future. This version of Queue::Beanstalk currently supports the 0.6 protocol version of Beanstalkd.

=head1 DESCRIPTION

Client library for Beanstalk. Read more about the Beanstalkd daemon at

  http://xph.us/software/beanstalkd/

=head1 CONSTRUCTOR


=head2 C<new>

Has the following hashref options:

=over 4

=item C<servers>

An arrayref of servers that can be connected to. Must be in the host:port format.
By default the module wil randomly select a server to connect to. You can change
this behaviour with the random_servers option.

=item C<random_servers>

If given a false value, the module will follow the order of the servers array and
select the next server in the list on subsequent calls to next_server(); When using
this module as a 'producer', it is best to leave the default value of true, so the
clients will randomly connect to one of your beantalkd servers.

=item C<auto_next_server>

Will automatically go to the next or a random server after a successful C<put> or
C<delete>. Default value is false.

=item C<report_errors>

When given a false value, the module will not give any errormessages out loud. And
will only exit the functions with an undefined value, the corresponding
error-messages however will be found in the 'errstr' variable of the object.

=item C<connect_timeout>

Amount of seconds to wait for a connection to go through. Default is 0.25 second.

=item C<select_timeout>

Amount of seconds to wait for a socket to have data available. Default is 1 second.

=item C<reserve_timeout>

Amount of seconds to wait for an available job to reserve. Default is 10 seconds.

=back

=head1 METHODS

=head2 C<put>

$jobs->put($job_data[, $priority, $delay])

Insert a job into the queue. Priority is an integer between 0 (highest) and 4294967295 (lowest).
Default priority is 4294967295. Default delay is 0.

Returns an undefined value on errors, 'inserted' or 'burried'.

=head2 C<stats>

$jobs->stats();

Returns YAML stats output from beanstalkd. B<TODO:> Parse yaml and return hashref.

=head2 C<reserve>

$jobs->reserve();

Returns undef on failure/timeout, or full job-data if successful. You have 120 seconds to fullfil the job, before beanstalkd gives up on you.

=head2 C<release>

$jobs->release([$priority, $delay]);

Release the current reserved job. The default is to use the same priority as the job had, and 0 second delay.

=head2 C<delete>

$jobs->delete();

Delete the current reserved job. Removes the job from the queue as the job is finished.

=head1 AUTHOR

Håkon Nessjøen, Loopback Systems AS, E<lt>lunatic@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 by Loopback Systems AS

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
