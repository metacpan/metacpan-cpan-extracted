##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Package.pm
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
package Net::API::CPAN::Package;
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
    $self->{dist_version} = undef unless( CORE::exists( $self->{dist_version} ) );
    $self->{distribution} = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{file}         = undef unless( CORE::exists( $self->{file} ) );
    $self->{module_name}  = undef unless( CORE::exists( $self->{module_name} ) );
    $self->{object}       = 'package';
    $self->{version}      = '' unless( CORE::exists( $self->{version} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        author dist_version distribution file module_name version
    )];
    return( $self );
}

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub dist_version { return( shift->_set_get_version( { class => "Changes::Version", field => "dist_version" }, @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub file { return( shift->_set_get_scalar_as_object( 'file', @_ ) ); }

sub module_name { return( shift->_set_get_scalar_as_object( 'module_name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub version { return( shift->_set_get_number( { field => "version", undef_ok => 1 }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Package - Meta CPAN API Package Class

=head1 SYNOPSIS

    use Net::API::CPAN::Package;
    my $obj = Net::API::CPAN::Package->new( {
      author => "MOMOTARO",
      dist_version => "v1.2.3",
      distribution => "Folklore-Japan",
      file => "M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
      module_name => "Folklore::Japan",
      version => "1.002003",
    } ) || die( Net::API::CPAN::Package->error );
    
    my $string = $obj->author;
    my $vers = $obj->dist_version;
    my $string = $obj->distribution;
    my $string = $obj->file;
    my $string = $obj->module_name;
    my $str = $obj->object;
    my $num = $obj->version;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate packages.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Package> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 dist_version

    $obj->dist_version( "v1.2.3" );
    my $version = $obj->dist_version;

Sets or gets a version value and returns a version object using L<Changes::Version>.

=head2 distribution

    $obj->distribution( "Folklore-Japan" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 file

    $obj->file( "M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz" );
    my $string = $obj->file;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 module_name

    $obj->module_name( "Folklore::Japan" );
    my $string = $obj->module_name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<package>

=head2 version

    $obj->version("1.002003");
    my $number = $obj->version;

Sets or gets a float value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

Please note that this represents the numified version of the module version number. In other object classes, the property C<version_numified> is used instead. For the L<version object|Changes::Version> of the module, see L</dist_version>

=head1 API SAMPLE

    {
       "distribution" : "Folklore-Japan",
       "author" : "MOMOTARO",
       "version" : "1.002003",
       "dist_version" : "v1.2.3",
       "file" : "M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
       "module_name" : "Folklore::Japan"
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

