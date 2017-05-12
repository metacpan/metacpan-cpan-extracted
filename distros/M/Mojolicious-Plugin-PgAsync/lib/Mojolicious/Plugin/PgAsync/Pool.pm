package Mojolicious::Plugin::PgAsync::Pool;
use Mojo::Base -base;

use Data::Dumper;
use Mojolicious::Plugin::PgAsync::Db;

our $VERSION = '0.01';

has ioloop => sub { Mojo::IOLoop->singleton };
has [qw/ dbi ttl /];
has [qw/ db_free /] => sub {[]};
has db_pool => sub {{}};

our $debug = $ENV{DEBUG_PG};


sub get {
	my $self = shift;

	my $db = shift @{$self->db_free};
	say "have free db $db" if $debug && $db;
	if ($db) {
		if (my $timer_id = $self->db_pool->{$db}{timer_id}) {
			say "remove timer $timer_id for $db" if $debug;
			$self->ioloop->remove($timer_id);
		}

		return $db
	}

	$db = Mojolicious::Plugin::PgAsync::Db->new
			->dbi($self->dbi)
			->make_free(sub { $self->_make_free(@_) })
			;
	say "new db $db" if $debug;
	return $db
}

sub _make_free {
	my $self = shift;
	my $db = shift;

	unless (grep {$db eq $_} @{$self->db_free}) {
		push @{$self->db_free}, $db;
	}

	my $timer_id; $timer_id = Mojo::IOLoop->timer($self->ttl => sub {
			my $loop = shift;

			say "ttl $timer_id for $db" if $debug;
			$db->disconnect;
			$self->db_free([grep {$db ne $_} @{$self->db_free}]);
			delete $self->db_pool->{$db};
		}
	);

	say "set timer $timer_id for $db" if $debug;
	$self->db_pool->{$db}{timer_id} = $timer_id;
}

sub fetch {
	my $self = shift;
	my $db = shift;

	$self->db_free([grep {$db ne $_} @{$self->db_free}]);

	return $db
}


1

