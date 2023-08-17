package Slick::Util;

use 5.036;

use Sub::Util qw(set_subname);

# Generate a 4 digit number for request tracing
sub four_digit_number {
    my @chars = ( 1 .. 9 );

    my $n = '';
    for ( 1 .. 4 ) {
        $n .= $chars[ int rand @chars ];
    }

    return $n;
}

## no critic qw(TestingAndDebugging::ProhibitNoStrict TestingAndDebugging::ProhibitNoWarnings Subroutines::RequireFinalReturn)
sub monkey_patch {

# Credits to: https://github.com/mojolicious/mojo/blob/1343054b7f5c3e8c70c073e28c7ac65ab4008723/lib/Mojo/Util.pm#L200C1-L206C2

    my ( $class, %patch ) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = set_subname( "${class}::$_", $patch{$_} )
      for keys %patch;
}

1;

=encoding utf8

=head1 NAME

Slick::EventHandler

=head1 SYNOPSIS

A utility module that provides a few small useful tid-bits.

=head1 API

=head2 four_digit_number

A method that returns a four-digit number.

=head2 monkey_patch

Patches a sub-routine onto a package as a method.

=over2

=item * L<Slick>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
