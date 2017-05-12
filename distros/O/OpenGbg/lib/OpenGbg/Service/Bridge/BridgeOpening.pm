use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Bridge::BridgeOpening;

# ABSTRACT: A change in status for Göta Älvbron
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use XML::Rabbit;
use DateTime::Format::HTTP;
use MooseX::AttributeShortcuts;
use OpenGbg::DateTimeType qw/DateTime/;
use Types::Standard qw/Bool/;

has_xpath_value _timestamp => './x:TimeStamp';

has_xpath_value _was_open => './x:Value';

has timestamp => (
    is => 'ro',
    isa => DateTime,
    lazy => 1,
    builder => 1,
);

has was_open => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    builder => 1,
);

sub _build_timestamp {
    return DateTime::Format::HTTP->parse_datetime(shift->_timestamp);
}
sub _build_was_open {
    return shift->_was_open eq 'true';
}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::Bridge::BridgeOpening - A change in status for Göta Älvbron

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $bridge = OpenGbg->new->bridge;
    my $status = $bridge->get_opened_status->get_by_index(2);

    printf 'it was %s', $status->was_open ? 'open' : 'closed';

=head1 DESCRIPTIOn

Each C<BridgeOpening> object only knows if the bridge was opened or closed at that time. Usually, an 'open' BridgeOpening is followed a few minutes later by a 'closed' one.

=head1 ATTRIBUTES

=head2 timestamp

A L<DateTime> object.

The time the bridge was either open or closed.

=head2 was_open

Boolean. True if the bridge was open at C<timestamp>, false if not.

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
