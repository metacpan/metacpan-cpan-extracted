#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::Storage::Generic::DBI;
use Moose;

with qw(POE::Component::MessageQueue::Storage::Generic::Base);

use DBI;
use Exception::Class::DBI;
use Exception::Class::TryCatch;

sub dsn      { return $_[0]->servers->[0]->{dsn}; }
sub username { return $_[0]->servers->[0]->{username}; }
sub password { return $_[0]->servers->[0]->{password}; }
sub options  { return $_[0]->servers->[0]->{options}; }

has 'servers' => (
	is => 'ro',
	isa => 'ArrayRef[HashRef]',
	required => 1,
	default => sub { return [] },
);

has 'mq_id' => (
	is       => 'ro',
	isa      => 'Str',
);

has 'dbh' => (
	is => 'ro',
	isa => 'Object',
	writer => '_dbh',
	lazy => 1,
	builder => '_build_dbh',
	init_arg => undef,
);

has 'cur_server' => (
	is => 'ro',
	isa => 'Int',
	writer => '_cur_server',
	default => sub { return -1 },
	init_arg => undef,
);

has max_retries => (
    is      => 'ro',
    isa     => 'Int',
    default => 10,
);

# NOT async!
sub _clear_claims {
	my ($self) = @_;
	
	# Clear all this servers claims
	my $sql = "UPDATE messages SET in_use_by = NULL";
	my $mq_id = $self->mq_id;
	if (defined $mq_id and $mq_id ne '') {
		$sql .= " WHERE in_use_by LIKE '$mq_id:%'";
	}

	$self->dbh->do($sql);
}

around BUILDARGS => sub
{
	my ($orig, $class) = @_;
	my %args = @_;

	if (!defined($args{servers})) {
		$args{servers} = [{
			dsn      => $args{dsn},
			username => $args{username},
			password => $args{password},
			options  => $args{options} || {},
		}];
	}

	return $class->$orig(%args);
};

sub BUILD 
{
	my ($self, $args) = @_;

	foreach my $server (@{$self->servers}) {
		if (!defined $server->{options}) {
			$server->{options} = {};
		}

		# Force exception handling
		$server->{options}->{'HandleError'} = Exception::Class::DBI->handler,
		$server->{options}->{'PrintError'} = 0;
		$server->{options}->{'RaiseError'} = 0;
	}

	# This actually makes DBH connect
	$self->_clear_claims();
}

sub _build_dbh
{
	my ($self) = @_;

	my $i = $self->cur_server + 1;
	my $count = scalar @{$self->servers};
	my @servers = map { [$_, $self->servers->[$_]] } (0 .. $count-1);
	my $dbh;

	# re-arrange the server list, so that it starts on $i
	@servers = (@servers[$i .. $count-1], @servers[0 .. $i-1]);

	while (1) {
		foreach my $spec ( @servers ) {
			my ($id, $server) = @$spec;

			$self->log(info => "Connecting to DB: $server->{dsn}");
			try eval {
				$dbh = DBI->connect($server->{dsn}, $server->{username}, $server->{password}, $server->{options});
			};
			if (my $err = catch) {
				$self->log(error => "Unable to connect to DB ($server->{dsn}): $err");
				$dbh = undef;
			}

			if (defined $dbh) {
				$self->_cur_server($id);
				return $dbh;
			}
		}

		if ($self->cur_server == -1) {
			# if this is our first connection on MQ startup, we should fail loudly..
			$self->log(error => "Unable to connect to database.");
			die "Unable to connect to database.";
		}

		# after trying them all we sleep for 1 second, so that we don't hot-loop and
		# the system has a chance to get back up.
		$self->log(error => "Unable to connect to any DB servers.  Waiting 1 second and then retrying...");
		# this is OK because we are in PoCo::Generic
		sleep 1;
	}
}

sub _wrap {
    my ($self, $name, $action) = @_;
    my $trying = 1;
    my $max_retries = $self->max_retries;

    while ($trying++) {
        if ($trying >= $max_retries) {
            $self->log(error =>
                "Giving up on $name() after trying $max_retries times");
            return 0;
        }
        try eval {
            $action->();
            # it was a success, so no need to try any more
            $trying = 0;
        };
        if (my $err = catch)
        {
            $self->log(error => "Error in $name(): $err");
            $self->log(error => "Going to reconnect to DB to try again...");
            $self->_dbh($self->_build_dbh());
        }
    }

    return 1;
}

sub _make_where
{
	my $ids = shift;
	return join(' OR ', map "message_id = '$_'", @$ids);
}

sub _wrap_ids
{
	my ($self, $ids, $name, $action) = @_;
	$self->_wrap(name => sub {$action->(_make_where($ids))}) if (@$ids > 0);
}

