use 5.006; use strict; use warnings;

package Plack::App::Hostname;

our $VERSION = '1.002';

BEGIN { require Plack::Component; our @ISA = 'Plack::Component' }
use Plack::Util::Accessor qw( custom_matcher missing_header_app default_app );

sub map_hosts_to {
	my $self = shift;
	my $app = shift;
	@{ $self->{'_app_for_host'} }{ map { lc } @_ } = ( $app ) x @_;
	$self->{'_num_wildcards'} += grep { /\A\*\*\./ } @_;
	return $self;
}

sub unmap_host {
	my $self = shift;
	delete @{ $self->{'_app_for_host'} }{ map { lc } @_ };
	$self->{'_num_wildcards'} -= grep { /\A\*\*\./ } @_;
	return $self;
}

sub unmap_app {
	my $self = shift;
	my $map = $self->{'_app_for_host'} ||= {};
	while ( my ( $host, $host_app ) = each %$map ) {
		next if not grep { $host_app == $_ } @_;
		delete $map->{ $host };
		--$self->{'_num_wildcards'} if $host =~ /\A\*\*\./;
	}
	return $self;
}

sub matching {
	my $self = shift;
	my $host = lc $_[0];

	my $map = $self->{'_app_for_host'};

	return $_ for $map->{ $host } || ();

	if ( $self->{'_num_wildcards'} ) {
		my @part = split /\./, $host, 16;
		for my $pattern ( map { shift @part; join '.', '**', @part } 1 .. $#part ) {
			return $_ for $map->{ $pattern } || ();
		}
	}

	return undef unless my $cb = $self->custom_matcher;

	return scalar $cb->() for $host;
}

our $sadtrombone = [
	400,
	[qw( Content-Type text/html )],
	['<!DOCTYPE html><title>Bad Request</title><center style="font-family: sans-serif"><h1>Bad Request</h1><p>Unknown host or domain'],
];

sub call {
	my $self = shift;
	my ( $env ) = @_;

	my $host = $env->{'HTTP_HOST'};

	my $app = defined $host
		? ( $host =~ s/:$env->{'SERVER_PORT'}\z//, $self->matching( $host ) || $self->default_app )
		: $self->missing_header_app;

	return 'CODE' eq ref $app ? &$app : $app || $sadtrombone;
}

1;
