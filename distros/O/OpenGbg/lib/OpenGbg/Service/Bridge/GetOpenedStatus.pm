use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Bridge::GetOpenedStatus;

# ABSTRACT: A list of bridge openings
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use XML::Rabbit::Root;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.BridgeService';

has_xpath_object bridge_openings => '/x:BridgeOpenings' => 'OpenGbg::Service::Bridge::BridgeOpenings';

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::Bridge::GetOpenedStatus - A list of bridge openings

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $bridge = OpenGbg->new->bridge;
    my $get_opened_status = $bridge->get_opened_status('2014-10-15', '2014-11-01');

    my $opening = $get_opened_status->bridge_openings->get_by_index(5);

    printf 'It was %s at %s on %s', $opening->was_open ? 'open' : 'closed', $opening->timestamp->hms, $opening->timestamp->ymd;

=head1 METHODS

=head2 bridge_openings

The service returns a list of status changes. The list is prepended with the status at midnight of the start date (given to get_opened_status
in L<Bridge|OpenGbg::Service::Bridge>), and appended with the status at midnight to the end date.

Returns the list of status changes in the response in a L<OpenGbg::Service::Bridge::BridgeOpenings> object.

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
