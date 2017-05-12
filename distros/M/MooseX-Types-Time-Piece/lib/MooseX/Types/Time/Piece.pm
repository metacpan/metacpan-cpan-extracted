package MooseX::Types::Time::Piece;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.10';

use Carp ();
use Time::Piece ();
use Time::Seconds ();
use Try::Tiny;

use MooseX::Types -declare => [qw( Time Duration )];
use MooseX::Types::Moose qw( ArrayRef Num Str );

class_type 'Time::Piece';
class_type 'Time::Seconds';

subtype Time,     as 'Time::Piece';
subtype Duration, as 'Time::Seconds';

my $DEFAULT_FORMAT = '%a, %d %b %Y %H:%M:%S %Z';
my $ISO_FORMAT = '%Y-%m-%dT%H:%M:%S';

for my $type ( 'Time::Piece', Time )
{
    coerce $type,
        from Num, via
        {
            Time::Piece->new($_)
        },
        from Str, via
        {
            my $time = $_;
            return try {
                Time::Piece->strptime( $time, $ISO_FORMAT );
            } catch {
                # error message from strptime does say much
                Carp::confess "Error parsing time '$time' with format '$ISO_FORMAT'";
            };
        },
        from ArrayRef, via
        {
            my @args = @$_;
            return try {
                Time::Piece->strptime(@args);
            } catch {
                $args[1] ||= $DEFAULT_FORMAT; # if only 1 arg
                Carp::confess "Error parsing time '$args[0]' with format '$args[1]'";
            };
        };
}

for my $type ( 'Time::Seconds', Duration )
{
    coerce $type,
        from Num, via { Time::Seconds->new($_) };
}

1;

__END__

=head1 NAME

MooseX::Types::Time::Piece - Time::Piece type and coercions for Moose

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::Types::Time::Piece qw( Time Duration );

    has 'time' => (
        is      => 'rw',
        isa     => Time,
        coerce  => 1,
    );

    has 'duration' => (
        is      => 'rw',
        isa     => Duration,
        coerce  => 1,
    );

    # ...

    my $f = Foo->new;
    $f->time( Time::Piece->new )            # no coercion
    $f->time( time() );                     # coerce from Num
    $f->time( '2012-12-31T23:59:59' );      # coerce from Str
    $f->time( ['2012-12-31', '%Y-%m-%d'] ); # coerce from ArrayRef
    $f->duration( Time::Seconds::ONE_DAY * 2 );

=head1 DESCRIPTION

This module provides L<Moose> type constraints and coercions for using
L<Time::Piece> objects as Moose attributes.

=head1 EXPORTS

The following type constants provided by L<MooseX::Types> must be explicitly
imported. The full class name may also be used (as strings with quotes) without
importing the constant declarations.

=head2 Time

A class type for L<Time::Piece>.

=over

=item coerce from C<Num>

The number is interpreted as the seconds since the system epoch
as accepted by L<localtime()|perlfunc/localtime>.

=item coerce from C<Str>

The string is expected to be in ISO 8601 date/time format,
e.g. C<'2012-12-31T23:59:59'>. See also L<Time::Piece/YYYY-MM-DDThh:mm:ss>.

=item coerce from C<ArrayRef>

The arrayref is expected to contain 2 string values, the time and the time format,
as accepted by L<strptime()|Time::Piece/"Date Parsing">.

=back

An exception is thrown during coercion if the given time does not match the
expected/given format, or the given time or format is invalid.

=head2 Duration

A class type for L<Time::Seconds>.

=over

=item coerce from C<Num>

The number is interpreted as seconds in duration.

=back

=head1 SEE ALSO

L<Time::Piece>, L<MooseX::Types>

=head1 AUTHOR

Steven Lee, C<< <stevenl at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Steven Lee

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
