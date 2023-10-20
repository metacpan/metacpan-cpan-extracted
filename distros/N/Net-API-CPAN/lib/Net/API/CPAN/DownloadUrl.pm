##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/DownloadUrl.pm
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
package Net::API::CPAN::DownloadUrl;
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
    $self->{checksum_md5}    = undef unless( CORE::exists( $self->{checksum_md5} ) );
    $self->{checksum_sha256} = undef unless( CORE::exists( $self->{checksum_sha256} ) );
    $self->{date}            = undef unless( CORE::exists( $self->{date} ) );
    $self->{download_url}    = undef unless( CORE::exists( $self->{download_url} ) );
    $self->{object}          = 'download_url';
    $self->{release}         = undef unless( CORE::exists( $self->{release} ) );
    $self->{status}          = undef unless( CORE::exists( $self->{status} ) );
    $self->{version}         = '' unless( CORE::exists( $self->{version} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        checksum_md5 checksum_sha256 date download_url release status version
    )];
    return( $self );
}

sub checksum_md5 { return( shift->_set_get_scalar_as_object( 'checksum_md5', @_ ) ); }

sub checksum_sha256 { return( shift->_set_get_scalar_as_object( 'checksum_sha256', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub download_url { return( shift->_set_get_uri( 'download_url', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub release { return( shift->_set_get_scalar_as_object( 'release', @_ ) ); }

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

sub version { return( shift->_set_get_version( { class => "Changes::Version", field => "version" }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::DownloadUrl - Meta CPAN API DownloadUrl Class

=head1 SYNOPSIS

    use Net::API::CPAN::DownloadUrl;
    my $obj = Net::API::CPAN::DownloadUrl->new( {
      checksum_md5 => "71682907d95a4b0a4b74da8c16e88d2d",
      checksum_sha256 => "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
      date => "2023-07-29T05:10:12",
      download_url => "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
      release => "Folklore-Japan-v1.2.3",
      status => "latest",
      version => "v1.2.3",
    } ) || die( Net::API::CPAN::DownloadUrl->error );
    
    my $string = $obj->checksum_md5;
    my $string = $obj->checksum_sha256;
    my $date = $obj->date;
    my $uri = $obj->download_url;
    my $str = $obj->object;
    my $string = $obj->release;
    my $string = $obj->status;
    my $vers = $obj->version;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate download_urls.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::DownloadUrl> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 checksum_md5

    $obj->checksum_md5( "71682907d95a4b0a4b74da8c16e88d2d" );
    my $string = $obj->checksum_md5;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 checksum_sha256

    $obj->checksum_sha256( "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d" );
    my $string = $obj->checksum_sha256;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 date

    $obj->date( "2023-07-29T05:10:12" );
    my $datetime_obj = $obj->date;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 download_url

    $obj->download_url( "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz" );
    my $uri = $obj->download_url;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 object

Returns the object type for this class, which is C<download_url>

=head2 release

    $obj->release( "Folklore-Japan-v1.2.3" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 status

    $obj->status( "latest" );
    my $string = $obj->status;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 version

    $obj->version( "v1.2.3" );
    my $version = $obj->version;

Sets or gets a version value and returns a version object using L<Changes::Version>.

=head1 API SAMPLE

    {
       "checksum_md5" : "71682907d95a4b0a4b74da8c16e88d2d",
       "checksum_sha256" : "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
       "date" : "2023-07-29T05:10:12",
       "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
       "release" : "Folklore-Japan-v1.2.3",
       "status" : "latest",
       "version" : "v1.2.3",
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

