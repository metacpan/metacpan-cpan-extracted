package Museum::EICAS;

use 5.34.0;
use strictures 2;

use JSON::MaybeXS;
use LWP::UserAgent;
use Moo;
use URI::QueryParam;

use namespace::clean;

=head1 NAME

Museum::EICAS - A simple interface to the EICAS museum API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides access to the bulk items, individual item, and media endpoints from
the EICAS (European Institute for Contemporary Art and Science.) See
L<https://collectie.eicas.nl/api/items?per_page=10> for an example of how the
API looks.

    use Museum::EICAS;

    my $m = Museum::EICAS->new();

    # Returns an arrayref of all the data.
    my $all = $m->get_items();
   
    # Get a particular item
    my $item = $m->get_item(42);

    # Get media data for an item
    my $media = $m->get_media($item);

    # Or for a particular media ID (not item ID)
    my $media = $m->get_media(69);

The data is returned pretty much as it comes from the endpoint, converted into
a Perl structure.

Generally calls die on failure.

=head1 METHODS

=head2 get_items

Returns an arrayref of all the data in the EICAS catalogue. At time of writing,
this is small enough that it's no problem.

=cut

sub get_items {
    my ($self) = @_;

    # I'd like to implement paging, but I'm not sure how to do that in the API, and
    # right now it's not needed
    my $url_part = 'items?per_page=1000';
    return $self->_http_query($url_part);
}

=head2 get_item

Fetches the item detail, the only parameter is the item ID.

=cut

sub get_item {
    my ($self, $item_id) = @_;

    my $url_part = 'items/' . $item_id;
    return $self->_http_query($url_part);
}

=head2 get_media

Returns an arrayref containing the media entries associated with the passed in
item record. Empty list if there are none.

=cut

sub get_media {
    my ($self, $item) = @_;

    my @media;

    my @ids = map { $_->{'o:id'} } $item->{'o:media'}->@*;

    for my $id (@ids) {
        my $url_part = 'media/' . $id;
        push @media, $self->_http_query($url_part);
    }
    return \@media;
}

# Abstracts away all the HTTP guff
sub _http_query {
    my ($self, $url_part) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::EICAS/$VERSION");

    my $url = URI->new( $self->url_base . $url_part );

    my $req = HTTP::Request->new(
        GET => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
        ]
    );

    my $res = $ua->request($req);

    if (!$res->is_success) {
        die "Failed to query EICAS '$url_part' endpoint: " . $res->status_line . "\n";
    }

    my $json = JSON::MaybeXS->new();
    my $content = $json->decode( $res->decoded_content );
    return $content;
}

has 'url_base' => (
    is      => 'ro',
    default => 'https://collectie.eicas.nl/api/',
);

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-museum-eicas at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Museum-EICAS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Museum::EICAS


You can also look for information at:

=over 4

=item * Source Repository (report bugs here)

L<https://gitlab.com/eythian/museum-eicas>

=item * RT: CPAN's request tracker (or here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Museum-EICAS>

=item * Search CPAN

L<https://metacpan.org/release/Museum-EICAS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Robin Sheat.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007


=cut

1; # End of Museum::EICAS
