package Net::Riak::Role::PBC::Bucket;
{
  $Net::Riak::Role::PBC::Bucket::VERSION = '0.1702';
}
use Moose::Role;

sub get_properties {
    my ( $self, $name, $params ) = @_;
    my $resp = $self->send_message( GetBucketReq => { bucket => $name } );
    return { props =>  { %{ $resp->props } } };
}

sub set_properties {
    my ( $self, $bucket, $props ) = @_;
    return $self->send_message(
        SetBucketReq => {
            bucket => $bucket->name,
            props  => $props
        }
    );
}

sub get_keys {
    my ( $self, $name, $params) = @_;
    my $keys = [];

    my $res = $self->send_message(
        ListKeysReq => { bucket => $name, },
        sub {
            if ( defined $_[0]->keys ) {
                if ($params->{cb}) {
                    $params->{cb}->($_) for @{ $_[0]->keys };
                }
                else {
                    push @$keys, @{ $_[0]->keys };
                }
            }
        }
    );

    return $params->{cb} ? undef : $keys;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::Bucket

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
