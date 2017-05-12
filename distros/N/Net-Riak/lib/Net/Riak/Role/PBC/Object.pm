package Net::Riak::Role::PBC::Object;
{
  $Net::Riak::Role::PBC::Object::VERSION = '0.1702';
}
use JSON;
use Moose::Role;
use List::Util 'first';

sub store_object {
    my ($self, $w, $dw, $object) = @_;

    die "Storing object without a key is not supported in the PBC interface" unless $object->key;

    my $value = (ref $object->data && $object->content_type eq 'application/json')
            ? JSON::encode_json($object->data) : $object->data;

    my $content = {
        content_type => $object->content_type,
        value => $value,
    };

    if ($object->has_links) {
        $content->{links} = $self->_links_for_message($object);
    }

    if ($object->has_meta) {
        $content->{usermeta} = $self->_metas_for_message($object);
    }

    $self->send_message(
        PutReq => {
            bucket  => $object->bucket->name,
            key     => $object->key,
            content => $content,
        }
    );
    return $object;
}

sub load_object {
    my ( $self, $params, $object ) = @_;

    my $resp = $self->send_message(
        GetReq => {
            bucket => $object->bucket->name,
            key    => $object->key,
            r      => $params->{r},
        }
    );

    $self->populate_object($object, $resp);

    return $object;
}

sub delete_object {
    my ( $self, $params, $object ) = @_;

    my $resp = $self->send_message(
        DelReq => {
            bucket => $object->bucket->name,
            key    => $object->key,
            rw     => $params->{dw},
        }
    );

    $object;
}

sub populate_object {
    my ( $self, $object, $resp) = @_;

    $object->_clear_links;
    $object->exists(0);

    if ( $resp->content && scalar (@{$resp->content}) > 1) {
        my %seen;
        my @vtags = grep { !$seen{$_}++ } map { $_->vtag } @{$resp->content};
        $object->siblings(\@vtags);
    }

    my $content = $resp->content ? $resp->content->[0] : undef;

    return unless $content and $resp->vclock;

    $object->vclock($resp->vclock);
    $object->vtag($content->vtag);
    $object->content_type($content->content_type);

    if($content->links) {
        $self->_populate_links($object, $content->links);
    }

    if($content->usermeta) {
        $self->_populate_metas($object, $content->usermeta);
    }

    my $data = ($object->content_type eq 'application/json')
        ? JSON::decode_json($content->value) : $content->value;

    $object->exists(1);

    $object->data($data);
}


# This emulates the behavior of the existing REST client.
sub retrieve_sibling {
    my ($self, $object, $params) = @_;

    my $resp = $self->send_message(
        GetReq => {
            bucket => $object->bucket->name,
            key    => $object->key,
            r      => $params->{r},
        }
    );

    # hack for loading 1 sibling
    if ($params->{vtag}) {
        $resp->{content} = [
            first {
                $_->vtag eq $params->{vtag}
            } @{$resp->content}
        ];
    }

    my $sibling = Net::Riak::Object->new(
        client => $self,
        bucket => $object->bucket,
        key    => $object->key
    );

    $sibling->_jsonize($object->_jsonize);

    $self->populate_object($sibling, $resp);

    $sibling;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::Object

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
