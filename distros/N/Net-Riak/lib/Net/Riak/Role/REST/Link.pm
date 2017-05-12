package Net::Riak::Role::REST::Link;
{
  $Net::Riak::Role::REST::Link::VERSION = '0.1702';
}
use Moose::Role;
use Net::Riak::Link;
use Net::Riak::Bucket;

sub _populate_links {
    my ($self, $object, $links) = @_;

    for my $link (split(',', $links)) {
        if ($link
            =~ /\<\/([^\/]+)\/([^\/]+)\/([^\/]+)\>; ?riaktag=\"([^\']+)\"/)
        {
            my $bucket = _uri_decode($2);
            my $key    = _uri_decode($3);
            my $tag    = _uri_decode($4);
            my $l      = Net::Riak::Link->new(
                bucket => Net::Riak::Bucket->new(
                    name   => $bucket,
                    client => $self
                ),
                key => $key,
                tag => $tag
            );
            $object->add_link($l);
        }
    }
}

sub _uri_decode {
  my $str = shift;
  $str =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
  return $str;
}

sub _links_to_header {
    my ($self, $object) = @_;
    join(', ', map { $self->link_to_header($_) } $object->links);
}

sub link_to_header {
    my ($self, $link) = @_;

    my $link_header = '';
    $link_header .= '</';
    $link_header .= $self->prefix . '/';
    $link_header .= $link->bucket->name . '/';
    $link_header .= $link->key . '>; riaktag="';
    $link_header .= $link->tag . '"';
    return $link_header;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::REST::Link

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
