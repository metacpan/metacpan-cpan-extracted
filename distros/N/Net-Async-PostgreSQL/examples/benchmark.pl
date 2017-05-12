#!/usr/bin/perl
use strict;
use warnings;
use Benchmark qw(:hireswallclock);

use IO::Async::Loop;
use Net::Async::PostgreSQL::Client;

my $code = sub {
	my $port = shift;
my $loop = IO::Async::Loop->new;
my $client = Net::Async::PostgreSQL::Client->new(
	debug			=> 0 && sub { warn "@_" },
	host			=> $ENV{NET_ASYNC_POSTGRESQL_SERVER} || 'localhost',
	service			=> $port,
#	ssl			=> 1,
	database		=> $ENV{NET_ASYNC_POSTGRESQL_DATABASE},
	user			=> $ENV{NET_ASYNC_POSTGRESQL_USER},
	pass			=> $ENV{NET_ASYNC_POSTGRESQL_PASS},
);
#$client->init;

my @query_list = (
	q{begin work},
	q{create schema nap_test},
	q{create table nap_test.nap_1 (id serial primary key, name varchar, creation timestamp, id1 bigint, id2 bigint, k1 text, k2 text)},
);

my $init = 0;
my $finished = 0;
my %status;
my $rfq = sub {
	my $self = shift;
	unless($init) {
#		print "Server version " . $status{server_version} . "\n";
		++$init;
	}
	my $q = shift(@query_list);
	return $self->simple_query($q) if $q;

	if($finished == 1) {
		$self->simple_query(q{select * from nap_test.nap_1});
		++$finished;
		return;
	} elsif($finished == 2) {
		$self->simple_query(q{rollback});
		++$finished;
		return;
	} elsif($finished == 3) {
		$loop->later(sub {
			$client->transport->configure(on_outgoing_empty => sub {
				$client->close;
				$loop->later(sub { $loop->loop_stop; });
			});
			$self->send_message('Terminate');
		});
		++$finished;
		return;
	}

	$self->simple_query(q{copy nap_test.nap_1 (name,creation, id1, id2, k1, k2) from stdin});
	return;
};
$client->add_handler_for_event(
	error	=> sub {
		my ($self, %args) = @_;
		print "Received error\n";
		my $err = $args{error};
		warn "$_ => " . $err->{$_} . "\n" for sort keys %$err;
		return 1;
	},
	command_complete => sub {
		my $self = shift;
		return 1;
	},
	copy_in_response => sub {
		my ($self, %args) = @_;
		my $k1 = 'aaaaaaaaaaa';
		$self->send_copy_data(['some name', '2010-01-01 00:00:00', int(rand() * 10_000_000), $$ ^ time, ++$k1, localtime() . {} ]) for 0..10_000;
		++$finished;
		$self->copy_done;
		return 1;
#		$self->attach_event(ready_for_query => $rfq);
	},
	ready_for_query => sub { $rfq->(@_); return 1; },
	parameter_status => sub {
		my $self = shift;
		my %args = @_;
		$status{$_} = $args{status}->{$_} for sort keys %{$args{status}};
		return 1;
	},
	row_description => sub {
		my $self = shift;
		my %args = @_;
		return 1;
	},
	data_row => sub {
		my $self = shift;
		my %args = @_;
		return 1;
	},
);
$loop->add($client);
$client->connect;
$loop->loop_forever;
};
timethese(10, {
	5432	=> sub { $code->(5432, @_) },
	6432	=> sub { $code->(6432, @_) }
});

exit 0;
