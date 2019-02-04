# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Server;

use strict;
use warnings;

our $VERSION = '0.003003';

use Plack::Request;
use Plack::Response;
use HTTP::Headers::ActionPack;
use Module::Runtime ();
use JSON::MaybeXS;
use URI::Escape qw( uri_unescape );

use PONAPI::Server::ConfigReader;
use PONAPI::Names qw( check_name );

use parent 'Plack::Component';

use constant {
    ERR_MISSING_MEDIA_TYPE   => +{ __error__ => +[ 415, "{JSON:API} No {json:api} Media-Type (Content-Type / Accept)" ] },
    ERR_MISSING_CONTENT_TYPE => +{ __error__ => +[ 415, "{JSON:API} Missing Content-Type header" ] },
    ERR_WRONG_CONTENT_TYPE   => +{ __error__ => +[ 415, "{JSON:API} Invalid Content-Type header" ] },
    ERR_WRONG_HEADER_ACCEPT  => +{ __error__ => +[ 406, "{JSON:API} Invalid Accept header" ] },
    ERR_BAD_REQ              => +{ __error__ => +[ 400, "{JSON:API} Bad request" ] },
    ERR_BAD_REQ_INVALID_NAME => +{ __error__ => +[ 400, "{JSON:API} Bad request (invalid member-name)" ] },
    ERR_BAD_REQ_PARAMS       => +{ __error__ => +[ 400, "{JSON:API} Bad request (unsupported parameters)" ] },
    ERR_SORT_NOT_ALLOWED     => +{ __error__ => +[ 400, "{JSON:API} Server-side sorting not allowed" ] },
    ERR_NO_MATCHING_ROUTE    => +{ __error__ => +[ 404, "{JSON:API} No matching route" ] },
};

my $qr_member_name_prefix = qr/^[a-zA-Z0-9]/;

sub prepare_app {
    my $self = shift;

    my %conf;
    local $@;
    eval {
        %conf = PONAPI::Server::ConfigReader->new(
            dir => $self->{'ponapi.config_dir'} || 'conf'
        )->read_config;
    };
    $self->{$_} //= $conf{$_} for keys %conf;

    # Some defaults
    my $default_media_type           = 'application/vnd.api+json';
    $self->{'ponapi.spec_version'} //= '1.0';
    $self->{'ponapi.mediatype'}    //= $default_media_type;

    $self->_load_dao();
}

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);

    my $ponapi_params;
    eval {
        $ponapi_params = $self->_ponapi_params( $req );
        1;
    } or do {
        $ponapi_params = $@;
    };

    return $self->_options_response( $ponapi_params->{__options__} )
        if $ponapi_params->{__options__};

    return $self->_error_response( $ponapi_params->{__error__} )
        if $ponapi_params->{__error__};

    my $action = delete $ponapi_params->{action};
    my ( $status, $headers, $res ) = $self->{'ponapi.DAO'}->$action($ponapi_params);
    return $self->_response( $status, $headers, $res, $req->method eq 'HEAD' );
}


### ...

sub _load_dao {
    my $self = shift;

    my $repository =
        Module::Runtime::use_module( $self->{'repository.class'} )->new( @{ $self->{'repository.args'} } )
          || die "[PONAPI Server] failed to create a repository object\n";

    $self->{'ponapi.DAO'} = PONAPI::DAO->new(
        repository => $repository,
        version    => $self->{'ponapi.spec_version'},
    );
}

sub _is_get_like {
    my $req = shift;
    return 1 if $req->method =~ /^(?:GET|HEAD)$/;
    return;
}

sub _ponapi_params {
    my ( $self, $req ) = @_;

    # THE HEADERS
    $self->_ponapi_check_headers($req);

    # THE PATH --> route matching
    my @ponapi_route_params = $self->_ponapi_route_match($req);

    # THE QUERY
    my @ponapi_query_params = $self->_ponapi_query_params($req);

    # THE BODY CONTENT
    my @ponapi_data = $self->_ponapi_data($req);

    # misc.
    my $req_base      = $self->{'ponapi.relative_links'} eq 'full' ? "".$req->base : '/';
    my $req_path      = $self->{'ponapi.relative_links'} eq 'full' ? "".$req->uri : $req->request_uri;
    my $update_200    = !!$self->{'ponapi.respond_to_updates_with_200'};
    my $doc_self_link = _is_get_like($req) ? !!$self->{'ponapi.doc_auto_self_link'} : 0;

    my %params = (
        @ponapi_route_params,
        @ponapi_query_params,
        @ponapi_data,
        req_base                    => $req_base,
        req_path                    => $req_path,
        respond_to_updates_with_200 => $update_200,
        send_doc_self_link          => $doc_self_link,
    );

    return \%params;
}

