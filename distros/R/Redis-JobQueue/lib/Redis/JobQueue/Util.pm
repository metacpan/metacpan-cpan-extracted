package Redis::JobQueue::Util;

=head1 NAME

Redis::JobQueue::Util - String manipulation utilities.

=head1 VERSION

This documentation refers to C<Redis::JobQueue::Util> version 1.19

=cut

#-- Pragmas --------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

# ENVIRONMENT ------------------------------------------------------------------

our $VERSION = '1.19';

use Exporter qw(
    import
);

our @EXPORT_OK  = qw(
    &format_message
    &format_reference
);

#-- load the modules -----------------------------------------------------------

use overload;
use Carp;
use Data::Dumper ();

#-- declarations ---------------------------------------------------------------

=head1 SYNOPSIS

    use 5.010;
    use strict;
    use warnings;

    use Redis::CappedCollection::Util qw( format_message );
    $string = format_message( 'Object %d loaded. Status: %s', $id, $message );

=head1 DESCRIPTION

String manipulation utilities.

=cut

#-- public functions -----------------------------------------------------------

=head1 EXPORTED FUNCTIONS

Use these functions by importing them into your package or by calling a fully-qualified method name.

=cut

=head2 format_reference

    say format_reference( $object );

Dumps reference using preconfigured L<Data::Dumper>. Produces less verbose
output than default L<Data::Dumper> settings.

=cut

my $dumper;
my $empty_array = [];

sub format_reference {
    my ( $value ) = @_;

    unless( $dumper ) {
        $dumper = Data::Dumper->new( $empty_array )
            ->Indent( 0 )
            ->Terse( 1 )
            ->Quotekeys( 0 )
            ->Sortkeys( 1 )
            ->Useperl( 1 )      # XS version seems to have a bug which sometimes results in modification of original object
#            ->Sparseseen( 1 )   # speed up since we don't use "Seen" hash
        ;
    }

    my $r;
    if (
            overload::Overloaded( $value ) &&
            overload::Method( $value, '""' )
        ) {
        $r = "$value";  # force stringification
    } else {
        $r = $dumper->Values( [ $value ] )->Dump;
        $dumper->Reset->Values( $empty_array );
    }

    return $r;
}

=head2 format_message

    $string = format_message( 'Object %d loaded. Status: %s', $id, $message );

Returns string formatted using printf-style syntax.

If there are more than one argument and the first argument contains C<%...>
conversions, arguments are converted to a string message using C<sprintf()>. In this case, undefined
values are printed as C<< <undef> >> and references are converted to strings using L</format_reference>.

=cut
sub format_message {
    my $format = shift // return;

    my $got = scalar @_;

    return $format unless $got && $format =~ /\%/;

    my $expected = 0;
    while ( $format =~ /(%%|%[^%])/g ) {
        next if $1 eq '%%'; # don't count escape sequence
        ++$expected;
    }

    Carp::cluck "Wrong number of arguments: $expected vs $got" unless $got == $expected;

    return sprintf $format, map {
        !defined $_
            ? '<undef>'
            : ref $_
                ? format_reference( $_ )
                : $_
    } @_;
}

#-- private functions ----------------------------------------------------------

1;

__END__

=head1 SEE ALSO

The basic operation of the L<Redis::JobQueue|Redis::JobQueue> package modules:

L<Redis::JobQueue|Redis::JobQueue> - Object interface for creating and
executing jobs queues, as well as monitoring the status and results of jobs.

L<Redis::JobQueue::Job|Redis::JobQueue::Job> - Object interface for creating
and manipulating jobs.

L<Redis::JobQueue::Util|Redis::JobQueue::Util> - String manipulation utilities.

L<Redis|Redis> - Perl binding for Redis database.

=head1 SOURCE CODE

Redis::JobQueue is hosted on GitHub:
L<https://github.com/TrackingSoft/Redis-JobQueue>

=head1 AUTHOR

Sergey Gladkov, E<lt>sgladkov@trackingsoft.comE<gt>

Please use GitHub project link above to report problems or contact authors.

=head1 CONTRIBUTORS

Alexander Solovey

Jeremy Jordan

Vlad Marchenko

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by TrackingSoft LLC.

This package is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See I<perlartistic> at
L<http://dev.perl.org/licenses/artistic.html>.

This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
