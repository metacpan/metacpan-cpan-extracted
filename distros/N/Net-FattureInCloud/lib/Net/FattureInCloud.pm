package Net::FattureInCloud {
    use Moo;
    use Mojo::UserAgent;
    use Carp qw/croak confess/;
    use List::Util qw/first/;
    use Mojo::Util qw/url_escape url_unescape/;
    use namespace::clean;
    use version;
    use v5.36;

    our $VERSION = qv("v0.2.3");

    has endpoint_uri => ( is => 'ro', default => sub { 'https://api-v2.fattureincloud.it/' } );
    has token => ( is => 'ro' );
    has company_id => ( is => 'ro' );
    has ua => ( is => 'ro', lazy => 1, default => sub { Mojo::UserAgent->new() } );

    sub BUILD {
        my ($self, $args) = @_;

        croak 'Please provide token' if !exists $args->{token};
        croak 'Please provide company_id' if !exists $args->{company_id};
    }

    sub request($self, $path, $method, $args = {}) {
        croak 'Please provide path' if !defined $path;
        croak 'Invalid path' if $path !~ m/\w+/xs;
        $method = $self->_validate_method($method);

        my $reqargs = {
            %$args,
        };

        my $datatransport = $method eq 'get' ? 'form' : 'json';

        my $res = $self->ua->$method( $self->endpoint_uri . "$path" =>
            { Authorization => 'Bearer ' . $self->token },
            $datatransport => $reqargs
        )->result;
        croak $res->message .': ' . $res->body if !$res->is_success;

        return $res->json;
    }

    sub crequest($self, $path, $method, $args = {}) {
        croak 'Please provide path' if !defined $path;
        croak 'Invalid path' if $path !~ m/\w+/xs;
        $method = $self->_validate_method($method);

        my $reqargs = {
            %$args,
        };

        my $datatransport = $method eq 'get' ? 'form' : 'json';

        my $res = $self->ua->$method( $self->endpoint_uri . 'c/' . $self->company_id . "/$path" =>
            { Authorization => 'Bearer ' . $self->token },
            $datatransport => $reqargs
        )->result;
        croak $res->message .': ' . $res->body if !$res->is_success;

        return $res->json;
    }

    sub _validate_method($self, $method) {
        confess 'Invalid-method' if !defined first { $_ eq uc($method) } qw/GET POST PUT DEL/;
        return lc $method;
    }
}

1;

=head1 NAME

Net::FattureInCloud - Perl library with MINIMAL interface to use FattureInCloud (FIC) API version 2.

=head1 SYNOPSIS

    use Net::FattureInCloud;

    # TODO

=head1 DESCRIPTION

This is HIGHLY EXPERIMENTAL and in the works, do not use for now.

=head1 AUTHOR

Michele Beltrame, C<mb@blendgroup.it>

=head1 LICENSE

This library is free software under the Artistic License 2.0.

=cut
