package Net::HTTP::Knork;

# ABSTRACT: Lightweight implementation of Spore specification
use Moo;
use Sub::Install;
use Try::Tiny;
use Carp;
use JSON::MaybeXS;
use Data::Rx;
use LWP::UserAgent;
use URI;
use File::ShareDir ':ALL';
use Subclass::Of;
use Net::HTTP::Knork::Request;
use Net::HTTP::Knork::Response;

with 'Net::HTTP::Knork::Role::Middleware';


has 'client' => ( is => 'lazy', );

# option that allows one to pass optional parameters that are not specified
# in the spore 'optional_params' or 'optional_payload' section for a given method.

has 'lax_optionals' => ( is => 'rw', default => sub {0} );

has 'base_url' => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return $_[0]->spec->{base_url};
    }
);

has 'request' => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        return Net::HTTP::Knork::Request->new( $_[0]->env );
    }
);

has 'env' => ( is => 'rw', );

has 'spec' => (
    is       => 'lazy',
    required => 1,
    coerce   => sub {
        my $json_spec = $_[0];
        my $spec;

        # it could be a file
        try {
            open my $fh, '<', $json_spec or croak 'Cannot read the spec file';
            local $/ = undef;
            binmode $fh;
            $spec = decode_json(<$fh>);
            close $fh;
        }
        catch {
            try {
                $spec = decode_json($json_spec);
            }

            # it is not json, so we are returning the string as is
            catch {
                $spec = $json_spec;
            };
        };
        return $spec;
    }
);

has 'default_params' => (
    is        => 'rw',
    default   => sub { {} },
    predicate => 1,
    clearer   => 1,
    writer    => 'set_default_params',
);

has 'spore_rx' => (
    is      => 'rw',
    default => sub {
        return dist_file(
            'Net-HTTP-Knork',
            'config/specs/spore_validation.rx'
        );
    }
);

has 'encoding' => ( 
    is => 'rw',
    default => sub { undef }, 
); 

has 'decoding' => ( 
    is => 'rw',
    default => sub { undef },
);


# Change the namespace of a given instance, so that there won't be any
# method collision between two instances

sub BUILD {
    my $self     = shift;
    my $subclass = subclass_of('Net::HTTP::Knork');
    bless( $self, $subclass );
    $self->build_from_spec();
}

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new();
}

sub validate_spore {
    my ( $self, $spec ) = @_;
    my $rx = Data::Rx->new;
    my $spore_schema;
    if ( -f $self->spore_rx ) {
        open my $fh, "<", $self->spore_rx;
        binmode $fh;
        local $/ = undef;
        $spore_schema = <$fh>;
        close $fh;
    }
    else {
        croak "Spore schema " . $self->spore_rx . " could not be found";
    }
    my $json_schema = decode_json($spore_schema);
    my $schema      = $rx->make_schema($json_schema);
    try {
        my $valid = $schema->assert_valid($spec);
    }
    catch {
        croak "Spore specification is invalid, please fix it\n" . $_;
    };
}

# take a spec and instanciate methods that matches those

sub build_from_spec {
    my $self = shift;
    my $spec = $self->spec;

    $self->validate_spore($spec);
    my $base_url = $self->base_url;
    croak
      'We need a base URL, either in the spec or as a parameter to build_from_spec'
      unless $base_url;
    $self->build_methods();
}

sub build_methods {
    my $self = shift;
    foreach my $method ( keys %{ $self->spec->{methods} } ) {
        my $sub_from_spec =
          $self->make_sub_from_spec( $self->spec->{methods}->{$method} );
        Sub::Install::install_sub(
            {   code => $sub_from_spec,
                into => ref($self),
                as   => $method,
            }
        );
    }
}

