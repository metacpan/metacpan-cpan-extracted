package Puncheur::Request;
use strict;
use warnings;

use parent 'Plack::Request::WithEncoding';
use Carp ();
use URI::QueryParam;

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->SUPER::uri;
    $self->{uri}->clone; # avoid destructive opearation
}

sub base {
    my $self = shift;

    $self->{base} ||= $self->SUPER::base;
    $self->{base}->clone; # avoid destructive operation
}

# for backward compatible
sub body_parameters_raw {
    shift->raw_body_parameters(@_);
}

sub query_parameters_raw {
    shift->raw_query_parameters(@_);
}

sub parameters_raw {
    shift->raw_parameters(@_);
}

sub param_raw {
    shift->raw_param(@_);
}

sub uri_with {
    my( $self, $query, $behavior) = @_;
    Carp::carp( 'No arguments passed to uri_with()' ) unless $query;

    my $append = ref $behavior eq 'HASH' && $behavior->{mode} && $behavior->{mode} eq 'append';
    my @query = ref $query eq 'HASH' ? %$query : @$query;
    @query = map { $_ && encodde_utf8($_) } @query;

    my $params = do {
        my %params = %{ $self->uri->query_form_hash };

        while (my ($key, $val) = splice @query, 0, 2) {
            if ( defined $val ) {
                if ( $append && exists $params{$key} ) {
                    $params{$key} = [
                        (ref $params{$key} eq 'ARRAY' ? @{ $params{$key} } : $params{$key}),
                        (ref $val eq 'ARRAY'          ? @$val              : $val),
                    ];
                }
                else {
                    $params{$key} = $val;
                }
            }
            else {
                # If the param wasn't defined then we delete it.
                delete( $params{$key} );
            }
        }
        \%params;
    };

    my $uri = $self->uri;
    $uri->query_form($params);

    return $uri;
}

sub capture_params {
    my ($self, @params) = @_;
    (map {($_ => $self->parameters->get($_))} @params);
}

1;
