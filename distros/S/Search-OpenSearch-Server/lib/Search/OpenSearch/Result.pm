package Search::OpenSearch::Result;
use Moose;
use JSON;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

use namespace::autoclean;

our $VERSION = '0.301';

has 'build_time'  => ( is => 'rw' );
has 'search_time' => ( is => 'rw' );
has 'doc'         => ( is => 'rw' );
has 'code'        => ( is => 'rw' );
has 'success'     => ( is => 'rw' );
has 'msg'         => ( is => 'rw' );
has 'total'       => ( is => 'rw' );

sub stringify {
    my $self = shift;

    #Data::Dump::dump($self);
    my $json = encode_json( {%$self} );

    #warn "json=$json";
    return $json;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Result - REST action response

=head1 SYNOPSIS

 my $server = Search::OpenSearch::Server::Plack->new();
 my $result = $server->do_rest_api( Plack::Request->new( $env ) );
 print $result;

=head1 DESCRIPTION

This class is used internally to represent the result of a REST
API action.

=head1 METHODS

=head2 new( I<attrs> )

I<attrs> are key/value pairs with keys including:

=over

=item build_time

=item search_time

=item code

=item doc

=item success

=item msg

=item total

=back

=head2 stringify

Returns the object as a JSON-encoded string.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Server/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
