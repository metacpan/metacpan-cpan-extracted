package Net::Amazon::Utils;

use v5.10.0;
use strict;
use warnings FATAL => 'all';
use Carp;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Message;
use XML::Simple;

=head1 NAME

Net::Amazon::Utils - Implementation of a set of utilities to help in developing Amazon web service modules in Perl.

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

This module implements a set of helpers that should be of aid to
programming client to Amazon RESTful webservices.

Loosely based in com.amazonaws.regions.Region at L<http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/regions/Region.html>

	use Net::Amazon::Utils;

	my $utils = Net::Amazon::Utils->new();

	# get a list of all regions
	my @all_regions = $utils->get_regions();

	# get a list of all services abbreviations
	my @all_services = $utils->get_services();

	# get all endpoints for ec2
	my @service_endpoints = $utils->get_service_endpoints( 'ec2' );

	my $endpoint_uri;

	# check that ec2 exists in region us-west-1
	if ( $utils->is_service_supported( 'ec2', 'us-west-1' ) ) {
		# check that http is supported by the end point
		if ( $utils->get_http_support( 'ec2', 'us-west-1' ) ) {
			# get the first http endpoint for ec2 in region us-west-1
			$endpoint_uri =($utils->get_endpoint_uris( 'Http', 'ec2', 'us-west-1' ))[0];
			#... use LWP to POST, send get comments
			#... use Net::Amazon::EC2
		}
	}

	# get endpoints for ec2 with http support on two given regions
	my @some_endpoints = $utils->get_http_support( 'ec2', 'us-west-1', 'us-east-1' );

	# check ec2 is supported on all us regions
	my @us_regions = grep( /^us/, $utils->get_regions );
	my @us_endpoints;
	if ( $utils->is_service_supported( 'ec2', @us_regions ) ) {
		# get endpoints for ec2 with http support on all us regions
		@us_endpoints = $utils->get_http_support( 'ec2', @us_regions );
		# choose a random one and give you images a spin
		# ...
	}

=head1 SUBROUTINES/METHODS

=head2 new( [ $no_cache = 0 ], [ $no_inet = 1 ] )

Spawns a blessed Net::Amazon::Utils minion.

$no_cache means regions will be reloaded with each call to a function and will likely be deprecated.
$no_inet means regions should never be fetched from the Internet unless forced by fetch_region_update.

=cut

sub new {
	my ( $class, $no_cache, $no_inet ) = @_;

	$no_inet = 1 unless defined $no_inet;
	$no_cache = 0 unless defined $no_cache;

	my $self = {
		remote_region_file => 'https://raw.githubusercontent.com/aws/aws-sdk-android-v2/master/src/com/amazonaws/regions/regions.xml',
		# do not cache regions between calls, does not affect Internet caching, defaults to false.
		no_cache => $no_cache,
		# do not load updated file from the Internet, defaults to true.
		no_inet => $no_inet,
		# be well behaved and tell who we are.
		# use more reasonable 21st century Internet timeout
		# do not accept redirects
		ua     => LWP::UserAgent->new(
			agent		=> __PACKAGE__ . '/' . $VERSION,
			timeout => 30,
			max_redirect => 0,
		),
	};

	bless $self, $class;

	return $self;
}

=head2 fetch_region_update

Fetch regions file from the internet even if no_inet was specified when
intanciating the object.

=cut

sub fetch_region_update {
	my ( $self ) = @_;

	if ( $self->{no_cache} ) {
		# Cached regions will not be fetched
		carp 'Fetching updated region update is useless unless no_cache is false. Still I will comply to your orders because you are intelligent.';
		$self->_load_regions( 1 );
	} else {
		# Backup and restore Internet connection selection.
		my $old_no_inet = $self->{no_inet};
		# Force loading
		$self->_load_regions( 1 );
		$self->{no_inet} = $old_no_inet;
	}
}

=head2 get_domain

Currently returns 'amazonaws.com' which is the only supported domain.

=cut

sub get_domain {
	return 'amazonaws.com';
}

=head2 get_regions

Returns a list of regions abbreviations, i.g., us-west-1, us-east-1, eu-west-1, sa-east-1.

=cut

