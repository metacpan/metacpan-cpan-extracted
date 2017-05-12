package Plack::App::Gearman::Status;
{
  $Plack::App::Gearman::Status::VERSION = '0.001001';
}
use parent qw(Plack::Component);

# ABSTRACT: Plack application to display the status of Gearman job servers

use strict;
use warnings;

use Carp;
use MRO::Compat;
use Net::Telnet::Gearman;
use Text::MicroTemplate;
use Try::Tiny;
use Plack::Util::Accessor qw(job_servers template connections);


chomp(my $template_string = <<'EOTPL');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Gearman Server Status</title>
		<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
		<style type="text/css">
			html, body {
				padding: 0px;
				margin: 5px;
				background-color: #FFFFFF;
				font-family: Helvetica, Sans-Serif;
			}
			h1, h2, h3 {
				border: solid #EAEAEA 1px;
				padding: 5px;
				margin-top: inherit;
				margin-bottom: inherit;
				background-color: #FAFAFA;
				color: #777777;
			}
			h1 {
				border-radius: 10px;
				-moz-border-radius: 10px;
			}
			h2 {
				font-size: 1.25em;
				margin-top: 40px;
				border-radius: 10px 10px 0px 0px;
				-moz-border-radius: 10px 10px 0px 0px;
			}
			h3 {
				font-size: 1em;
			}
			p {
				margin: 0px;
				color: #444444;
				font-size: 0.9em;
			}
			p.error {
				text-align: center;
				border: 1px solid #FFAAAA;
			}
			table {
				width: 100%;
				border: 1px solid #DDDDDD;
				border-spacing: 0px;
			}
			table.status {
				border-radius: 0px 0px 10px 10px;
				-moz-border-radius: 0px 0px 10px 10px;
			}
			table th {
				border-bottom: 1px solid #DDDDDD;
				background: #FAFAFA;
				padding: 5px;
				font-size: 0.9em;
				color: #555555;
			}
			table td {
				text-align: center;
				padding: 5px;
				font-size: 0.8em;
				color: #444444;
			}
			table tr:hover {
				background: #FBFBFB;
			}
		</style>
	</head>
	<body>
		<h1>Gearman Server Status</h1>
		<% for my $job_server_status (@{$_[0]}) { %>
			<h2>Job server <code><%= $job_server_status->{job_server} %></code></h2>
			<% if ($job_server_status->{error}) { %>
				<p class="error"><%= $job_server_status->{error} %></p>
			<% } else { %>
				<p>Server Version: <%= $job_server_status->{version} %></p>

				<h3>Workers</h3>
				<table class="workers">
					<tr>
						<th>File Descriptor</th>
						<th>IP Address</th>
						<th>Client ID</th>
						<th>Functions</th>
					</tr>
					<% for my $worker (@{$job_server_status->{workers}}) { %>
						<tr>
							<td><%= $worker->file_descriptor() %></td>
							<td><%= $worker->ip_address() %></td>
							<td><%= $worker->client_id() %></td>
							<td><%= join(', ', sort @{$worker->functions()}) %></td>
						</tr>
					<% } %>
				</table>

				<h3>Status</h3>
				<table class="status">
					<tr>
						<th>Function</th>
						<th>Total</th>
						<th>Running</th>
						<th>Available Workers</th>
						<th>Queue</th>
					</tr>
					<% for my $status (@{$job_server_status->{status}}) { %>
						<tr>
							<td><%= $status->name() %></td>
							<td><%= $status->running() %></td>
							<td><%= $status->busy() %></td>
							<td><%= $status->free() %></td>
							<td><%= $status->queue() %></td>
						</tr>
					<% } %>
				</table>
			<% } %>
		<% } %>
	</body>
</html>
EOTPL



sub new {
	my ($class, @arg) = @_;

	my $self = $class->next::method(@arg);

	unless (ref $self->job_servers() eq 'ARRAY') {
		$self->job_servers(['127.0.0.1:4730']);
	}

	$self->connections({});

	$self->template(Text::MicroTemplate->new(
		template   => $template_string,
		tag_start  => '<%',
		tag_end    => '%>',
		line_start => '%',
	)->build());

	return $self;
}



