##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Rating.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/25
## Modified 2023/09/26
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This module file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
package Net::API::CPAN::Rating;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{author}       = undef unless( CORE::exists( $self->{author} ) );
    $self->{date}         = undef unless( CORE::exists( $self->{date} ) );
    $self->{details}      = undef unless( CORE::exists( $self->{details} ) );
    $self->{distribution} = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{helpful}      = [] unless( CORE::exists( $self->{helpful} ) );
    $self->{object}       = 'rating';
    $self->{rating}       = undef unless( CORE::exists( $self->{rating} ) );
    $self->{release}      = undef unless( CORE::exists( $self->{release} ) );
    $self->{user}         = undef unless( CORE::exists( $self->{user} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        author date details distribution helpful rating release user
    )];
    return( $self );
}

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub details { return( shift->_set_get_class( 'details', {
    description => { type => "scalar" },
}, @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub helpful { return( shift->_set_get_class_array_object( 'helpful', { user => "scalar_as_object", value => "boolean" }, @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub rating { return( shift->_set_get_number( 'rating', @_ ) ); }

sub release { return( shift->_set_get_scalar_as_object( 'release', @_ ) ); }

sub user { return( shift->_set_get_scalar_as_object( 'user', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Rating - Meta CPAN API Rating Class

=head1 SYNOPSIS

    use Net::API::CPAN::Rating;
    my $obj = Net::API::CPAN::Rating->new( {
      author => "PLACEHOLDER",
      date => "2018-05-31T09:20:07",
      distribution => "Japan-Folklore",
      rating => "5.0",
      release => "PLACEHOLDER",
      user => "CPANRatings",
    } ) || die( Net::API::CPAN::Rating->error );
    
    my $string = $obj->author;
    my $date = $obj->date;
    my $this = $obj->details;
    my $description_obj = $obj->details->description;
    my $string = $obj->distribution;
    my $array = $obj->helpful;
    foreach my $this ( @$array )
    {
        my $scalar = $this->user;
        my $boolean = $this->value;
    }
    my $str = $obj->object;
    my $num = $obj->rating;
    my $string = $obj->release;
    my $string = $obj->user;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate ratings.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Rating> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 author

    $obj->author( "PLACEHOLDER" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 date

    $obj->date( "2018-05-31T09:20:07" );
    my $datetime_obj = $obj->date;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 details

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Rating::Details> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<description> string (L<scalar object|Module::Generic::Scalar>)

=back

=head2 distribution

    $obj->distribution( "Japan-Folklore" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 helpful

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Rating::Helpful> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Rating::Helpful> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<user> scalar_as_object

=item * C<value> boolean (L<boolean object|Module::Generic::Boolean>)

=back

=head2 object

Returns the object type for this class, which is C<rating>

=head2 rating

    $obj->rating("5.0");
    my $number = $obj->rating;

Sets or gets a float value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head2 release

    $obj->release( "PLACEHOLDER" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 user

    $obj->user( "CPANRatings" );
    my $string = $obj->user;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
       "rating" : "5.0",
       "user" : "CPANRatings",
       "distribution" : "Japan-Folklore",
       "release" : "PLACEHOLDER",
       "date" : "2018-05-31T09:20:07",
       "author" : "PLACEHOLDER"
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN>, L<Net::API::CPAN::Activity>, L<Net::API::CPAN::Author>, L<Net::API::CPAN::Changes>, L<Net::API::CPAN::Changes::Release>, L<Net::API::CPAN::Contributor>, L<Net::API::CPAN::Cover>, L<Net::API::CPAN::Diff>, L<Net::API::CPAN::Distribution>, L<Net::API::CPAN::DownloadUrl>, L<Net::API::CPAN::Favorite>, L<Net::API::CPAN::File>, L<Net::API::CPAN::Module>, L<Net::API::CPAN::Package>, L<Net::API::CPAN::Permission>, L<Net::API::CPAN::Rating>, L<Net::API::CPAN::Release>

L<MetaCPAN::API>, L<MetaCPAN::Client>

L<https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

