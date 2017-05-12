use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;
use Time::HiRes 'sleep';
use DBI;
use lib 'lib';

my $wait = 1;
my $dsn		= $ENV{DBI_DSN}		|| 'dbi:Pg:dbname=test';
my $user	= $ENV{DBI_USER}	|| 'postgres';
my $pass	= $ENV{DBI_PASS}	|| '';

# If can't connect skip tests
DBI->connect($dsn, $user, $pass)
	or plan skip_all => sprintf 'Cannot connect to DB <%s>, <%s>, <%s>',
		$dsn, $user, $pass;


plugin PgAsync => {
	dbi	=> [$dsn, $user, $pass, {AutoCommit => 0, RaiseError => 1}],
	ttl	=> 0.5,
};

get '/1' => sub {
	my $self = shift->render_later;

	$self->pg("SELECT 12 AS id, pg_sleep(?)", undef, $wait, sub {
		my $db = shift;
		my $info = $db->sth->fetchall_arrayref({});
		#say Dumper $info;

		$self->render(text => 'Hello Mojo! '.$info->[0]{id});
	});
};

get '/2' => sub {
	my $self = shift->render_later;

	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg('SELECT 13 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
		},
		sub {
			my $delay = shift;
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			$self->render(text => $info->[0]{id});
		},
	);
};

get '/3' => sub {
	my $self = shift->render_later;

	my @res;
	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg('SELECT 14 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			say 'script 1';
		},
		sub {
			my $delay = shift;
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			push @res, $info->[0]{id};
			$self->pg('SELECT 15 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			say 'script 2';
		},
		sub {
			say 'script 3';
			my $delay = shift;
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			push @res, $info->[0]{id};
			$self->render(text => join ',', @res);
		},
	);
};

get '/4' => sub {
	my $self = shift->render_later;

	my @res;
	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg('SELECT 16 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg('SELECT 17 AS id, pg_sleep(?)', undef, $wait,  $delay->begin);
			say 'script 1';
		},
		sub {
			my $delay = shift;
			for my $db (@_) {
				#say "script sth $sth";
				my $info = $db->sth->fetchall_arrayref({});
				push @res, $info->[0]{id};
			}
			$self->pg('SELECT 18 AS id, pg_sleep(0.5)', $delay->begin);
			say 'script 2';
		},
		sub {
			say 'script 3';
			my $delay = shift;
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			push @res, $info->[0]{id};
			$self->render(text => join ',', @res);
		},
	);
};

get '/5' => sub {
	my $self = shift->render_later;

	my @res;
	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg('SELECT 19 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg('SELECT 20 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg('INSERT INTO test (name) VALUES (?)', undef, 'mojo', $delay->begin);
			say 'script 1';
		},
		sub {
			my $delay = shift;
			for my $db ($_[0], $_[1]) {
				#say "script sth $sth";
				my $info = $db->sth->fetchall_arrayref({});
				push @res, $info->[0]{id};
			}

			#$delay->begin->();

			my $db = $_[2];
			$db->dbh->commit;
		},
		sub {
			my $delay = shift;
			push @res, $_[1];
			$self->pg('SELECT 21 AS id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg(q/SELECT name FROM test WHERE name LIKE ?/, undef, 'mojo', $delay->begin);
			say 'script 2';
		},
		sub {
			say 'script 3';
			my $delay = shift;
			my $db1 = $_[0];
			my $db2 = $_[1];
			my $info1 = $db1->sth->fetchall_arrayref({});
			my $info2 = $db2->sth->fetchall_arrayref({});
			push @res, $info1->[0]{id}, $info2->[0]{name};
			$self->render(text => join ',', @res);
		},
	);
};

get '/6' => sub {
	my $self = shift->render_later;

	$self->pg_listen('foo6', sub {
		my $notify = shift;
		#my $info = $sth->fetchall_arrayref({});
		#say Dumper $info;

		$self->render(text => 'listen '.$notify->{name});
	});

	sleep 0.2;

	$self->pg(q/SELECT pg_notify('foo6','pl6')/, sub {
			say 'notify';
			my($db) = @_;
			$db->dbh->commit;
		});
};

