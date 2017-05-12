package Mojolicious::Plugin::PgAsync::Db;
use Mojo::Base 'Mojo::EventEmitter';

use IO::Handle;
use DBD::Pg ':async';
use Data::Dumper;

our $VERSION = '0.01';

our $debug = $ENV{DEBUG_PG};

has [qw/ dbi sth handle make_free /];
my @class_attr = qw/ callback sql attr values /;
has \@class_attr;
has ioloop => sub { Mojo::IOLoop->singleton };
has dbh => sub {
	my $self = shift;
	my $dbh = DBI->connect(@{$self->dbi});
	$self->handle(IO::Handle->new_from_fd($dbh->{pg_socket}, 'r'));

	my $reactor = $self->ioloop->reactor;
	$reactor->io($self->handle =>
		sub {
			my $reactor = shift;

			unless ($self->sth) {
				if (my $notify = $dbh->pg_notifies) {
					my $notify_hash = {
						name => $notify->[0],
						channel => $notify->[0],
						pid => $notify->[1],
						payload => $notify->[2],
					};
					$self->callback->($notify_hash, $notify_hash);
				}
				else {
					$self->callback->();
				}
			}
			else {
				my $result = $self->sth->pg_result;
				say "result $self $result" if $debug;
				$self->callback->($self, $self);
			}

			# Clear class attributes
			$self->$_(undef) for @class_attr;

			$self->make_free->($self);
		}
	)->watch($self->handle, 1, 0);

	return $dbh
};

sub execute {
	my $self = shift;
	my @values = @{$_[0]};

	$self->attr({%{$self->attr || {}}, pg_async => PG_ASYNC});

	say "execute $self" if $debug;
	$self->sth($self->dbh->prepare($self->sql, $self->attr));
	$self->sth->execute(@values);

	return $self
}

sub listen {
	my $self = shift;
	my $channel = shift;

	$self->sth(undef);
	say "channel $channel" if $debug;
	$self->dbh->do("LISTEN $channel");
	$self->dbh->commit unless $self->dbh->{AutoCommit};

	return $self
}

sub disconnect {
	my $self = shift;

	say "disconnect $self" if $debug;
	$self->ioloop->reactor->remove($self->handle) if $self->ioloop;
	$self->dbh->disconnect if $self->dbh;
}

1