sub make_sub_from_spec {
    my $reg       = shift;
    my $meth_spec = shift;
    return sub {
        my $self = shift;
        $self->clear_request;

        my %param_spec;
        if (scalar @_ == 1 and ref($_[0]) eq 'HASH') {
            %param_spec = %{ $_[0] };
        }
        else {
            %param_spec = @_;
        }

        if ( $self->has_default_params ) {
            foreach my $d_param ( keys( %{ $self->default_params } ) ) {
                $param_spec{$d_param} = $self->default_params->{$d_param};
            }
        }
        my %method_args = %{$meth_spec};
        my $method      = $method_args{method};


        if ( $method_args{required_params} ) {
            foreach my $required ( @{ $method_args{required_params} } ) {
                if ( !grep { $required eq $_ } keys %param_spec ) {
                    croak
                      "Parameter '$required' is marked as required but is missing";
                }
            }
        }
        if ( $method_args{required_payload} || $method_args{optional_payload}) {
            unless ($method =~ /POST|PUT|PATCH/i) { 
                croak 'Payloads are to be used with POST/PUT/PATCH HTTP methods';
            }
            foreach my $required ( @{ $method_args{required_payload} } ) {
                if ( !grep { $required eq $_ } keys %param_spec ) {
                    croak
                      "Parameter '$required' is required for the payload but is missing";
                }
            }
        }

        my $params;
        my $payload; 
        foreach ( @{ $method_args{required_params} } ) {
            push @$params, $_, delete $param_spec{$_};
        }

        foreach ( @{ $method_args{optional_params} } ) {
            push @$params, $_, delete $param_spec{$_}
              if ( defined( $param_spec{$_} ) );
        }
        foreach ( @{ $method_args{required_payload}} ) { 
            $payload->{$_} = delete $param_spec{$_};
        }
        foreach (@{ $method_args{optional_payload} } ) {
            $payload->{$_} = delete $param_spec{$_}
              if ( defined( $param_spec{$_} ) );
        }
        
        if (%param_spec) {
            if ( $self->lax_optionals ) {
                my $option = $self->lax_optionals;
                if ( $option eq 'params' ) {
                    foreach ( keys %param_spec ) {
                        push @$params, $_, delete $param_spec{$_};
                    }
                }
                else {
                    if ( $option eq 'payload' ) {
                        if ( $method =~ /POST|PUT|PATCH/i ) {
                            foreach ( keys %param_spec ) {
                                $payload->{$_} = delete $param_spec{$_};
                            }
                        }
                        else {
                            carp "Discarding the remaining parameters: cannot"
                              . " use lax payload with a method not supporting payloads";
                        }
                    }
                    else {
                        carp
                          "Discarding the remaining parameters since 'lax_optionals'"
                          . " is set, but not to 'params' or 'payload'";
                    }
                }
            }
        }

        my $base_url =
          ( exists $method_args{base_url} )
          ? $method_args{base_url}
          : $self->base_url;
        $base_url = URI->new( $base_url );
        my $env      = {
            REQUEST_METHOD => $method,
            SERVER_NAME    => $base_url->host,
            SERVER_PORT    => $base_url->port,
            SCRIPT_NAME    => (
                $base_url->path eq '/'
                ? ''
                : $base_url->path
            ),
            PATH_INFO       => $method_args{path},
            REQUEST_URI     => '',
            QUERY_STRING    => '',
            HTTP_USER_AGENT => $self->client->agent // '',

            'spore.params'     => $params,
            'spore.payload'    => $payload,
            'spore.errors'     => *STDERR,
            'spore.url_scheme' => $base_url->scheme,
            'spore.userinfo'   => $base_url->userinfo,
            'spore.encode'     => $self->encoding, 
            'spore.decode'     => $self->decoding,
        };
        $self->env($env);
        my $request      = $self->request->finalize();
        my $raw_response = $self->perform_request($request);
        my $knork_response = $self->request->new_response(
            $raw_response->code, $raw_response->message, $raw_response->headers,
            $raw_response->content
        );
        return $self->generate_response($knork_response);
    };
}


sub perform_request {
    my $self    = shift;
    my $request = shift;
    return $self->client->request($request);
}

