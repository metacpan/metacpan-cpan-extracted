##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Mirror.pm
## Version v0.1.0
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
package Net::API::CPAN::Mirror;
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
    $self->{A_or_CNAME} = undef unless( CORE::exists( $self->{A_or_CNAME} ) );
    $self->{aka_name}   = undef unless( CORE::exists( $self->{aka_name} ) );
    $self->{ccode}      = undef unless( CORE::exists( $self->{ccode} ) );
    $self->{city}       = undef unless( CORE::exists( $self->{city} ) );
    $self->{contact}    = [] unless( CORE::exists( $self->{contact} ) );
    $self->{continent}  = undef unless( CORE::exists( $self->{continent} ) );
    $self->{country}    = undef unless( CORE::exists( $self->{country} ) );
    $self->{distance}   = undef unless( CORE::exists( $self->{distance} ) );
    $self->{dnsrr}      = undef unless( CORE::exists( $self->{dnsrr} ) );
    $self->{freq}       = undef unless( CORE::exists( $self->{freq} ) );
    $self->{ftp}        = undef unless( CORE::exists( $self->{ftp} ) );
    $self->{http}       = undef unless( CORE::exists( $self->{http} ) );
    $self->{inceptdate} = undef unless( CORE::exists( $self->{inceptdate} ) );
    $self->{location}   = [] unless( CORE::exists( $self->{location} ) );
    $self->{name}       = undef unless( CORE::exists( $self->{name} ) );
    $self->{note}       = undef unless( CORE::exists( $self->{note} ) );
    $self->{object}     = 'mirror';
    $self->{org}        = undef unless( CORE::exists( $self->{org} ) );
    $self->{region}     = undef unless( CORE::exists( $self->{region} ) );
    $self->{reitredate} = undef unless( CORE::exists( $self->{reitredate} ) );
    $self->{rsync}      = undef unless( CORE::exists( $self->{rsync} ) );
    $self->{src}        = undef unless( CORE::exists( $self->{src} ) );
    $self->{tz}         = undef unless( CORE::exists( $self->{tz} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        A_or_CNAME aka_name ccode city contact continent country distance dnsrr freq ftp
        http inceptdate location name note org region reitredate rsync src tz
    )];
    return( $self );
}

sub A_or_CNAME { return( shift->_set_get_scalar_as_object( 'A_or_CNAME', @_ ) ); }

sub aka_name { return( shift->_set_get_scalar_as_object( 'aka_name', @_ ) ); }

sub ccode { return( shift->_set_get_scalar_as_object( 'ccode', @_ ) ); }

sub city { return( shift->_set_get_scalar_as_object( 'city', @_ ) ); }

sub contact { return( shift->_set_get_class_array_object( 'contact', {
    contact_site => "scalar_as_object",
    contact_user => "scalar_as_object",
}, @_ ) ); }

sub continent { return( shift->_set_get_scalar_as_object( 'continent', @_ ) ); }

sub country { return( shift->_set_get_scalar_as_object( 'country', @_ ) ); }

sub distance { return( shift->_set_get_scalar_as_object( 'distance', @_ ) ); }

sub dnsrr { return( shift->_set_get_scalar_as_object( 'dnsrr', @_ ) ); }

sub freq { return( shift->_set_get_scalar_as_object( 'freq', @_ ) ); }

sub ftp { return( shift->_set_get_uri( 'ftp', @_ ) ); }

sub http { return( shift->_set_get_uri( 'http', @_ ) ); }

sub inceptdate { return( shift->_set_get_datetime( 'inceptdate', @_ ) ); }

