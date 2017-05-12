package Net::Riak::Role::REST::Object;
{
  $Net::Riak::Role::REST::Object::VERSION = '0.1702';
}

use Moose::Role;
use JSON;

sub store_object {
    my ($self, $w, $dw, $object) = @_;

    my $params = {returnbody => 'true', w => $w, dw => $dw};

    $params->{returnbody} = 'false'
        if $self->disable_return_body;


    my $request;
    if ( defined $object->key ) {
      $request = $self->new_request('PUT',
        [$self->prefix, $object->bucket->name, $object->key], $params);
    } else {
      $request = $self->new_request('POST',
        [$self->prefix, $object->bucket->name ], $params);
    }

    $request->header('X-Riak-ClientID' => $self->client_id);
    $request->header('Content-Type'    => $object->content_type);

    if ($object->has_vclock) {
        $request->header('X-Riak-Vclock' => $object->vclock);
    }

    if ($object->has_links) {
        $request->header('link' => $self->_links_to_header($object));
    }

    if ($object->has_meta) {
        while ( my ( $k, $v ) = each %{ $object->metadata } ) {
            $request->header('x-riak-meta-' . lc($k) => $v );
        }
    }

    if ($object->i2indexes) {
        foreach (keys %{$object->i2indexes}) {
            $request->header(':x-riak-index-' . lc($_) => $object->i2indexes->{$_});
        }
    }

    if (ref $object->data && $object->content_type eq 'application/json') {
        $request->content(JSON::encode_json($object->data));
    }
    else {
        $request->content($object->data);
    }

    my $response = $self->send_request($request);
    $self->populate_object($object, $response, [200, 201, 204, 300]);
    return $object;
}

sub load_object {
    my ( $self, $params, $object ) = @_;

    my $request =
      $self->new_request( 'GET',
        [ $self->prefix, $object->bucket->name, $object->key ], $params );

    my $response = $self->send_request($request);
    $self->populate_object($object, $response, [ 200, 300, 404 ] );
    $object;
}

sub delete_object {
    my ( $self, $params, $object ) = @_;

    my $request =
      $self->new_request( 'DELETE',
        [ $self->prefix, $object->bucket->name, $object->key ], $params );

    my $response = $self->send_request($request);
    $self->populate_object($object, $response, [ 204, 404 ] );
    $object;
}

sub populate_object {
    my ($self, $obj, $http_response, $expected) = @_;

    $obj->_clear_links;
    $obj->exists(0);

    return if (!$http_response);


    my $status = $http_response->code;

    $obj->data($http_response->content)
        unless $self->disable_return_body;

    if ( $http_response->header('location') ) {
        $obj->key( $http_response->header('location') );
        $obj->location( $http_response->header('location') );
    }

    if (!grep { $status == $_ } @$expected) {
        confess "Expected status "
          . (join(', ', @$expected))
          . ", received: ".$http_response->status_line
    }

    $HTTP::Headers::TRANSLATE_UNDERSCORE = 0;
    foreach ($http_response->header_field_names) {

        if ( /^X-Riak-Index-(.+_bin)$/ || /^X-Riak-Index-(.+_int)$/ ) {
            $obj->add_index(lc($1),  $http_response->header($_))
        }
        elsif ( /^X-Riak-Meta-(.+)$/ ) {
            $obj->set_meta(lc($1), $http_response->header($_));
        }
    }
    $HTTP::Headers::TRANSLATE_UNDERSCORE = 1;

    if ($status == 404) {
        $obj->clear;
        return;
    }

    $obj->exists(1);

    if ($http_response->header('link')) {
        $self->_populate_links($obj, $http_response->header('link'));
    }

    if ($status == 300) {
        my @siblings = split("\n", $obj->data);
        shift @siblings;
        my %seen; @siblings = grep { !$seen{$_}++ } @siblings;
        $obj->siblings(\@siblings);
    }

    if ($status == 201) {
        my $location = $http_response->header('location');
        my ($key)    = ($location =~ m!/([^/]+)$!);
        $obj->key($key);
    }


    if ($status == 200 || $status == 201) {
        $obj->content_type($http_response->content_type)
            if $http_response->content_type;
        $obj->data(JSON::decode_json($obj->data))
            if $obj->content_type eq 'application/json';
        $obj->vclock($http_response->header('X-Riak-Vclock'));
    }
}

sub retrieve_sibling {
    my ($self, $object, $params) = @_;

    my $request = $self->new_request(
        'GET',
        [$self->prefix, $object->bucket->name, $object->key],
        $params
    );

    my $response = $self->send_request($request);

    my $sibling = Net::Riak::Object->new(
        client => $self,
        bucket => $object->bucket,
        key    => $object->key
    );

    $sibling->_jsonize($object->_jsonize);
    $self->populate_object($sibling, $response, [200]);
    $sibling;
}




1;

__END__

=pod

=head1 NAME

Net::Riak::Role::REST::Object

=head1 VERSION

version 0.1702

=over 3

=item populate_object

Given the output of RiakUtils.http_request and a list of statuses, populate the object. Only for use by the Riak client library.

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
