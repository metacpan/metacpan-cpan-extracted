use strict;
use warnings;

package OD::Prometheus::Client;
$OD::Prometheus::Client::VERSION = '0.003';
use v5.24;
use Moose;
use LWP::UserAgent;
use Data::Printer;
use OD::Prometheus::Metric;

=head1 NAME

OD::Prometheus::Client - Client library to talk to Prometheus nodes

=head1 VERSION

version 0.003

=cut



has host => (
	is		=> 'ro',
	isa		=> 'Str',
	required	=> 1,
);

has port => (
	is		=> 'ro',
	isa		=> 'Num',
	required	=> 1,
	
);

has path => (
	is		=> 'ro',
	isa		=> 'Str',
	required	=> 0,
	default		=> '/metrics',
);

has scheme => (
	is		=> 'ro',
	isa		=> 'Str',
	required	=> 0,
	default		=> 'http',
);

has ua => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	required	=> 0,
	default		=> sub { LWP::UserAgent->new },
);

has headers => (
	is		=> 'ro',
	isa		=> 'HTTP::Headers',
	required	=> 0,
	default		=> 	sub {
					HTTP::Headers->new(
						Accept		=> 'text/plain;version=0.0.4;q=0.3',
					);
				},
);

sub BUILD {
	my $self = shift // die 'incorrect call';
	$self->ua->default_headers( $self->headers )	
}

sub url {
	my $self = shift // die 'incorrect call';
	$self->scheme.'://'.$self->host.':'.$self->port.$self->path
}

sub request {
	my $self = shift // die 'incorrect call';
	HTTP::Request->new( GET => $self->url );	
}

sub get {
	my $self = shift // die 'incorrect call';
	my $res = $self->ua->request($self->request);
	if ($res->is_success) {
		my @ret = ();
		my @comments = ();
		for my $line ( split("\n",$res->decoded_content) ) {
			if( $line =~ /^#/ ){
				push @comments, $line
			}
			elsif( $line =~ /^\s*$/ ) { # prometheus exposition format says empty lines are ignored
				next
			}
			else {
				push @ret,OD::Prometheus::Metric->new( line => $line, comments => \@comments );
				@comments = ();
			}
		}
		return \@ret
	}
	else {
		die $res->status_line
	}	
}

=head1 COPYRIGHT & LICENSE
 
Copyright 2018 Athanasios Douitsis, all rights reserved.
 
This program is free software; you can use it
under the terms of Artistic License 2.0 which can be found at 
http://www.perlfoundation.org/artistic_license_2_0
 
=cut

1;