sub _ponapi_route_match {
    my ( $self, $req ) = @_;
    my $method = $req->method;

    die(ERR_BAD_REQ) unless grep { $_ eq $method } qw< GET POST PATCH DELETE HEAD OPTIONS >;

    my ( $type, $id, $relationships, $rel_type ) = split '/' => substr($req->path_info,1);

    # validate `type`
    die(ERR_BAD_REQ) unless defined $type and $type =~ /$qr_member_name_prefix/ ;

    # validate `rel_type`
    if ( defined $rel_type ) {
        die(ERR_BAD_REQ) if $relationships ne 'relationships';
    }
    elsif ( $relationships ) {
        $rel_type = $relationships;
        undef $relationships;
    }

    my $def_rel_type = defined $rel_type;

    die(ERR_BAD_REQ) if $def_rel_type and $rel_type !~ /$qr_member_name_prefix/;

    # set `action`
    my $action;
    if ( defined $id ) {
        $action = 'create_relationships'     if $method eq 'POST'   and $relationships  and $def_rel_type;
        $action = 'retrieve'                 if _is_get_like($req)  and !$relationships and !$def_rel_type;
        $action = 'retrieve_by_relationship' if _is_get_like($req)  and !$relationships and $def_rel_type;
        $action = 'retrieve_relationships'   if _is_get_like($req)  and $relationships  and $def_rel_type;
        $action = 'update'                   if $method eq 'PATCH'  and !$relationships and !$def_rel_type;
        $action = 'update_relationships'     if $method eq 'PATCH'  and $relationships  and $def_rel_type;
        $action = 'delete'                   if $method eq 'DELETE' and !$relationships and !$def_rel_type;
        $action = 'delete_relationships'     if $method eq 'DELETE' and $relationships  and $def_rel_type;
    }
    else {
        $action = 'retrieve_all'             if _is_get_like($req);
        $action = 'create'                   if $method eq 'POST';
    }

    if ( $method eq 'OPTIONS' ) {
        my @options = (qw< GET HEAD > );
        if ( defined $id ) {
            push @options => (qw< PATCH DELETE >) unless $def_rel_type;
        }
        else {
            push @options => 'POST';
        }
        die( +{ __options__ => \@options } );
    }

    die(ERR_NO_MATCHING_ROUTE) unless $action;

    # return ( action, type, id?, rel_type? )
    my @ret = ( action => $action, type => $type );
    defined $id   and push @ret => id => $id;
    $def_rel_type and push @ret => rel_type => $rel_type;
    return @ret;
}

sub _ponapi_check_headers {
    my ( $self, $req ) = @_;

    return if $req->method eq 'OPTIONS';

    my $mt = $self->{'ponapi.mediatype'};

    my $has_mediatype = 0;

    # check Content-Type
    if ( $req->content_length ) {
        if ( my $content_type = $req->headers->header('Content-Type') ) {
            die(ERR_WRONG_CONTENT_TYPE) unless $content_type eq $mt;
            $has_mediatype++;
        } else {
            die(ERR_MISSING_CONTENT_TYPE)
        }
    }

    # check Accept
    if ( my $accept = $req->headers->header('Accept') ) {
        my $pack = HTTP::Headers::ActionPack->new;

        my @jsonapi_accept =
            map { ( $_->[1]->type eq $mt ) ? $_->[1] : () }
            $pack->create_header( 'Accept' => $accept )->iterable;

        if ( @jsonapi_accept ) {
            die(ERR_WRONG_HEADER_ACCEPT)
                unless grep { $_->params_are_empty } @jsonapi_accept;

            $has_mediatype++;
        }
    }

    die(ERR_MISSING_MEDIA_TYPE) unless $has_mediatype;
}

sub _ponapi_query_params {
    my ( $self, $req ) = @_;

    my %params;
    my $query_params = $req->query_parameters;

    my $unesacpe_values = !!$req->headers->header('X-PONAPI-Escaped-Values');

    # loop over query parameters (unique keys)
    for my $k ( sort keys %{ $query_params } ) {
        my ( $p, $f ) = $k =~ /^ (\w+?) (?:\[(\w+)\])? $/x;

        # key not matched
        die(ERR_BAD_REQ_PARAMS) unless defined $p;

        # valid parameter names
        die(ERR_BAD_REQ_PARAMS)
            unless grep { $p eq $_ } qw< fields filter page include sort >;

        # "complex" parameters have the correct structre
        die(ERR_BAD_REQ)
            if !defined $f and grep { $p eq $_ } qw< page fields filter >;

        # 'sort' requested but not supported
        die(ERR_SORT_NOT_ALLOWED)
            if $p eq 'sort' and !$self->{'ponapi.sort_allowed'};

        # values can be passed as CSV
        my @values = map { $unesacpe_values ? uri_unescape($_) : $_ }
                     map { split /,/ } $query_params->get_all($k);

        # check we have values for a given key
        # (for 'fields' an empty list is valid)
        die(ERR_BAD_REQ) if $p ne 'fields' and !@values;

        # values passed on in array-ref
        grep { $p eq $_ } qw< fields filter >
            and $params{$p}{$f} = \@values;

        # page info has one value per request
        $p eq 'page' and $params{$p}{$f} = $values[0];

        # values passed on in hash-ref
        $p eq 'include' and $params{include} = \@values;

        # sort values: indicate direction
        # Not doing any processing here to allow repos to support
        # complex sorting, if they want to.
        $p eq 'sort' and $params{'sort'} = \@values;
    }

    return %params;
}