get '/7' => sub {
	my $self = shift->render_later;

	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg_listen('foo7', $delay->begin);
			$self->pg_listen('bar7', $delay->begin);
		},
		sub {
			my $delay = shift;
			my($notify1, $notify2) = @_;

			$self->render(text => "listen $notify1->{name} $notify2->{name}");
		},
	);

	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			Mojo::IOLoop->timer(0.2 => $delay->begin);
		},
		sub {
			my $delay = shift;
			$self->pg(q/SELECT pg_notify('foo7','pl foo 7')/, $delay->begin);
			$self->pg(q/SELECT pg_notify('bar7','pl bar 7')/, $delay->begin);
		},
		sub {
			my $delay = shift;
			my($db1, $db2) = @_;
			$db1->dbh->commit;
			$db2->dbh->commit;
			say 'commit';
		},
	);
};

get '/8' => sub {
	my $self = shift->render_later;

	my @res;

	Mojo::IOLoop->delay(
		sub {
			my $delay = shift;
			$self->pg('SELECT 22 as id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg('SELECT 23 as id, pg_sleep(?)', undef, $wait, $delay->begin);
		},
		sub {
			my $delay = shift;
			my($db1, $db2) = @_;
			my $info1 = $db1->sth->fetchall_arrayref({});
			my $info2 = $db2->sth->fetchall_arrayref({});
			push @res, $info1->[0]{id}, $info2->[0]{id};
			say "got 22,23";
			$self->pg('SELECT 24 as id, pg_sleep(?)', undef, $wait, $delay->begin);
		},
		sub {
			my $delay = shift;
			my($db1) = @_;
			my $info1 = $db1->sth->fetchall_arrayref({});
			push @res, $info1->[0]{id};
			say "got 24";
			$self->pg('SELECT 25 as id, pg_sleep(?)', undef, $wait, $delay->begin);
			$self->pg('SELECT 26 as id, pg_sleep(?)', undef, $wait, $delay->begin);
		},
		sub {
			my $delay = shift;
			my($db1, $db2) = @_;
			my $info1 = $db1->sth->fetchall_arrayref({});
			my $info2 = $db2->sth->fetchall_arrayref({});
			push @res, $info1->[0]{id}, $info2->[0]{id};
			say "got 25,26";
			$self->render(text => join ',', @res);
		},
	);
};

get '/9' => sub {
	my $self = shift->render_later;

	$self->pg('SELECT 3 as id, pg_sleep(?)', undef, $wait,
		sub {
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			$self->render(text => $info->[0]{id});
		}
	);
};

get '/10' => sub {
	my $self = shift->render_later;

	$self->pg('UPDATE test SET name=?', undef, 'q',
		sub {
			my $db = shift;
			my $rv = $db->sth->rows;
			$self->render(text => $rv);
		}
	);
};

my $t = Test::Mojo->new;
$t->get_ok('/1')->status_is(200)->content_is('Hello Mojo! 12');
$t->get_ok('/2')->status_is(200)->content_is('13');
$t->get_ok('/3')->status_is(200)->content_is('14,15');
$t->get_ok('/4')->status_is(200)->content_is('16,17,18');
#$t->get_ok('/5')->status_is(200)->content_is('19,20,1,21,mojo');
$t->get_ok('/6')->status_is(200)->content_is('listen foo6');
$t->get_ok('/7')->status_is(200)->content_is('listen foo7 bar7');
$t->get_ok('/8')->status_is(200)->content_is('22,23,24,25,26');
$t->get_ok('/9')->status_is(200)->content_is('3');
#$t->get_ok('/10')->status_is(200)->content_is('0');

done_testing();

__DATA__
@@ exception.html.ep
%= $exception->message
