package Parcel::Track::Role::Base;
# ABSTRACT: Parcel::Track base role

use Moo::Role;
use Types::Standard qw( Str );

our $VERSION = '0.005';

has id => (
    is  => 'ro',
    isa => Str,
);

requires 'uri';
requires 'track';

1;

#
# This file is part of Parcel-Track
#
# This software is copyright (c) 2015 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Parcel::Track::Role::Base - Parcel::Track base role

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package Parcel::Track::KR::MyDriver;

    use Moo;

    with 'Parcel::Track::Role::Base';

    sub uri {
        ...
    }

    sub track {
        ...
    }

=head1 DESCRIPTION

The C<Parcel::Track::Role::Base> class provides an abstract base class
for all L<Parcel::Track> driver classes.

At this time it does not provide any implementation code for drivers
(although this may change in the future).
It does serve as something you should sub-class your driver from
to identify it as a L<Parcel::Track> driver.

Please note that if your driver class not B<not> return true for
C<$driver->does('Parcel::Track::Role::Base')> then the L<Parcel::Track>
constructor will refuse to use your class as a driver.

=head1 ATTRIBUTES

=head2 id

Returns tracking number.

=head1 METHODS

=head2 uri

Returns official link to track parcel.

=head2 track

Returns C<HASHREF> which contains information of tracking the parcel.
C<HASHREF> MUST contain following key and value pairs.

=over 4

=item *

C<from>: C<SCALAR>.

=item *

C<to>: C<SCALAR>.

=item *

C<result>: C<SCALAR>.

=item *

C<htmls>: C<ARRAYREF>.

=item *

C<descs>: C<ARRAYREF>.

=back

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
