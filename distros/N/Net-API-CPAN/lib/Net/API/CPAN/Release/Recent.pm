##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Release/Recent.pm
## Version v0.1.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/25
## Modified 2023/11/24
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This module file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
package Net::API::CPAN::Release::Recent;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{abstract}     = undef unless( CORE::exists( $self->{abstract} ) );
    $self->{author}       = undef unless( CORE::exists( $self->{author} ) );
    $self->{date}         = undef unless( CORE::exists( $self->{date} ) );
    $self->{distribution} = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{maturity}     = undef unless( CORE::exists( $self->{maturity} ) );
    $self->{name}         = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}       = 'release_recent';
    $self->{status}       = undef unless( CORE::exists( $self->{status} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        abstract author date distribution maturity name status
    )];
    return( $self );
}

sub abstract { return( shift->_set_get_scalar_as_object( 'abstract', @_ ) ); }

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub maturity { return( shift->_set_get_scalar_as_object( 'maturity', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Release::Recent - Meta CPAN API Release::Recent Class

=head1 SYNOPSIS

    use Net::API::CPAN::Release::Recent;
    my $obj = Net::API::CPAN::Release::Recent->new( {
      abstract => "Japan Folklore Object Class",
      author => "MOMOTARO",
      date => "2023-07-29T05:10:12",
      distribution => "Folklore-Japan",
      maturity => "developer",
      name => "Folklore-Japan-v1.2.3",
      status => "latest",
    } ) || die( Net::API::CPAN::Release::Recent->error );
    
    my $string = $obj->abstract;
    my $string = $obj->author;
    my $date = $obj->date;
    my $string = $obj->distribution;
    my $string = $obj->maturity;
    my $string = $obj->name;
    my $str = $obj->object;
    my $string = $obj->status;

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This class serve to retrieve and manipulate recent releases.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Release::Recent> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 abstract

    $obj->abstract( "Japan Folklore Object Class" );
    my $string = $obj->abstract;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 date

    $obj->date( "2023-07-29T05:10:12" );
    my $datetime_obj = $obj->date;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 distribution

    $obj->distribution( "Folklore-Japan" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 maturity

    $obj->maturity( "developer" );
    my $string = $obj->maturity;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 name

    $obj->name( "Folklore-Japan-v1.2.3" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<release_recent>

=head2 status

    $obj->status( "latest" );
    my $string = $obj->status;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
        "abstract" : "Japan Folklore Object Class",
        "author" : "MOMOTARO",
        "date" : "2023-07-29T05:10:12",
        "distribution" : "Folklore-Japan",
        "maturity" : "developer",
        "name" : "Folklore-Japan-v1.2.3",
        "status" : "latest"
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

