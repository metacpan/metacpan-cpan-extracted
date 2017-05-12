package MouseX::Types::DateTime;

use strict;
use warnings;
use 5.8.1;
use DateTime ();
use DateTime::Duration ();
use DateTime::TimeZone ();
use DateTime::Locale ();
use DateTime::Locale::root ();
use DateTimeX::Easy ();
use Time::Duration::Parse qw(parse_duration);
use Scalar::Util qw(looks_like_number);
use Mouse::Util::TypeConstraints;
use MouseX::Types::Mouse qw(Str HashRef);
use namespace::clean;

use MouseX::Types
    -declare => [qw(DateTime Duration TimeZone Locale)]; # export Types

our $VERSION = '0.02';

class_type 'DateTime'           => { class => 'DateTime' };
class_type 'DateTime::Duration' => { class => 'DateTime::Duration' };
class_type 'DateTime::TimeZone' => { class => 'DateTime::TimeZone' };
class_type 'DateTime::Locale'   => { class => 'DateTime::Locale::root' };

subtype DateTime, as 'DateTime';
subtype Duration, as 'DateTime::Duration';
subtype TimeZone, as 'DateTime::TimeZone';
subtype Locale,   as 'DateTime::Locale';

for my $type ( 'DateTime', DateTime ) {
    coerce $type,
        from Str, via {
            looks_like_number($_)
                ? 'DateTime'->from_epoch(epoch => $_)
                : DateTimeX::Easy->new($_);
        },
        from HashRef, via { 'DateTime'->new(%$_) };
}

for my $type ( 'DateTime::Duration', Duration ) {
    coerce $type,
        from Str, via {
            DateTime::Duration->new(
                seconds => looks_like_number($_) ? $_ : parse_duration($_)
            );
        },
        from HashRef, via { DateTime::Duration->new(%$_) };
}

for my $type ( 'DateTime::TimeZone', TimeZone ) {
    coerce $type,
        from Str, via { DateTime::TimeZone->new(name => $_) };
}

for my $type ( 'DateTime::Locale', Locale ) {
    coerce $type,
        from Str, via { DateTime::Locale->load($_) };
}

1;

=head1 NAME

MouseX::Types::DateTime - A DateTime type library for Mouse

=head1 SYNOPSIS

=head2 CLASS TYPES

    package MyApp;
    use Mouse;
    use MouseX::Types::DateTime;

    has 'datetime' => (
        is     => 'rw',
        isa    => 'DateTime',
        coerce => 1,
    );

    has 'duration' => (
        is     => 'rw',
        isa    => 'DateTime::Duration',
        coerce => 1,
    );

    has 'timezone' => (
        is     => 'rw',
        isa    => 'DateTime::TimeZone',
        coerce => 1,
    );

    has 'locale' => (
        is     => 'rw',
        isa    => 'DateTime::Locale',
        coerce => 1,
    );

=head2 CUSTOM TYPES

    package MyApp;
    use Mouse;
    use MouseX::Types::DateTime qw(DateTime Duration TimeZone Locale);

    has 'datetime' => (
        is     => 'rw',
        isa    => DateTime,
        coerce => 1,
    );

    has 'duration' => (
        is     => 'rw',
        isa    => Duration,
        coerce => 1,
    );

    has 'timezone' => (
        is     => 'rw',
        isa    => TimeZone,
        coerce => 1,
    );

    has 'locale' => (
        is     => 'rw',
        isa    => Locale,
        coerce => 1,
    );

=head1 DESCRIPTION

MouseX::Types::DateTime creates common L<Mouse> types and coercions
for dealing with L<DateTime> objects as L<Mouse> attributes.

Coercions (see L<Mouse::TypeRegistry>) are made from
C<Str> and C<HashRef> to L<DateTime>, L<DateTime::Duration>,
L<DateTime::TimeZone> and L<DateTime::Locale> objects.

=head1 TYPES

=head2 DateTime

=over 4

A L<DateTime> class type.

Coerces from C<Str> via L<DateTime/from_epoch> or L<DateTimeX::Easy/new>.

Coerces from C<HashRef> via L<DateTime/new>.

=back

=head2 Duration

=over 4

A L<DateTime::Duration> class type.

Coerces from C<Str> via L<Time::Duration::Parse/parse_duration>
and L<DateTime::Duration/new>.

Coerces from C<HashRef> via L<DateTime::Duration/new>.

=back

=head2 TimeZone

=over 4

A L<DateTime::TimeZone> class type.

Coerces from C<Str> via L<DateTime::TimeZone/new>.

=back

=head2 Locale

=over 4

A L<DateTime::Locale> (see L<DateTime::Locale::root>) class type.

Coerces from C<Str> via L<DateTime::Locale/load>.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

Yuval Kogman, John Napiorkowski, L<MooseX::Types::DateTime/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>, L<Mouse::TypeRegistry>,

L<DateTime>, L<DateTimeX::Easy>,

L<MooseX::Types::DateTime>, L<MooseX::Types::DateTimeX>

=cut
