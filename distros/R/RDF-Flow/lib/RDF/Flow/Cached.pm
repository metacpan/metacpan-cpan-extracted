use strict;
use warnings;
package RDF::Flow::Cached;
{
  $RDF::Flow::Cached::VERSION = '0.178';
}
#ABSTRACT: Caches a source

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

use parent 'RDF::Flow::Source';
use RDF::Flow::Source qw(:util);
use Scalar::Util qw(blessed);
use Carp;

sub new {
    my $class  = shift;
    my $source = shift;
    my $cache  = shift;
    my (%args) = @_;

    croak "missing source" unless $source;

    $source = RDF::Flow::Source->new( $source )
        unless blessed $source and $source->isa('RDF::Flow::Source');

    my $self = bless {
        name   => "cached " . $source->name,
        source => $source,
        cache  => $cache,
    }, $class;

    $self->match( $args{match} );
    $self->guard( $args{guard} );

    $self;
}

sub retrieve_rdf {
    my $self = shift;
    my $env  = shift;

    my $key = $env->{'rdflow.uri'};
	my $rdf;

	# guarded, but no guard there (never was or expired)
	if ( $self->guard && !$self->guard->get( $key ) ) {

		$rdf = $self->{source}->retrieve( $env );
		if ( empty_rdf($rdf) ) {
			# better get from cache
			$rdf = $self->_get_cache($env);
		} else {
			# update
			$rdf = $self->_set_cache( $rdf, $env );
		}
		$self->guard->set( $key, 1 );

	} else {

		# get from cache
		$rdf = $self->_get_cache( $env );
		unless ( $rdf ) {
			# get from source and store in cache
			$rdf = $self->{source}->retrieve( $env );
			$rdf = $self->_set_cache( $rdf, $env );
		}
	}

	return $rdf
}

sub _set_cache {
	my ($self, $rdf, $env) = @_;
	my $key = $env->{'rdflow.uri'};

    log_trace { 'store in cache' };

	my $vars = {
		map { $_ => $env->{$_} }
		grep { $_ =~ /^rdflow\./ } keys %$env
	};

    my $object = [$rdf,$vars];
    if (blessed($rdf) and $rdf->isa('RDF::Trine::Model')) {
        $object->[0] = $rdf->as_hashref;
    } elsif (blessed($rdf) and $rdf->isa('RDF::Trine::Iterator')) {
        my @stms;

        # FIXME: RDF::Trine::Iterator should also have as_hashref
        # so we can avoid one serialization
        my $model = RDF::Trine::Model->new;
        $model->begin_bulk_ops;
        while (my $s = $rdf->next) {
            $model->add_statement( $s );
            push @stms, $s;
        }
        $model->end_bulk_ops;
        $object->[0] = $model->as_hashref;

        $rdf = RDF::Trine::Iterator::Graph->new( \@stms );
    } else {
        $object->[0] = { };
    }

    $self->{cache}->set( $key, $object );

    return $rdf;
}

sub _get_cache {
	my ($self, $env) = @_;

    my $obj = $self->{cache}->get( $env->{'rdflow.uri'} ) || return;

    log_trace { 'got from cache' };
    my ($rdf, $vars) = @{$obj};
    while ( my ($key, $value) = each %$vars ) {
        $env->{$key} = $value;
    }
    $env->{'rdflow.cached'} = 1;
    my $model = RDF::Trine::Model->new;
    $model->add_hashref($rdf);
    return $model;
}

sub inputs {
    return (shift->{source});
}

sub guard {
	return $_[0]->{'guard'} if scalar( @_ ) == 1;
    return $_[0]->{'guard'} = $_[1];
};

1;


__END__
=pod

=head1 NAME

RDF::Flow::Cached - Caches a source

=head1 VERSION

version 0.178

=head1 SYNOPSIS

  use CHI;                          # create a cache, for instance with CHI
  my $cache = CHI->new( ... );

  use RDF::Flow::Cached;        # plug cache in front of an existing source
  my $cached_source = RDF::Flow::Cached->new( $source, $cache );

  my $cached_source = $source->cached( $cache );       # alternative syntax

  use RDF::Flow qw(cached);
  my $cached_source = cached( $source, $cache );       # alternative syntax

  # guarded cache
  my $cached = cached( $source, $cache, guard => $quick_cache );

=head1 DESCRIPTION

Plugs a cache in front of a L<RDF::Flow::Source>. Actually, this module does
not implement a cache. Instead you must provide an object that provides at
least two methods to get and set an object based on a key. See L<CHI>,
L<Cache>, and L<Cache::Cache> for existing cache modules.

The request URI in C<rdflow.uri> is used as caching key. C<rdflow.cached> is
set if the response has been retrieved from the cache.  C<rdflow.timestamp>
reflects the timestamp of the original source, so you get the timestamp of the
cached response when it was first retrieved and stored in the cache.

=head1 METHODS

=head2 guard

You can get and/or set a guarding cache with this accessor.

=head1 CONFIGURATION

You can also use a cached source to guard against unreliable sources, which
sometimes just return nothing, for instance because of a failure.  To do so,
use a quickly expiring second cache as "guard". This guard is not used to
actually store data, but only to save the information that some data (at least
one triple) has been retrieved from the source. The source is not queried
again, until the guard expires. If, afterwards, the source returns no data,
data is returned from the cache instead. A possible setting is to use a
non-expiring cache as backend, guared by a another cache;

  use CHI;
  my $store = CHI->new( driver => 'File', root_dir => '/path/to/root' );
  my $guard = CHI->new( driver => 'Memory', global => 1 );

  my $cached = cached( $source, $store, guard => $guard );

However be sure not to use the same cache (C<root_dir>, C<global>...) for
caching different sources.

=head1 SEE ALSO

L<Plack::Middleware::Cached> implements almost the same mechanism for caching
general PSGI applications.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

