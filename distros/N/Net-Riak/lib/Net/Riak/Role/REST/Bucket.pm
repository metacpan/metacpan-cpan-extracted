package Net::Riak::Role::REST::Bucket;
{
  $Net::Riak::Role::REST::Bucket::VERSION = '0.1702';
}

use Moose::Role;
use JSON;

sub get_properties {
    my ($self, $name, $params) = @_;

    # Callbacks require stream mode
    $params->{keys}  = 'stream' if $params->{cb};

    $params->{props} = 'true'  unless exists $params->{props};
    $params->{keys}  = 'false' unless exists $params->{keys};

    my $request = $self->new_request(
        'GET', [$self->prefix, $name], $params
    );

    my $response = $self->send_request($request);

    unless ($response->is_success) {
        die "Error getting bucket properties: ".$response->status_line."\n";
    }

    if ($params->{keys} ne 'stream') {
        return JSON::decode_json($response->content);
    }

    # In streaming mode, aggregate keys from the multiple returned chunk objects
    else {
        my $json = JSON->new;
        my $props = $json->incr_parse($response->content);
        if ($params->{cb}) {
            while (defined(my $obj = $json->incr_parse)) {
                $params->{cb}->($_) foreach @{$obj->{keys}};
            }
            return %$props ? { props => $props } : {};
        }
        else {
            my @keys = map { $_->{keys} && ref $_->{keys} eq 'ARRAY' ? @{$_->{keys}} : () }
                $json->incr_parse;
            return { props => $props, keys => \@keys };
        }
    }
}

sub set_properties {
    my ($self, $bucket, $props) = @_;

    my $request = $self->new_request(
        'PUT', [$self->prefix, $bucket->name]
    );

    $request->header('Content-Type' => $bucket->content_type);
    $request->content(JSON::encode_json({props => $props}));

    my $response = $self->send_request($request);
    unless ($response->is_success) {
        die "Error setting bucket properties: ".$response->status_line."\n";
    }
}

sub get_keys {
    my ($self, $bucket, $params) = @_;

    my $key_mode = delete($params->{stream}) ? 'stream' : 'true';
    $params = { props => 'false', keys => $key_mode, %$params };
    my $properties = $self->get_properties($bucket, $params);

    return $properties->{keys};
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::REST::Bucket

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
