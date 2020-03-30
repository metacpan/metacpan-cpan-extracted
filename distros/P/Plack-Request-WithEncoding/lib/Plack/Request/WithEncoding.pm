package Plack::Request::WithEncoding;
use 5.008_001;
use strict;
use warnings;
use parent qw/Plack::Request/;
use Encode ();
use Carp ();
use Hash::MultiValue;

our $VERSION = "0.13";

use constant KEY_BASE_NAME    => 'plack.request.withencoding';
use constant DEFAULT_ENCODING => 'utf-8';

sub encoding {
    my $env = $_[0]->env;
    my $k = KEY_BASE_NAME . '.encoding';

    # In order to be able to specify the `undef` into $req->env->{plack.request.withencoding.encoding}
    exists $env->{$k} ? $env->{$k} : ($env->{$k} = DEFAULT_ENCODING);
}

sub body_parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.body'} ||= $self->_decode_parameters($self->SUPER::body_parameters);
}

sub query_parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.query'} ||= $self->_decode_parameters($self->SUPER::query_parameters);
}

sub parameters {
    my $self = shift;
    $self->env->{KEY_BASE_NAME . '.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new($query->flatten, $body->flatten);
    }
}

sub raw_body_parameters {
    shift->SUPER::body_parameters;
}

sub raw_query_parameters {
    shift->SUPER::query_parameters;
}

sub raw_parameters {
    my $self = shift;

    $self->env->{'plack.request.merged'} ||= do {
        my $query = $self->SUPER::query_parameters();
        my $body  = $self->SUPER::body_parameters();
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub raw_param {
    my $self = shift;

    my $raw_parameters = $self->raw_parameters;
    return keys %{ $raw_parameters } if @_ == 0;

    my $key = shift;
    return $raw_parameters->{$key} unless wantarray;
    return $raw_parameters->get_all($key);
}

sub _decode_parameters {
    my ($self, $stuff) = @_;
    return $stuff unless $self->encoding; # return raw value if encoding method is `undef`

    my $encoding = Encode::find_encoding($self->encoding);
    unless ($encoding) {
        my $invalid_encoding = $self->encoding;
        Carp::croak("Unknown encoding '$invalid_encoding'.");
    }

    my @flatten = $stuff->flatten;
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, $encoding->decode($k), $encoding->decode($v);
    }
    return Hash::MultiValue->new(@decoded);
}

1;
__END__

=encoding utf-8

=for stopwords CGI.pm-compatible $req->env->{'plack.request.withencoding.encoding'} utf-8 falsy

=head1 NAME

Plack::Request::WithEncoding - Subclass of L<Plack::Request> which supports encoded requests.

=head1 SYNOPSIS

    use Plack::Request::WithEncoding;

    my $app_or_middleware = sub {
        my $env = shift; # PSGI env

        # Example of $env
        #
        # $env = {
        #     QUERY_STRING   => 'query=%82%d9%82%b0', # <= encoded by 'cp932'
        #     REQUEST_METHOD => 'GET',
        #     HTTP_HOST      => 'example.com',
        #     PATH_INFO      => '/foo/bar',
        # };

        my $req = Plack::Request::WithEncoding->new($env);

        $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the encoding method.

        my $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'.

        my $res = $req->new_response(200); # new Plack::Response
        $res->finalize;
    };

=head1 DESCRIPTION

Plack::Request::WithEncoding is a subclass of L<Plack::Request> that supports encoded requests. It overrides many Plack::Request attributes to return decoded values.
This feature allows a single application to seamlessly handle a wide variety of different language code sets. Applications that must be able to handle many different translations at once will find this extension able to quickly solve that problem.

The target attributes to be encoded are described at L</"SPECIFICATION OF THE ENCODING METHOD">.

=head1 ATTRIBUTES of C<Plack::Request::WithEncoding>

=over 4

=item * encoding

Returns an encoding method to decode parameters.

=item * query_parameters

Returns a reference of L<Hash::MultiValue> instance that contains B<decoded> query parameters.

=item * body_parameters

Returns a reference of L<Hash::MultiValue> instance that contains B<decoded> request body.

=item * parameters

Returns a reference of L<Hash::MultiValue> instance that contains B<decoded> parameters. The parameters are merged with C<query_parameters> and C<body_parameters>.

=item * param

Returns B<decoded> parameters with a CGI.pm-compatible param method. This is an alternative method for accessing parameters in
C<$req-E<gt>parameters>.
Unlike CGI.pm, it does B<not> allow setting or modifying query parameters.

    $value  = $req->param('foo');
    @values = $req->param('foo');
    @params = $req->param;

=item * raw_query_parameters

This attribute is the same as C<query_parameters> of L<Plack::Request>.

=item * raw_body_parameters

This attribute is the same as C<body_parameters> of L<Plack::Request>.

=item * raw_parameters

This attribute is the same as C<parameters> of L<Plack::Request>.

=item * raw_param

This attribute is the same as C<param> of L<Plack::Request>.

=back

=head1 SPECIFICATION OF THE ENCODING METHOD

You can specify the character-encoding to decode, like so;

    $req->env->{'plack.request.withencoding.encoding'} = 'utf-7'; # <= set utf-7

When this character-encoding wasn't given through C<$req-E<gt>env-E<gt>{'plack.request.withencoding.encoding'}>, this module uses "utf-8" as the default character-encoding to decode.
It would be better to specify this character-encoding explicitly because the readability and understandability of the code behavior would be improved.

Once this value was specified by falsy value (e.g. `undef`, 0 and ''), this module returns B<raw value> (i.e. never decodes).

The example of a code is shown below.

    print exists $req->env->{'plack.request.withencoding.encoding'} ? 'EXISTS'
                                                                    : 'NOT EXISTS'; # <= NOT EXISTS
    $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'utf-8' (*** YOU SHOULD NOT USE LIKE THIS ***)

    $req->env->{'plack.request.withencoding.encoding'} = undef; # <= explicitly specify the `undef`
    $query = $req->param('query'); # <= get parameters of 'query' that is not decoded (raw value)

    $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the 'cp932' as encoding method
    $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'

=head1 SEE ALSO

L<Plack::Request>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