sub get_regions {
	my ( $self ) = @_;
	my @regions;

	$self->_load_regions();

	return keys %{$self->{regions}->{Regions}};

	$self->_unload_regions();
}

=head2 get_services

Returns a list of services abbreviations, i.g., ec2, sqs, glacier.

=cut

sub get_services {
	my ( $self ) = @_;

	$self->_load_regions();

	return keys %{$self->{regions}->{Services}};

	$self->_unload_regions();
}

=head2 get_service_endpoints

Returns a list of the available services endpoints.

=cut

sub get_service_endpoints {
	my ( $self, $service ) = @_;

	croak 'A service must be specified' unless defined $service;

	$self->_load_regions();

	my @service_endpoints;

	unless ( defined $self->{regions}->{ServiceEndpoints} ) {
		foreach my $region ( keys %{$self->{regions}->{Regions}} ) {
			push @service_endpoints, $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{Hostname}
				if (
					defined $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}
				);
		}
		$self->{regions}->{ServiceEndpoints} = \@service_endpoints;
	}

	return @{$self->{regions}->{ServiceEndpoints}};

	$self->_unload_regions();
}

=head2 get_http_support( $service, [ @regions ] )

Returns a list of the available http services endpoints for a service abbreviation
as returned by get_services.
A region or list of regions can be specified to narrow down the results.

=cut

sub get_http_support {
	my ( $self, $service, @regions ) = @_;

	return $self->get_protocol_support( 'Http', $service, @regions );
}

=head2 get_https_support( $service, [ @regions ] )

@regions is an optional list of regions to narrow down the results.

Returns a list of the available https services endpoints for a service abbreviation
as returned by get_services.

=cut

sub get_https_support {
	my ( $self, $service, @regions ) = @_;

	return $self->get_protocol_support( 'Https', $service, @regions );
}

=head2 get_protocol_support( $protocol, $service, [ @regions ] )

@regions is an optional list of regions to narrow down the results.

Returns a list of the available services endpoints for a service abbreviation as
returned by get_services for a given protocol. Protocols should be cased accordingly.

=cut

sub get_protocol_support {
	my ( $self, $protocol, $service, @regions ) = @_;

	croak 'A protocol must be specified' unless defined $protocol;
	croak 'A service must be specified' unless defined $service;

	$self->_load_regions();

	@regions = keys %{$self->{regions}->{Regions}} unless ( @regions );

	my $regions_key = join('||', sort @regions);

	my @protocol_support;

	unless ( defined $self->{regions}->{$protocol . 'Support'}->{$service}->{$regions_key} ) {
		foreach my $region ( @regions ) {
			push @protocol_support, $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{Hostname}
				if (
					defined $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service} &&
					$self->_is_true(
						$self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{$protocol}
					)
				);
		}
		$self->{regions}->{$protocol . 'Support'}->{$service}->{$regions_key} = \@protocol_support;
	}

	return @{$self->{regions}->{$protocol . 'Support'}->{$service}->{$regions_key}};

	$self->_unload_regions();

}

=head2 get_service_endpoint( $protocol, $service, @regions )

$protocol is a protocol as returned by get_known_protocols.
$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns the list of endpoints for the specified protocol and service on a list of regions.

=cut

sub get_service_endpoint {
	my ( $self, $protocol, $service, @regions ) = @_;

	croak 'A protocol must be specified' unless defined $protocol;
	croak 'A service must be specified' unless defined $service;
	croak 'At least one region must be specified' unless @regions;

	$self->_load_regions();

	my @endpoints;

	foreach my $region ( @regions ) {
		push @endpoints, $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{Hostname}
			if (
				$self->_is_true(
					$self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{$protocol}
				)
			);
	}

	$self->_unload_regions();

	return @endpoints;
}

=head2 is_service_supported( $service, @regions )

$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns true if the service is supported in all listed regions.

=cut

sub is_service_supported {
	my ( $self, $service, @regions ) = @_;
	my $support = 1;

	croak 'A service must be specified' unless defined $service;
	croak 'At least one region must be specified' unless @regions;

	$self->_load_regions();

	foreach my $region ( @regions ) {
		my $supported_in_this_region = 0;
		foreach my $protocol ( $self->get_known_protocols() ) {
			$supported_in_this_region ||= $self->_is_true( $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{$protocol} );
			last if $supported_in_this_region;
		}
		$support &&= $supported_in_this_region;
		last unless $support;
	}

	$self->_unload_regions();

	return $support;
}

