#!/usr/bin/perl
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::PostgreSQL::Client;

my $loop = IO::Async::Loop->new;
my $client = Net::Async::PostgreSQL::Client->new(
	debug			=> 0,
	host			=> $ENV{NET_ASYNC_POSTGRESQL_SERVER} || 'localhost',
	service			=> $ENV{NET_ASYNC_POSTGRESQL_PORT} || 5432,
	database		=> $ENV{NET_ASYNC_POSTGRESQL_DATABASE},
	user			=> $ENV{NET_ASYNC_POSTGRESQL_USER},
	pass			=> $ENV{NET_ASYNC_POSTGRESQL_PASS},
);

my @query_list = (
	q{begin work},
	q{create schema nap_test},
	q{create table nap_test.nap_1 (id serial primary key, name varchar, creation timestamp)},
	q{insert into nap_test.nap_1 (name, creation) values ('test', 'now')},
	q{insert into nap_test.nap_1 (name, creation) values ('test2', 'now')},
	q{select * from nap_test.nap_1},
);
my $init = 0;
my $finished = 0;
my %status;
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
		print "Command complete\n";
		warn $finished;
		if($finished == 1) {
			print "run query\n";
			$self->simple_query(q{select * from nap_test.nap_1});
			++$finished;
			return 1;
		} elsif($finished == 2) {
			$self->add_handler_for_event(
				ready_for_query => sub {
					$client->add_handler_for_event(
						closed => sub {
							$loop->later(sub {
								$loop->loop_stop;
							});
							return 0;
						}
					);
					$client->terminate;
					0;
				}
			);
			$self->simple_query(q{rollback});
			return 0;
		}

		return 1;
	},
	copy_in_response => sub {
		my ($self, %args) = @_;
		print "Copy in response\n";
		$self->copy_data("some name\t2010-01-01 00:00:00");
		$loop->later(sub {
			++$finished;
			$self->copy_done;
		});
		return 0;
	},
	ready_for_query => sub {
		my $self = shift;
		print "Ready for query\n";
		return if $finished;
		unless($init) {
			print "Server version " . $status{server_version} . "\n";
			++$init;
		}
		my $q = shift(@query_list);
		if($q) {
			$self->simple_query($q);
		} else {
			$self->simple_query(q{copy nap_test.nap_1 (name,creation) from stdin});
		}
		return 1;
	},
	parameter_status => sub {
		my $self = shift;
		my %args = @_;
		$status{$_} = $args{status}->{$_} for sort keys %{$args{status}};
		print "Parameter status: $_ => " . $args{status}->{$_} . "\n" for sort keys %{$args{status}};
		return 1;
	},
	row_description => sub {
		my $self = shift;
		print "Row description\n";
		my %args = @_;
		print '[' . join(' ', map { $_->{name} } @{$args{description}{field}}) . "]\n";
		return 1;
	},
	data_row => sub {
		my $self = shift;
		print "Data row\n";
		my %args = @_;
		print '[' . join(',', map { $_->{data} } @{$args{row}}) . "]\n";
		return 1;
	}
);
$loop->add($client);
$client->connect;
$loop->loop_forever;
exit 0;
