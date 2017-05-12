use 5.10.0;
use strict;
use warnings;

package Types::Opendata::GTFS;

# ABSTRACT: Types for Opendata::GTFS
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0202';

use namespace::autoclean;
use Type::Library -base;
use Type::Utils -all;

class_type Agency        => { class => 'Opendata::GTFS::Type::Agency' };
class_type Calendar      => { class => 'Opendata::GTFS::Type::Calendar' };
class_type CalendarDate  => { class => 'Opendata::GTFS::Type::CalendarDate' };
class_type FareAttribute => { class => 'Opendata::GTFS::Type::FareAttribute' };
class_type FareRule      => { class => 'Opendata::GTFS::Type::FareRule' };
class_type Frequency     => { class => 'Opendata::GTFS::Type::Frequency' };
class_type Route         => { class => 'Opendata::GTFS::Type::Route' };
class_type Shape         => { class => 'Opendata::GTFS::Type::Shape' };
class_type Stop          => { class => 'Opendata::GTFS::Type::Stop' };
class_type Transfer      => { class => 'Opendata::GTFS::Type::Transfer' };
class_type StopTime      => { class => 'Opendata::GTFS::Type::StopTime' };
class_type Trip          => { class => 'Opendata::GTFS::Type::Trip' };

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Opendata::GTFS - Types for Opendata::GTFS

=head1 VERSION

Version 0.0202, released 2016-02-28.

=head1 TYPES

=over 4

=item *

L<Agency|Opendata::GTFS::TypeAgency>

=item *

L<Calendar|Opendata::GTFS::Type::Calendar>

=item *

L<CalendarDate|Opendata::GTFS::Type::CalendarDate>

=item *

L<FareAttribute|Opendata::GTFS::Type::FareAttribute>

=item *

L<FareRule|Opendata::GTFS::Type::FareRule>

=item *

L<Frequency|Opendata::GTFS::Type::Frequency>

=item *

L<Route|Opendata::GTFS::Type::Route>

=item *

L<Shape|Opendata::GTFS::Type::Shape>

=item *

L<Stop|Opendata::GTFS::Type::Stop>

=item *

L<Transfer|Opendata::GTFS::Type::Transfer>

=item *

L<StopTime|Opendata::GTFS::Type::StopTime>

=item *

L<Trip|Opendata::GTFS::Type::Trip>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Opendata-GTFS-Feed>

=head1 HOMEPAGE

L<https://metacpan.org/release/Opendata-GTFS-Feed>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