sub _ponapi_data {
    my ( $self, $req ) = @_;

    return unless $req->content_length and $req->content_length > 0;

    die(ERR_BAD_REQ) if _is_get_like($req);

    my $body;
    eval { $body = JSON::MaybeXS::decode_json( $req->content ); 1 };

    die(ERR_BAD_REQ) unless $body and ref $body eq 'HASH' and exists $body->{data};

    my $data = $body->{data};

    die(ERR_BAD_REQ) if defined $data and ref($data) !~ /^(?:ARRAY|HASH)$/;

    $self->_validate_data_members($data) if defined $data;

    return ( data => $data );
}

sub _validate_data_members {
    my ( $self, $data ) = @_;

    my @recs = ref $data eq 'ARRAY' ? @{$data} : $data;

    for my $r ( @recs ) {
        return unless keys %{$r};

        # `type`
        die(ERR_BAD_REQ)              unless $r->{type};
        die(ERR_BAD_REQ_INVALID_NAME) unless check_name( $r->{type} );

        # `attributes`
        if ( exists $r->{attributes} ) {
            die(ERR_BAD_REQ) unless ref( $r->{attributes} ) eq 'HASH';
            die(ERR_BAD_REQ_INVALID_NAME)
                if grep { !check_name($_) } keys %{ $r->{attributes} };
        }

        # `relationships`
        if ( exists $r->{relationships} ) {
            die(ERR_BAD_REQ) unless ref( $r->{relationships} ) eq 'HASH';

            for my $k ( keys %{ $r->{relationships} } ) {
                die(ERR_BAD_REQ_INVALID_NAME) unless check_name($k);

                my $rel  = $r->{relationships}{$k};
                my @rels = ref($rel||'') eq 'ARRAY' ? @$rel : $rel;
                foreach my $relationship ( @rels ) {
                    next unless defined $relationship;
                    # Some requests have relationships => { blah },
                    # others have relationships => { data => { blah } }
                    $relationship = $relationship->{data}
                        if exists $relationship->{data};

                    die(ERR_BAD_REQ) unless
                        ref($relationship) eq 'HASH' and exists $relationship->{type};

                    die(ERR_BAD_REQ_INVALID_NAME)
                        if !check_name( $relationship->{type} )
                            or grep { !check_name($_) } keys %$relationship;
                }
            }
        }
    }
}

sub _response {
    my ( $self, $status, $headers, $content, $is_head ) = @_;
    my $res = Plack::Response->new( $status || 200 );

    $res->headers($headers);
    $res->header( 'X-PONAPI-Server-Version' => $self->{'ponapi.spec_version'} )
        if $self->{'ponapi.send_version_header'};

    if ( ref $content ) {
        my $enc_content = JSON::MaybeXS::encode_json $content;
        $res->content_length( length($enc_content) );
        $res->content_type( $self->{'ponapi.mediatype'} );
        $res->content($enc_content) unless $is_head;
    }

    $res->finalize;
}

sub _options_response {
    my ( $self, $options ) = @_;
    return +[ 200, [ Allow => join( ', ' => @{$options} ) ], [] ];
}

sub _error_response {
    my ( $self, $args ) = @_;

    return $self->_response( $args->[0], [], +{
        jsonapi => { version => $self->{'ponapi.spec_version'} },
        errors  => [ { detail => $args->[1], status => $args->[0] } ],
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Server - PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0

=head1 VERSION

version 0.003003

=head1 SYNOPSIS

    # Run the server
    $ plackup -MPONAPI::Server -e 'PONAPI::Server->new("repository.class" => "Test::PONAPI::Repository::MockDB")->to_app'

    $ perl -MPONAPI::Client -E 'say Dumper(PONAPI::Client->new->retrieve(type => "people", id => 88))'

    # Or with cURL:
    $ curl -X GET -H "Content-Type: application/vnd.api+json" 'http://0:5000/people/88'

=head1 DESCRIPTION

C<PONAPI::Server> is a small plack server that implements the
L<{json:api}|http://jsonapi.org/> specification.

You'll have to set up a repository (to provide access to the data
you want to serve) and tweak some server configurations, so
hop over to L<PONAPI::Manual> for the next steps!

=head1 BUGS, CONTACT AND SUPPORT

For reporting bugs or submitting patches, please use the github
bug tracker at L<https://github.com/mickeyn/PONAPI>.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