sub _make_message { 
	my ($self, $h) = @_;
	my %map = (
		id          => 'message_id',
		destination => 'destination',
		body        => 'body',
		persistent  => 'persistent',
		claimant    => 'in_use_by',
		size        => 'size',
		timestamp   => 'timestamp',
		deliver_at  => 'deliver_at',
	);
	my %args;
	foreach my $field (keys %map) 
	{
		my $val = $h->{$map{$field}};
		$args{$field} = $val if (defined $val);
	}
	# pull only the client ID out of the in_use_by field
	my $mq_id = $self->mq_id;
	if (defined $mq_id and $mq_id ne '' and defined $args{claimant}) {
		$args{claimant} =~ s/^$mq_id://;
	}
	return POE::Component::MessageQueue::Message->new(%args);
};

sub _in_use_by {
	my ($self, $client_id) = @_;
	if (defined $client_id and defined $self->mq_id and $self->mq_id ne '') {
		return $self->mq_id .":". $client_id;
	}
	return $client_id;
}

# Note:  We explicitly set @_ in all the storage methods in this module,
# because when we do our tail-calls (goto $method), we don't want to pass them
# anything unneccessary, particulary $callbacks.

sub store {
	my ($self, $m, $callback) = @_;

	$self->_wrap(store => sub {
		my $sth = $self->dbh->prepare(q{
			INSERT INTO messages (
				message_id, destination, body, 
				persistent, in_use_by,  
				timestamp,  size,
				deliver_at
			) VALUES (
				?, ?, ?, 
				?, ?, 
				?, ?,
				?
			)
		});
		$sth->execute(
			$m->id,         $m->destination, $m->body, 
			$m->persistent, $self->_in_use_by($m->claimant), 
			$m->timestamp,  $m->size,
			$m->deliver_at
		);
    }) or $self->log(error => sprintf
        "Could not store message '%s' to queue %s", $m->body, $m->destination);

	@_ = ();
	goto $callback if $callback;
}

sub _get
{
	my ($self, $name, $clause, $callback) = @_;
	my @messages;
	$self->_wrap($name => sub {
		my $sth = $self->dbh->prepare("SELECT * FROM messages	$clause");
		$sth->execute;
		my $results = $sth->fetchall_arrayref({});
		@messages = map $self->_make_message($_), @$results;
	});
	@_ = (\@messages);
	goto $callback;
}

sub _get_one
{
	my ($self, $name, $clause, $callback) = @_;
	$self->_get($name, $clause, sub {
		my $messages = $_[0];
		@_ = (@$messages > 0 ? $messages->[0] : undef);
		goto $callback;
	});
}

sub get
{
	my ($self, $message_ids, $callback) = @_;
	$self->_get(get => 'WHERE '._make_where($message_ids), $callback);
}

sub get_all
{
	my ($self, $callback) = @_;
	$self->_get(get_all => '', $callback);
}

sub get_oldest
{
	my ($self, $callback) = @_;
	$self->_get_one(get_oldest => 'ORDER BY timestamp ASC LIMIT 1', $callback);
}

sub claim_and_retrieve
{
	my ($self, $destination, $client_id, $callback) = @_;
	my $time = time();
	$self->_get_one(claim_and_retrieve => qq{
		WHERE destination = '$destination' AND in_use_by IS NULL AND
		      (deliver_at IS NULL OR deliver_at < $time)
		ORDER BY timestamp ASC LIMIT 1
	}, sub {
		if(my $message = $_[0])
		{
			$self->claim($message->id, $client_id)
		}
		goto $callback;
	});
}

sub remove
{
	my ($self, $message_ids, $callback) = @_;
	$self->_wrap_ids($message_ids, remove => sub {
		my $where = shift;
		$self->dbh->do("DELETE FROM messages WHERE $where");
	});
	@_ = ();
	goto $callback if $callback;
}

sub empty
{
	my ($self, $callback) = @_;
	$self->_wrap(empty => sub {$self->dbh->do("DELETE FROM messages")});
	@_ = ();
	goto $callback if $callback;
}

sub claim
{
	my ($self, $message_ids, $client_id, $callback) = @_;
	my $in_use_by = $self->_in_use_by($client_id);
	$self->_wrap_ids($message_ids, claim => sub {
		my $where = shift;
		$self->dbh->do(qq{
			UPDATE messages SET in_use_by = '$in_use_by' WHERE $where
		});
	});
	@_ = ();
	goto $callback if $callback;
}

