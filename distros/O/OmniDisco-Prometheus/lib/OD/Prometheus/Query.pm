use strict;
use warnings;

package OD::Prometheus::Query;
$OD::Prometheus::Query::VERSION = '0.006';
use v5.24;
use Moose;
use LWP::UserAgent;
use Data::Printer;
use OD::Prometheus::Metric;
use OD::Prometheus::Set;
use Scalar::Util qw(reftype);
use URI;
use JSON;

=head1 NAME

OD::Prometheus::Query - Query library to talk to Prometheus servers

=head1 VERSION

version 0.006

=cut


has host => (
	is		=> 'ro',
	isa		=> 'Str',
	required	=> 1,
);

has port => (
	is		=> 'ro',
	isa		=> 'Num',
	required	=> 0,
	default		=> 9090,
	
);

has prefix => (
	is		=> 'ro',
	isa		=> 'Str',
	required	=> 0,
	default		=> '/api/v1',
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
					HTTP::Headers->new();
				},
);

sub BUILD {
	my $self = shift // die 'incorrect call';
	$self->ua->default_headers( $self->headers )	
}

sub request {
	my $self	= shift // die 'incorrect call';
	my $type	= shift // die 'incorrect call';
	my $params	= shift // die 'incorrect call';
	
	$params = ( !defined(reftype($params)) )? [ query => $params, time => time ] : $params;
	die 'Expecting an arrayref as 2nd argument for GET parameters' unless reftype($params) eq 'ARRAY';

	my $url = URI->new;
	$url->scheme( $self->scheme );
	$url->host( $self->host );
	$url->port( $self->port );
	$url->path( $self->prefix.'/'.$type );
	$url->query_form( $params );

	HTTP::Request->new( GET => $url );	
}

sub get {
	my $self = shift // die 'incorrect call';
	my $res = $self->ua->request($self->request( @_ ));
	if ($res->is_success) {
		my $ret = OD::Prometheus::Set->new;
		my $j = decode_json $res->decoded_content;
		if( $j->{ status } eq 'success' ) {
			if( $j->{ warnings } ) {
				warn 'Query to '.$self->request( @_ ).' warns: '.$j->{ warnings }
			}
			if( $j->{ data }->{ resultType } eq 'vector' ) {
				for my $item ( $j->{ data }->{ result }->@* ) {
					my $metric = $item->{ metric };
					my $value = $item->{ value };
					$ret->push( OD::Prometheus::Metric->new(
						metric_name	=> $metric->{ __name__ },
						labels		=> { map { $_ => $metric->{$_} } grep { $_ ne '__name__' } keys $metric->%* },
						value		=> $value->[1],
						timestamp	=> $value->[0],
					));
				}
			}
			elsif( $j->{ data }->{ resultType } eq 'matrix' ) {
				for my $item ( $j->{ data }->{ result }->@* ) {
					my $metric = $item->{ metric };
					my $values = $item->{ values };
					$ret->push( OD::Prometheus::Metric->new(
						metric_name	=> $metric->{ __name__ },
						labels		=> { map { $_ => $metric->{$_} } grep { $_ ne '__name__' } keys $metric->%* },
						values		=> $values,
					));
				}
			}
			else {
				die 'cannot (yet) handle a resultType of '.$j->{ data }->{ resultType }
			}
		}
		else {
			die 'Query to '.$self->request( @_ ).' returned '.$j->{ status }.' with errorType:'.$j->{ errorType }.' and error:'.$j->{ error };
		}
		return $ret
	}
	else {
		die $res->status_line.' url was:'.$self->request( @_ )->as_string;
	}	
}

=head1 COPYRIGHT & LICENSE
 
Copyright 2018 Athanasios Douitsis, all rights reserved.
 
This program is free software; you can use it
under the terms of Artistic License 2.0 which can be found at 
http://www.perlfoundation.org/artistic_license_2_0
 
=cut

1;