=head2 has_http_endpoint( $service, @regions )

$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns true if an http endpoint exists for the service on the region or list or regions

=cut

sub has_http_endpoint {
	my ( $self, $service, @regions ) = @_;

	$self->_load_regions();

	return $self->has_protocol_endpoint( 'Http', $service, @regions );

	$self->_unload_regions();
}

=head2 has_https_endpoint( $service, @regions )

$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns true if an https endpoint exists for the service on the region or list or regions

=cut

sub has_https_endpoint {
	my ( $self, $service, @regions ) = @_;

	$self->_load_regions();

	return $self->has_protocol_endpoint( 'Https', $service, @regions );

	$self->_unload_regions();
}

=head2 has_protocol_endpoint( $protocol, $service, @regions )

$protocol is a protocol as returned by get_known_protocols.
$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns true if an endpoint of the specified protocol exists for the service on the region or list or regions

=cut

sub has_protocol_endpoint {
	my ( $self, $protocol, $service, @regions ) = @_;

	croak 'A protocol must be specified.' unless $protocol;
	croak 'A service must be specified' unless defined $service;
	croak 'At least one region must be specified' unless @regions;

	$self->_load_regions();

	my $has_protocol = 1;

	foreach my $region ( @regions ) {
		$has_protocol &&= $self->_is_true( $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{$protocol} );
		last unless $has_protocol;
	}

	$self->_unload_regions();

	return $has_protocol;
}

=head2 get_known_protocols

Returns a list of known endpoint protocols, e.g. Http, Https (note casing).

=cut

sub get_known_protocols {
	my ( $self ) = @_;

	return @{$self->{regions}->{Protocols}};
}

=head2 set_known_protocols ( @protocols )

Sets the list of known protocols. Should not be used unless Net::Amazon::Utils::Regions is really
outdated or you are blatantly galant and brave, probably reckless.
Remember to properly case protocols and rerun test including your set protocols.

Returns the newly set protocols.

=cut

sub set_known_protocols {
	my ( $self, @protocols) = @_;

	croak 'Protocols must be specified.' unless @protocols;

	$self->{regions}->{Protocols} = \@protocols;

	return @protocols;
}

=head2 reset_known_protocols

Sets the list of known protocols to Net::Amazon::Utils::Regions defaults.
Should fix bad set_known_protocols.

=cut

sub reset_known_protocols {
	my ( $self) = @_;

	$self->set_known_protocols( 'Http', 'Https' );
}

=head2 get_endpoint_uris( $protocol, $service, @regions )

$protocol is a protocol as returned by get_known_protocols.
$service is a service abbreviation as returned by get_services.
@regions is a list of regions as returned by get_regions.

Returns a list of protocol://service.region.domain URIs usable for RESTful fidling.

=cut

sub get_endpoint_uris {
	my ( $self, $protocol, $service, @regions ) = @_;

	croak 'A protocol must be specified.' unless $protocol;
	croak 'A service must be specified' unless defined $service;
	croak 'At least one region must be specified' unless @regions;

	$self->_load_regions();

	my @endpoint_uris;
	my $domain = $self->get_domain();

	foreach my $region ( @regions ) {
		if ( defined $self->_is_true( $self->{regions}->{Regions}->{$region}->{Endpoint}->{$service}->{$protocol} ) ) {
			push @endpoint_uris, "\L$protocol\E://$service.$region.$domain";
		} else {
			croak "An endpoint does not exist for $service in $region with protocol $protocol.";
		}
	}

	return @endpoint_uris;

	$self->_unload_regions();
}

=head1 Internal Functions

=head2 _load_regions( [$force] )

Loads regions from local cached file or the Internet performing reasonable formatting.

$force, does what it should when set.

If Internet fails local cached file is used.
If loading of new region definitions fail, old regions remain unaffected.

=cut