sub location { return( shift->_set_get_array_as_object( 'location', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub note { return( shift->_set_get_scalar_as_object( 'note', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub org { return( shift->_set_get_scalar_as_object( 'org', @_ ) ); }

sub region { return( shift->_set_get_scalar_as_object( 'region', @_ ) ); }

sub reitredate { return( shift->_set_get_datetime( 'reitredate', @_ ) ); }

sub rsync { return( shift->_set_get_uri( 'rsync', @_ ) ); }

sub src { return( shift->_set_get_uri( 'src', @_ ) ); }

sub tz { return( shift->_set_get_scalar_as_object( 'tz', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Mirror - Meta CPAN API Mirror Class

=head1 SYNOPSIS

    use Net::API::CPAN::Mirror;
    my $obj = Net::API::CPAN::Mirror->new( {
      ccode => "zz",
      city => "Everywhere",
      contact => [
        {
          contact_site => "perl.org",
          contact_user => "cpan",
        },
      ],
      continent => "Global",
      country => "Global",
      distance => undef,
      dnsrr => "N",
      freq => "instant",
      http => "http://www.cpan.org/",
      inceptdate => "2021-04-09T00:00:00",
      location => [
        0,
        0,
      ],
      name => "www.cpan.org",
      org => "Global CPAN CDN",
      src => "rsync://cpan-rsync.perl.org/CPAN/",
      tz => 0,
    } ) || die( Net::API::CPAN::Mirror->error );
    
    my $string = $obj->A_or_CNAME;
    my $string = $obj->aka_name;
    my $string = $obj->ccode;
    my $string = $obj->city;
    my $array = $obj->contact;
    foreach my $this ( @$array )
    {
        my $scalar = $this->contact_site;
        my $scalar = $this->contact_user;
    }
    my $string = $obj->continent;
    my $string = $obj->country;
    my $string = $obj->distance;
    my $string = $obj->dnsrr;
    my $string = $obj->freq;
    my $uri = $obj->ftp;
    my $uri = $obj->http;
    my $date = $obj->inceptdate;
    my $array = $obj->location;
    my $string = $obj->name;
    my $string = $obj->note;
    my $str = $obj->object;
    my $string = $obj->org;
    my $string = $obj->region;
    my $date = $obj->reitredate;
    my $uri = $obj->rsync;
    my $uri = $obj->src;
    my $string = $obj->tz;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate mirrors.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Mirror> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 A_or_CNAME

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 aka_name

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 ccode

    $obj->ccode( "zz" );
    my $string = $obj->ccode;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 city

    $obj->city( "Everywhere" );
    my $string = $obj->city;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 contact

    $obj->contact( [
      {
        contact_site => "perl.org",
        contact_user => "cpan",
      },
    ] );
    my $array = $obj->contact;
    foreach my $this ( @$array )
    {
        $this->contact_site( "perl.org" );
        my $scalar = $this->contact_site;
        $this->contact_user( "cpan" );
        my $scalar = $this->contact_user;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Mirror::Contact> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Mirror::Contact> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<contact_site> scalar_as_object

=item * C<contact_user> scalar_as_object

=back

=head2 continent

    $obj->continent( "Global" );
    my $string = $obj->continent;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 country

    $obj->country( "Global" );
    my $string = $obj->country;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 distance

    $obj->distance( undef );
    my $string = $obj->distance;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 dnsrr

    $obj->dnsrr( "N" );
    my $string = $obj->dnsrr;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 freq

    $obj->freq( "instant" );
    my $string = $obj->freq;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 ftp

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 http

    $obj->http( "http://www.cpan.org/" );
    my $uri = $obj->http;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 inceptdate

    $obj->inceptdate( "2021-04-09T00:00:00" );
    my $datetime_obj = $obj->inceptdate;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 location

    $obj->location( [
      0,
      0,
    ] );
    my $array = $obj->location;

Sets or gets an array of locations and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 name

    $obj->name( "www.cpan.org" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 note

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<mirror>

=head2 org

    $obj->org( "Global CPAN CDN" );
    my $string = $obj->org;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 region

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 reitredate

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 rsync

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 src

    $obj->src( "rsync://cpan-rsync.perl.org/CPAN/" );
    my $uri = $obj->src;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 tz

    $obj->tz( 0 );
    my $string = $obj->tz;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
       "ccode" : "zz",
       "city" : "Everywhere",
       "contact" : [
          {
             "contact_site" : "perl.org",
             "contact_user" : "cpan"
          }
       ],
       "continent" : "Global",
       "country" : "Global",
       "distance" : null,
       "dnsrr" : "N",
       "freq" : "instant",
       "http" : "http://www.cpan.org/",
       "inceptdate" : "2021-04-09T00:00:00",
       "location" : [
          0,
          0
       ],
       "name" : "www.cpan.org",
       "org" : "Global CPAN CDN",
       "src" : "rsync://cpan-rsync.perl.org/CPAN/",
       "tz" : "0"
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

