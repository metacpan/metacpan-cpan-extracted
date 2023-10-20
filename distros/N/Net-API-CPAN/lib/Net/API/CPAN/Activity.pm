##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Activity.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/09/12
## Modified 2023/09/12
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Activity;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Generic );
    use vars qw( $VERSION );
    use DateTime;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{activity} = [] unless( exists( $self->{activity} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub activity
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $data = shift( @_ );
        my $months;
        if( $self->_is_array( $data ) )
        {
            $months = $data;
        }
        elsif( ref( $data ) eq 'HASH' &&
            exists( $data->{activity} ) &&
            $self->_is_array( $data->{activity} ) )
        {
            $months = $data->{activity};
        }
        
        if( !defined( $months ) )
        {
            return( $self->error( "No data was provided. I was expecting either an array of integers, or an hash with a 'activity' property pointing to that array of integers." ) );
        }
        elsif( scalar( @$months ) != 24 )
        {
            warn( "The data provided contains ", scalar( @$months ), " elements versus the 24 that were expected." ) if( $self->_is_warnings_enabled( 'Net::API::CPAN' ) );
        }
        # A copy from MetaCPAN::Query::Release->activity()
        # <https://github.com/metacpan/metacpan-api/blob/db7c3a90925ec85e6ae6a9f6dd64677305feac8d/lib/MetaCPAN/Query/Release.pm#L303>
        my $start = DateTime->now->truncate( to => 'month' )->subtract( months => 23 );
        # from the furthest to most recent month
        # 0 being the start, and 23 being our current month
        my $a = $self->new_array;
        my $hash = $self->new_hash;
        # Allow reference as hash keys
        $hash->key_object(1);
        for( 0..23 )
        {
            my $dt = $start->clone->add( months => $_ );
            $a->push({ dt => $dt, value => $months->[$_] });
            $hash->{ $dt } = $months->[$_];
        }
        $self->{activity} = $a;
        $self->{activities} = $hash;
    }
    return( $self->_set_get_array_as_object( 'activity' ) );
}

sub activities { return( shift->_set_get_hash_as_mix_object( 'activities', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Activity - Meta CPAN API

=head1 SYNOPSIS

    use Net::API::CPAN::Activity;
    my $obj = Net::API::CPAN::Activity->new(
        activity => [8, 6, 6, 8, 9, 3, 7, 15, 4, 7, 4, 7, 13, 3, 1, 1, 4, 1, 1, 2, 4, 3, 4, 1]
    ) || die( Net::API::CPAN::Activity->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represent a release activity.

=head1 CONSTRUCTOR

=head2 new

This instantiates a new C<Net::API::CPAN::Activity> object and returns it. It takes the following arguments:

=over 4

=item * C<activity>

An array reference of 24 integer.

Upon providing those data, this will create an hash of 24 L<DateTime> objects representing each of the month from 23 months ago until the current month. This hash can be accessed with L<activities|/activities>

=back

=head1 METHODS

=head2 activity

    $obj->activity( [8, 6, 6, 8, 9, 3, 7, 15, 4, 7, 4, 7, 13, 3, 1, 1, 4, 1, 1, 2, 4, 3, 4, 1] ) ||
        die( $obj->error );
    my $array = $obj->activity;

As a mutator, this takes an array reference of 24 integers, each representing the aggregate number of release for the interval that was specified when making the API query.

Upon setting those data, this will create an hash of 24 L<DateTime> objects representing each of the month from 23 months ago until the current month. This hash can be accessed with L<activities|/activities>

It returns an L<array object|Module::Generic::Array> of hash references having the keys C<dt> for the L<DateTime> object and C<value> for the integer representing the aggregate value.

    my $array = $obj->activity;
    foreach my $hash ( @$array )
    {
        say "Date: ", $hash->{dt}, ", value: ", $hash->{value};
    }

=head2 activities

Sets or get the hash or key-value pairs of L<DateTime> object to aggregate value.

You could do then something like:

    my $ref = $obj->activities;
    foreach my $dt ( sort( keys( %$ref ) ) )
    {
        say $dt, ": ", $ref->{ $dt };
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN>, L<Net::API::CPAN::Author>, L<Net::API::CPAN::Changes>, L<Net::API::CPAN::Changes::Release>, L<Net::API::CPAN::Contributor>, L<Net::API::CPAN::Cover>, L<Net::API::CPAN::Diff>, L<Net::API::CPAN::Distribution>, L<Net::API::CPAN::DownloadUrl>, L<Net::API::CPAN::Favorite>, L<Net::API::CPAN::File>, L<Net::API::CPAN::Module>, L<Net::API::CPAN::Package>, L<Net::API::CPAN::Permission>, L<Net::API::CPAN::Rating>, L<Net::API::CPAN::Release>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
