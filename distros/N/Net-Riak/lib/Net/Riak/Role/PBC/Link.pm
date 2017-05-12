package Net::Riak::Role::PBC::Link;
{
  $Net::Riak::Role::PBC::Link::VERSION = '0.1702';
}
use Moose::Role;
use Net::Riak::Link;
use Net::Riak::Bucket;

sub _populate_links {
    my ($self, $object, $links) = @_;

    for my $link (@$links) {
        my $l = Net::Riak::Link->new(
            bucket => Net::Riak::Bucket->new(
                name   => $link->bucket,
                client => $self
            ),
            key => $link->key,
            tag => $link->tag
        );
        $object->add_link($l);
    }
}

sub _links_for_message {
    my ($self, $object) = @_;

    return [
        map { {
                tag => $_->tag,
                key => $_->key,
                bucket => $_->bucket->name
            }
        } $object->all_links
    ]
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::Link

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