sub _load_regions {
	my ( $self, $force ) = @_;

	if ( $force || !defined $self->{regions} ) {
		my $error;

		my $new_regions;
		if ( $self->{no_inet} ) {
			eval {
				require Net::Amazon::Utils::Regions;
				$new_regions = Net::Amazon::Utils::Regions::get_regions_data();
			};
			if ( $@ ) {
				carp "Processing XML failed with error $@";
				$error = 1;
			}
		} else {
			my $response = $self->{ua}->get( $self->{remote_region_file},
																				'Accept-Encoding' => scalar HTTP::Message::decodable,
																				'If-None-Match' => $self->{region_etag} );
			if ( $response->is_success ) {
				# Store etag for later tests
				$self->{region_etag} = $response->header( 'Etag' );
				# This should be a big file...
				my $content = $response->decoded_content;
				carp "Size of region file looks suspiciously small." if ( length $content < 10000 );
				eval {
					my @xml_options = ( KeyAttr => { Region => 'Name', Endpoint=>'ServiceName', Service => 'Name' } );
					$new_regions = XML::Simple::XMLin( $content, @xml_options );

					# Check that some "trustable" regions and services exist.
					unless ( defined $new_regions &&
						defined $new_regions->{Regions} &&
						defined $new_regions->{Regions}->{Region}->{'us-east-1'} &&
						defined $new_regions->{Regions}->{Region}->{'us-west-1'} &&
						defined $new_regions->{Regions}->{Region}->{'us-west-2'} &&
						defined $new_regions->{Services} &&
						defined $new_regions->{Services}->{Service}->{ec2} &&
						defined $new_regions->{Services}->{Service}->{sqs} &&
						defined $new_regions->{Services}->{Service}->{glacier}
					) {
						croak "Region file format cannot be trusted.";
					}
				};
				if ( $@ ) {
					carp "Processing XML failed with error $@";
					$error = 1;
				}
			} else {
				unless ( $response->code() eq '304' ) {
					carp "Getting updated regions failed with " . $response->status_line;
					$error = 1;
				}
			}
		}
		# Retry locally on errors
		if ( $error ) {
			my $old_no_inet = $self->{no_inet};
			carp "Getting regions file from Internet failed will use local cache. Check your Internet connection...";
			$self->{no_inet} = 1;
			$self->_load_regions();
			$self->{no_inet} = $old_no_inet
		}
		$new_regions->{Regions} = $new_regions->{Regions}->{Region};
		$new_regions->{Services} = $new_regions->{Services}->{Service};

		$self->{regions} = $new_regions if ( defined $new_regions );
		# Create a set of correct protocols for this set
		$self->reset_known_protocols();
	}
}

=head2 _unload_regions

Unloads regions recovering memory unless object has been instantiated with
cache_regions set to any true value.

=cut

sub _unload_regions {
	my ( $self ) = @_;

	$self->_force_unload_regions unless $self->{cache_regions};
}

=head2 _force_unload_regions

Unloads regions recovering memory.

=cut

sub _force_unload_regions {
	my ( $self ) = @_;

	$self->{regions} = undef;
}

=head2 _get_remote_regions_file_uri

Returns the uri of the remote regions.xml file.

=cut

sub _get_remote_regions_file_uri {
	my ( $self ) = @_;

	return $self->{remote_region_file};
}

=head2 get_regions_file_raw

Returns the full structure (plus possibly cached queries) of the interpreted regions.xml file.

=cut

sub _get_regions_file_raw {
	my ( $self ) = @_;

	$self->_load_regions();

	return $self->{regions};

	$self->_unload_regions();
}

=head2 _is_true

Converts a supposed truth into a true Perl true value if the value should be true perlishly speaking.

Returns a true value on strings that should be true in regions.xml parlance.

=cut

sub _is_true {
	my ( $self, $supposed_truth ) = @_;

	return $supposed_truth eq 'true';
}

=head1 AUTHOR

Gonzalo Barco, C<< <gbarco uy at gmail com, no spaces> >>

=head1 TODO

=over 4

=item * Online tests that endpoints are actually there.

=item * Better return values when scalar is expected.

=item * Probably helpers for assembling and signing requests to actual endpoints.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-amazon-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Amazon-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Amazon::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Amazon-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Amazon-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Amazon-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Amazon-Utils/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Gonzalo Barco.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Net::Amazon::Utils