sub generate_response {
    my $self           = shift;
    my $raw_response   = shift;
    my $orig_response  = shift;
    if ( defined($orig_response) ) {
        $raw_response->raw_body( $orig_response->content )
          unless defined( ( $raw_response->raw_body ) );
    }
    return $raw_response;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Knork - Lightweight implementation of Spore specification

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::HTTP::Knork;
    use JSON::MaybeXS;
    my $spec = encode_json(
        {   version => 1,
            format  => [ "json", ],
            methods => {
                test => {
                    method => 'GET',
                    path   => '/test/:foo',
                    required_params => [ "foo" ],
                }
            }
            base_url => 'http://example.com',
        }
    );

    my $knork = Net::HTTP::Knork->new(spec => $spec);

    # make a GET to 'http://example.com/test/bar'
    my $resp = $knork->test({ foo => 'bar'});

=head1 DESCRIPTION

Net::HTTP::Knork is a module that was inspired by <the Spore specification|https://github.com/SPORE/specifications/blob/master/spore_description.pod>.
So it is like L<Net::HTTP::Spore> but with some differences.

=head2 JSON or Perl hash specifications

Specifications can be written either in a JSON file, string, or as a Perl hash (no YAML support).
On top of that, every specification passed is validated against a Spore specification embedded, using L<Data::Rx>.

=head2 No middleware modules

This module does not provide middlewares as in L<Net::HTTP::Spore>, but you can alter the default behaviour on requests/responses.
See Middlewares below

=head2 Behaviour of requests with payloads (POST/PUT/PATCH)

The original behaviour of Net::HTTP::Spore with POST/PATCH/PUT was not clear enough, so I made some modifications: 

=over

=item * 
I changed the meaning of required_payload and optional_payload: now they contain the fields required or optional in the payload

=item * 
I removed altogether the support for form-data and payload

=item * 
Consequently I removed the { payload => ... } that was passed to methods when making a request with a payload 

=item * 
The default encoding on payload requests is now set to 'application/x-www-form-urlencoded'. I don't plan on support 'multipart/form-data'
right now, but if needed, it can be added by using 'encoding' and 'decoding' in the constructor.

=back

=head2 HTTP::Response compliant

All the responses returned by Knork are objects from a class extending L<HTTP::Response>.
This means that you can basically manipulate any response returned by a Knork client as an HTTP::Response.

=head2 Always check your HTTP codes !

No assumptions are made regarding the responses you may receive from an API.
It means that, contrary to L<Net::HTTP::Spore>, the code won't just die if the API returns a 4XX. This also implies that you should always check the responses returned.

=head2 Moo !

When I was working with Net::HTTP::Spore, I found it hard to get around all the magic done with Moose.
So this implementation tries to be lightweight.

=head1 METHODS

=over

=item new

Creates a new Knork object.

    my $client = Net::HTTP::Knork->new(spec => '/some/file.json');
    # or
    my $client = Net::HTTP::Knork->new(spec => $a_perl_hash);
    # or
    my $client = Net::HTTP::Knork->new($spec => $a_json_object);

Other constructor options:

=over

=item *

default_params: hash specifying default parameters to pass on every requests.

    # pass foo=bar on every request
    my $client = Net::HTTP::Knork->new(spec => 'some_file.json', default_params => {foo => 'bar'});

=item *

client: L<LWP::UserAgent> HTTP client. Automatically created if not passed.

=item *

lax_optionals: a string parameter that can either be set to 'payload' or 'params'. When this parameter
is set, the remaining parameters passed to any method will be either put in the URL or in the payload.
The default behaviour is to ignore any parameter that is not explicitly put in the spec. 

=item * 
encoding/decoding: those parameters allow you to apply an encoding/decoding on the requests/responses. 
Encoding or decoding is applied BEFORE the middlewares and can be changed on the fly (attributes are rw).

=over

=item * 
encoding: a subref that will be applied before the 'middlewares' to encode a request in a certain way. Takes a 
Net::HTTP::Knork::Request object as an argument and MUST return a Net::HTTP::Knork::Request object. 
When using the encoding attribute, the content is set to a Perl hash containing the keys/values needed for 
the POST request.

    use JSON::MaybeXS;
    my $client = Net::HTTP::Knork->new($spec => 'some_spec.json', 
        encoding => sub {  
            my $req = shift; 
            my $content = $req->content; 
            $req->content(encode_json ($content));
            return $req;
        }
    );

=item *
decoding: a subref that will be applied before the 'middlewares' to decode a request in a certain way. Takes a 
Net::HTTP::Knork::Response object as an argument and MUST return a Net::HTTP::Knork object.

    use JSON::MaybeXS;
    my $client = Net::HTTP::Knork->new($spec => 'some_spec.json', 
        decoding => sub {  
            my $req = shift; 
            my $content = $req->content; 
            $req->content(decode_json ($content));
            return $req;
        }
    );

=back

=back

=item make_sub_from_spec

Creates a new Knork sub from a snippet of spec.
You might want to do that if you want to create new subs with parameters you can get on runtime, while maintaining all the benefits of using Knork.

    my $client = Net::HTTP::Knork->new(spec => '/some/file.json');
    my $response = $client->get_foo_url();
    my $foo_url = $response->body->{foo_url};
    my $post_foo = $client->make_sub_from_spec({method => 'POST', path => $foo_url});
    $client->$post_foo(payload => { bar => 'baz' });

=back

=head1 MIDDLEWARES

=head2 Usage

    use strict;
    use warnings;
    use Net::HTTP::Knork;
    my $client = Net::HTTP::Knork->new(spec => '/path/to/spec.json');
    $client->add_middleware(
        {   on_request => sub {
                my $self = shift;
                my $req = shift;
                # alter the request in some way
                return $req;
            },
            on_response => sub {
                my $self = shift;
                my $resp = shift;
                # alter the response in some way
                return $resp;
              }
        }
    );

Although middlewares cannot be created as in L<Net::HTTP::Spore>, there is still the possibility to declare subs that will 
be executed either before the request is sent or before the response is processed. 
To accomplish this, it installs modifiers around some core functions in L<Net::HTTP::Knork>, using L<Class::Method::Modifiers>.

=head2 Limitations

=over

=item *
Basic : The system is kind of rough on edges. It should match simple needs, but for complex middlewares it would need a lot of code.

=item *

Order of application : The last middleware applicated will always be the first executed.

=back

=head1 TESTING

As a HTTP client can be specified as a parameter when building a Net::HTTP::Knork client, this means that you can use L<Test::LWP::UserAgent> to test your client. This is also how tests for Net::HTTP::Knork are implemented.

    use Test::More;
    use Test::LWP::UserAgent;
    use Net::HTTP::Knork;
    use Net::HTTP::Knork::Response;
    my $tua = Test::LWP::UserAgent->new;
    $tua->map_response(
        sub {
            my $req = shift;
            my $uri_path = $req->uri->path;
            if ( $req->method eq 'GET' ) {
                return ( $uri_path eq '/show/foo' );
            }
        },
        Net::HTTP::Knork::Response->new('200','OK')
    );
    my $client = Net::HTTP::Knork->new(
        spec => {
            base_url => 'http://example.com',
            name     => 'test',
            methods  => [
                {   get_user_info => { method => 'GET', path => '/show/:user' }
                }
            ]
        },
        client => $tua
    );


    my $resp = $client->get_user_info( { user => 'foo' } );
    is( $resp->code, '200', 'our user is correctly set to foo' );

=head1 TODO

This is still early alpha code but there are still some things missing :

=over

=item *

debug mode

=item *

more tests

=item *

a real life usage

=back

=head1 BUGS

This code is early alpha, so there will be a whole bucket of bugs.

=head1 ACKNOWLEDGEMENTS

Many thanks to Franck Cuny, the originator of L<Net::HTTP::Spore>. Some parts of this module borrow code from his module.

=head1 SEE ALSO

L<Net::HTTP::Spore>

=head1 AUTHOR

Emmanuel Peroumalnaïk

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by E. Peroumalnaik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Daniel Gempesaw - Fabrice Gabolde

=over 4

=item *

Daniel Gempesaw - <gempesaw@cpan.org>

=item *

Fabrice Gabolde - <fabrice.gabolde@gmail.com>

=back

=cut
