package Net::Statsd::Lite::Dog;

use v5.10;

use Moo 1.000000;
extends 'Net::Statsd::Lite';

# See Metrics::Any::Adapter::DogStatsd

around record_metric => sub {
    my ( $next, $self, $suffix, $metric, $value, $opts ) = @_;

    if ( my $tags = $opts->{tags} ) {
        $suffix .= "|#" . join ",", map { s/|//g; $_ } @$tags;
    }

    $self->$next( $suffix, $metric, $value, $opts );
};

1;