sub parse_job_server_address {
	my ($self, $address) = @_;

	unless (defined $address) {
		croak("Required job server address parameter not passed");
	}

	$address =~ m{^
		# IPv6 address or hostname/IPv4 address
		(?:\[([\d:]+)\]|([\w.-]+))
		# Optional port
		(?::(\d+))?
	$}xms or croak("Unable to parse address '$address'");
	my $host = $1 || $2;
	my $port = $3 || 4730;

	return ($host, $port);
}



sub connection {
	my ($self, $address) = @_;

	my ($host, $port) = $self->parse_job_server_address($address);
	my $connection;
	try {
		$connection = Net::Telnet::Gearman->new(
			Host => $host,
			Port => $port,
		);
	}
	catch {
		carp $_;
	};
	return $connection;
}



sub get_status {
	my ($self) = @_;

	my @result;
	for my $job_server (@{$self->job_servers()}) {
		unless (defined $self->connections()->{$job_server}) {
			$self->connections()->{$job_server} = $self->connection($job_server);
		}
		try {
			push @result, {
				job_server => $job_server,
				workers    => [ $self->connections()->{$job_server}->workers() ],
				status     => [ $self->connections()->{$job_server}->status() ],
				version    => $self->connections()->{$job_server}->version(),
			};
		}
		catch {
			delete $self->connections()->{$job_server};
			push @result, {
				job_server => $job_server,
				error      => 'Failed to fetch status information from '.$job_server,
			}
		};
	}

	return \@result;
}



sub call {
	my ($self, $env) = @_;

	return [
		200,
		[ 'Content-Type' => 'text/html; charset=utf-8' ],
		[ $self->template()->($self->get_status()) ]
	];
}



1;


__END__
=pod

=head1 NAME

Plack::App::Gearman::Status - Plack application to display the status of Gearman job servers

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

In a C<.psgi> file:

	use Plack::App::Gearman::Status;

	my $app = Plack::App::Gearman::Status->new({
		job_servers => ['127.0.0.1:4730'],
	});

As one-liner on the command line:

	plackup -MPlack::App::Gearman::Status \
		-e 'Plack::App::Gearman::Status->new({ job_servers => ["127.0.0.1:4730"] })->to_app'

=head1 DESCRIPTION

Plack::App::Gearman::Status displays the status of the configured Gearman job
servers by fetching it using L<Net::Telnet::Gearman|Net::Telnet::Gearman> and
turning it into a simple HTML page. This page contains information about the
available workers and the status of the registered functions.

=head2 new

Constructor, creates new L<Plack::App::Gearman::Status|Plack::App::Gearman::Status>
instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item job_servers

Array reference with the addresses of the job servers the application should
connect to.

=back

=head2 parse_job_server_address

Parses a job server address of the form C<hostname:port> with optional C<port>.
If no port is given, it defaults to C<4730>.

=head3 Parameters

This method expects positional parameters.

=over

=item address

The address to parse.

=back

=head3 Result

A list with host and port.

=head2 connection

Connects to the given job server and returns the
L<Net::Telnet::Gearman|Net::Telnet::Gearman> object.

=head3 Parameters

This method expects positional parameters.

=over

=item address

Address of the job server to connect to.

=back

=head3 Result

The L<Net::Telnet::Gearman|Net::Telnet::Gearman> instance on success, C<undef>
otherwise.

=head2 get_status

Fetch status information from configured Gearman job servers.

=head3 Result

An array reference with hash references containing status information.

=head2 call

Specialized call method which retrieves the job server status information and
transforms it to HTML.

=head3 Result

A L<PSGI|PSGI> response.

=head1 SEE ALSO

=over

=item *

L<Plack|Plack> and L<Plack::Component|Plack::Component>.

=item *

L<Net::Telnet::Gearman|Net::Telnet::Gearman> which is used to access a Gearman
job server.

=item *

C<gearman-stat.psgi> (L<https://github.com/tokuhirom/gearman-stat.psgi>) by
TOKUHIROM which inspired this application.

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

