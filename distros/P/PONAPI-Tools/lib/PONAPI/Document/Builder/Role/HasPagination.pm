# ABSTRACT: document builder - role - pagination
package PONAPI::Document::Builder::Role::HasPagination;

use Moose::Role;

use URI;
use URI::QueryParam;

# requires 'links_builder';
# requires 'req_path';

# self isn't really part of pagination, but it can be overriden here
my %allowed_page_keys = map +($_=>1), qw/
    first
    last
    next
    prev
    self
/;

sub add_pagination_links {
    my ($self, %page_links) = @_;

    $page_links{self} ||= delete $page_links{current}
        if exists $page_links{current};

    foreach my $link_name ( keys %page_links ) {
        die "Tried to add pagination link `$link_name`, not allowed by the spec"
            unless exists $allowed_page_keys{ $link_name };
    }

    my $link = $self->req_path;

    my $uri = URI->new($link);
    my $path = $uri->path;

    $self->links_builder->add_links(
        map {
            my $query = $self->_hash_to_uri_query( {
                page => $page_links{$_}
            }, $uri );
            ( $_ => $path . '?' . $query )
        }
        grep scalar keys %{ $page_links{$_} || {} },
        keys %page_links
    );
}

sub _hash_to_uri_query {
    my ($self, $data, $u) = @_;
    $u ||= URI->new("", "http");

    for my $d_k ( sort keys %$data ) {
        my $d_v = $data->{$d_k};
        defined($d_v) or next;

        if ( ref $d_v ne 'HASH' ) {
            $u->query_param( $d_k =>
                             join ',' => ( ref $d_v eq 'ARRAY' ? @{$d_v} : $d_v ) );
            next;
        }

        # HASH
        for my $k ( sort keys %{$d_v} ) {
            my $v = $d_v->{$k};
            defined($v) or next;

            die "_hash_to_uri_query: nested value can be scalar/arrayref only"
                unless !ref $v or ref $v eq 'ARRAY';

            $u->query_param( $d_k . '[' . $k . ']' =>
                             join ',' => ( ref $v eq 'ARRAY' ? @{$v} : $v ) );
        }
    }

    return $u->query;
}



no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Role::HasPagination - document builder - role - pagination

=head1 VERSION

version 0.001002

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

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