sub disown_destination
{
	my ($self, $destination, $client_id, $callback) = @_;
	my $in_use_by = $self->_in_use_by($client_id);
	$self->_wrap(disown_destination => sub {
		$self->dbh->do(qq{
			UPDATE messages SET in_use_by = NULL WHERE in_use_by = '$in_use_by'
			AND destination = '$destination'
		});
	});
	@_ = ();
	goto $callback if $callback;
}

sub disown_all
{
	my ($self, $client_id, $callback) = @_;
	my $in_use_by = $self->_in_use_by($client_id);
	$self->_wrap(disown_all => sub {
		$self->dbh->do(qq{
			UPDATE messages SET in_use_by = NULL WHERE in_use_by = '$in_use_by'
		});
	});
	@_ = ();
	goto $callback if $callback;
}

sub storage_shutdown
{
	my ($self, $callback) = @_;

	$self->log(alert => 'Shutting down DBI storage engine...');

	$self->_clear_claims();
	$self->dbh->disconnect();
	@_ = ();
	goto $callback if $callback;
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::Generic::DBI -- A storage engine that uses L<DBI>

=head1 SYNOPSIS

  use POE;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::Generic;
  use POE::Component::MessageQueue::Storage::Generic::DBI;
  use strict;

  # For mysql:
  my $DB_DSN      = 'DBI:mysql:database=perl_mq';
  my $DB_USERNAME = 'perl_mq';
  my $DB_PASSWORD = 'perl_mq';
  my $DB_OPTIONS  = undef;

  POE::Component::MessageQueue->new({
    storage => POE::Component::MessageQueue::Storage::Generic->new({
      package => 'POE::Component::MessageQueue::Storage::DBI',
      options => [{
        # if there is only one DB server
        dsn      => $DB_DSN,
        username => $DB_USERNAME,
        password => $DB_PASSWORD,
        options  => $DB_OPTIONS,

        # OR, if you have multiple database servers and want to failover
        # when one goes down.

        #servers => [
        #  {
        #    dsn => $DB_SERVER1_DSN,
        #    username => $DB_SERVER1_USERNAME,
        #    password => $DB_SERVER1_PASSWORD,
        #    options  => $DB_SERVER1_OPTIONS
        #  },
        #  {
        #    dsn => $DB_SERVER2_DSN,
        #    username => $DB_SERVER2_USERNAME,
        #    password => $DB_SERVER2_PASSWORD,
        #    options  => $DB_SERVER2_OPTIONS
        #  },
        #],
      }],
    })
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

A storage engine that uses L<DBI>.  All messages stored with this backend are
persistent.

This module is not itself asynchronous and must be run via 
L<POE::Component::MessageQueue::Storage::Generic> as shown above.

Rather than using this module "directly" [1], I would suggest wrapping it inside of
L<POE::Component::MessageQueue::Storage::FileSystem>, to keep the message bodys on
the filesystem, or L<POE::Component::MessageQueue::Storage::Complex>, which is the
overall recommended storage engine.

If you are only going to deal with very small messages then, possibly, you could 
safely keep the message body in the database.  However, this is still not really
recommended for a couple of reasons:

=over 4

=item *

All database access is conducted through L<POE::Component::Generic> which maintains
a single forked process to do database access.  So, not only must the message body be
communicated to this other proccess via a pipe, but only one database operation can
happen at once.  The best performance can be achieved by having this forked process
do as little as possible.

=item *

A number of databases have hard limits on the amount of data that can be stored in
a BLOB (namely, SQLite, which sets an artificially lower limit than it is actually
capable of).

=item *

Keeping large amounts of BLOB data in a database is bad form anyway!  Let the database do what
it does best: index and look-up information quickly.

=back

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item dsn => SCALAR

=item username => SCALAR

=item password => SCALAR

=item options => SCALAR

=item servers => ARRAYREF

An ARRAYREF of HASHREFs containing dsn, username, password and options.  Use this when you 
have serveral DB servers and want Storage::DBI to failover when one goes down.

=item mq_id => SCALAR

A string which uniquely identifies this MQ.  This is required when running two MQs which 
use the same database.  If they don't have unique mq_id values, than one MQ could inadvertently
clear the claims set by the other, causing messages to be delivered more than once.

=back

=head1 SUPPORTED STOMP HEADERS

=over 4

=item B<persistent>

I<Ignored>.  All messages are persisted.

=item B<expire-after>

I<Ignored>.  All messages are kept until handled.

=item B<deliver-after>

I<Fully Supported>.

=back

=head1 FOOTNOTES

=over 4

=item [1] 

By "directly", I still mean inside of L<POE::Component::MessageQueue::Storage::Generic> because
that is the only way to use this module.

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage>,
L<DBI>

I<Other storage engines:>

L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

=cut

