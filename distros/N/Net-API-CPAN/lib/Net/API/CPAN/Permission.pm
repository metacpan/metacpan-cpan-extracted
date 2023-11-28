##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Permission.pm
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
package Net::API::CPAN::Permission;
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
    $self->{co_maintainers} = [] unless( CORE::exists( $self->{co_maintainers} ) );
    $self->{module_name}    = undef unless( CORE::exists( $self->{module_name} ) );
    $self->{object}         = 'permission';
    $self->{owner}          = undef unless( CORE::exists( $self->{owner} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( co_maintainers module_name owner )];
    return( $self );
}

sub co_maintainers { return( shift->_set_get_array_as_object( 'co_maintainers', @_ ) ); }

sub module_name { return( shift->_set_get_scalar_as_object( 'module_name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub owner { return( shift->_set_get_scalar_as_object( 'owner', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Permission - Meta CPAN API Permission Class

=head1 SYNOPSIS

    use Net::API::CPAN::Permission;
    my $obj = Net::API::CPAN::Permission->new( {
      co_maintainers => [
        "URASHIMATARO",
        "KINTARO",
        "YAMATONADESHIKO",
      ],
      module_name => "Folklore::Japan",
      owner => "MOMOTARO",
    } ) || die( Net::API::CPAN::Permission->error );
    
    my $array = $obj->co_maintainers;
    my $string = $obj->module_name;
    my $str = $obj->object;
    my $string = $obj->owner;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate permissions.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Permission> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 co_maintainers

    $obj->co_maintainers( [
      "URASHIMATARO",
      "KINTARO",
      "YAMATONADESHIKO",
    ] );
    my $array = $obj->co_maintainers;

Sets or gets an array of co_maintainers and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 module_name

    $obj->module_name( "Folklore::Japan" );
    my $string = $obj->module_name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<permission>

=head2 owner

    $obj->owner( "MOMOTARO" );
    my $string = $obj->owner;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
       "co_maintainers" : [
          "URASHIMATARO",
          "KINTARO",
          "YAMATONADESHIKO"
       ],
       "module_name" : "Folklore::Japan",
       "owner" : "MOMOTARO"
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

