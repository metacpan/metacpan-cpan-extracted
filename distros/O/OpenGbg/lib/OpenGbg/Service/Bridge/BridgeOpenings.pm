use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Bridge::BridgeOpenings;

# ABSTRACT: A list of bridge openings/closings
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit;

has_xpath_object_list _bridge_openings => './x:BridgeOpen' => 'OpenGbg::Service::Bridge::BridgeOpening',
                                        handles => {
                                            all => 'elements',
                                            count => 'count',
                                            filter => 'grep',
                                            find => 'first',
                                            get_by_index => 'get',
                                            map => 'map',
                                            sort => 'sort',
                                        };

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::Bridge::BridgeOpenings - A list of bridge openings/closings

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SYNOPSIS

    my $bridge = OpenGbg->new->bridge;
    my $get_os = $bridge->get_opened_status;

    my $opening = $get_opened_status->bridge_openings->get_by_index(5);

    printf 'It was %s at %s on %s', $opening->was_open ? 'open' : 'closed', $opening->timestamp->hms, $opening->timestamp->ymd;

=head1 METHODS

=head2 all

Returns an array of the L<OpenGbg::Service::Bridge::BridgeOpening> objects in the response.

=head2 count

Returns the number of L<BridgeOpening|OpenGbg::Service::Bridge::BridgeOpening> objects in the response.

=head2 filter(sub { ... })

Allows filtering of the bridge openings. Takes a sub routine reference, into which all L<BridgeOpening|OpenGbg::Service::Bridge::BridgeOpening> objects are
passed one-by-one into C<$_>. Works like C<grep>. For example, to get the number of times the bridge was open:

use List::AllUtils 'sum';
my $opening_count = scalar $get_opened_status->bridge_openings->filter(sub { $_->was_open });

=head2 find(sub { ... })

Just like C<filter>, except it returns the first bridge opening that matches.

=head2 get_by_index($index)

Returns the n:th L<OpenGbg::Service::Bridge::BridgeOpening> object in the response.

=head2 map(sub { ... })

Like C<filter> it takes a sub routine reference and passes each L<BridgeOpening|OpenGbg::Service::Bridge::BridgeOpening> as C<$_>.

=head2 sort(sub { ... })

Like C<filter> it takes a sub routine reference. It works just like C<sort> except the two L<BridgeOpening|OpenGbg::Service::Bridge::BridgeOpening> objects to compare are passed as C<$_[0]> and C<$_[1]>

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
