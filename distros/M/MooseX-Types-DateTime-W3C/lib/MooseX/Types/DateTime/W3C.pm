use strict;
use warnings;
package MooseX::Types::DateTime::W3C;
BEGIN {
  $MooseX::Types::DateTime::W3C::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $MooseX::Types::DateTime::W3C::VERSION = '1.103360';
}
#ABSTRACT: W3C DateTime format type constraint


use MooseX::Types -declare =>[qw(
    DateTimeW3C
)];
use MooseX::Types::Moose qw( Str Num );

use DateTime;
use DateTime::TimeZone 1.26;

subtype DateTimeW3C,
    as Str,
    where { /^
    \d{4}                 # year
    (?:\-\d{2})?            # month
    (?:\-\d{2})?            # day
    (?:
        T
        \d{2}             # hours
        :
        \d{2}             # minutes
        (?:
            :\d{2}        # seconds
            (?:
                \.\d+     # fraction of second
            )?
        )?
        (?:
            Z|[\+\-]\d{2}:\d{2} # time zone
        )?
    )?
    $/x };

{
    my $_dt_format = sub {
        my $dt = shift;
        my $datetime = sprintf('%04d-%02d-%02dT%02d:%02d:%02d',
            $dt->year, $dt->month,  $dt->day,
            $dt->hour, $dt->minute, $dt->second
        );
        if ( my $ns = $dt->nanosecond ) {
            $ns =~ s/0+$//;
            $datetime .= ".$ns";
        }
        my $tz = $dt->time_zone;

        return $datetime if $tz->is_floating;
        return $datetime .'Z' if $tz->is_utc;

        if ( DateTime::TimeZone->offset_as_string($dt->offset) =~
            /^([\+\-]\d{2})(\d{2})/ ) {
            return "$datetime$1:$2";
        }
        return $datetime;
    };

    class_type 'DateTime';
    coerce DateTimeW3C,
        from 'DateTime',
            via {
                $_dt_format->($_)
            },
        from Num,
           via {
                $_dt_format->( DateTime->from_epoch(epoch => $_) )
            }
    ;
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

MooseX::Types::DateTime::W3C - W3C DateTime format type constraint

=head1 VERSION

version 1.103360

=head1 SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::Types::DateTime::W3C qw( DateTimeW3C );

    has 'datetime' => (
        is => 'rw',
        isa => DateTimeW3C,
        coerce => 1,
    );


    package main;

    my $obj = My::Class->new();

    # YYYY
    $obj->datetime('1997');

    # YYYY-MM
    $obj->datetime('1997-07');

    # YYYY-MM-DD
    $obj->datetime('1997-07-16');

    # YYYY-MM-DDThh:mmTZD
    $obj->datetime('1997-07-16T19:20');
    $obj->datetime('1997-07-16T19:20Z');
    $obj->datetime('1997-07-16T19:20+01:00');

    # YYYY-MM-DDThh:mm:ssTZD
    $obj->datetime('1997-07-16T19:20:30');
    $obj->datetime('1997-07-16T19:20:30Z');
    $obj->datetime('1997-07-16T19:20:30+01:00');

    # YYYY-MM-DDThh:mm:ss.sTZD
    $obj->datetime('1997-07-16T19:20:30.45');
    $obj->datetime('1997-07-16T19:20:30.45Z');
    $obj->datetime('1997-07-16T19:20:30.45+01:00');


    # coercion from DateTime objects
    use DateTime;

    $obj->datetime(
        DateTime->new(
            year => 1997, month => 7, day => 16,
            hour => 19, minute => 20, second => 30,
            time_zone => 'UTC'
        )
    );
    # same as 1997-07-16T19:20:30Z

    # coercion from Num
    $obj->datetime( time() );


    # exported functions

    # is_DateTimeW3C - validate
    my $w3cdtf_string = '1997-07-16T19:20:30.45Z';
    if ( is_DateTimeW3C($w3cdtf_string) ) { # yes, it is
        ...
    }

    # to_DateTimeW3C - coerce
    $w3cdtf_string = to_DateTimeW3C( DateTime->now );

    $w3cdtf_string = to_DateTimeW3C( time() );

=head1 DESCRIPTION

This class provides W3C date/time format type constraint.

=head1 TYPES

=head2 DateTimeW3C

    has 'datetime' => (
        is => 'rw',
        isa => DateTimeW3C,
        coerce => 1,
    );

C<DateTimeW3C> is a subtype of C<Str> validated against format described at
L<http://www.w3.org/TR/NOTE-datetime>.

Coercion is supported from L<DateTime> objects and numbers (treated as time in
seconds since unix epoch).

    $obj->datetime( DateTime->now );

    $obj->datetime( time() );

Please note that time coerced from C<Num> will be in C<UTC> time zone.

=head1 EXPORTS

In addition to type constraint following functions are exported:

=head2 is_DateTimeW3C

    if ( is_DateTimeW3C($w3cdtf_string) ) {
        ...
    }

Tests if given value is a valid W3C DateTime string.

=head2 to_DateTimeW3C

    # from DateTime object
    $w3cdtf_string = to_DateTimeW3C( DateTime->now );

    # from number
    $w3cdtf_string = to_DateTimeW3C( time() );

Coerce given value into valid W3C DateTime string.

Note: nanoseconds are added only if != 0.

Note: numbers are converted into DateTime objects in UTC time zone.

=head1 SEE ALSO

=over 4

=item *

L<http://www.w3.org/TR/NOTE-datetime>

=item *

L<MooseX::Types>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

