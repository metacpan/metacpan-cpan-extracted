##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Contributor.pm
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
package Net::API::CPAN::Contributor;
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
    $self->{distribution}   = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{object}         = 'contributor';
    $self->{pauseid}        = undef unless( CORE::exists( $self->{pauseid} ) );
    $self->{release_author} = undef unless( CORE::exists( $self->{release_author} ) );
    $self->{release_name}   = undef unless( CORE::exists( $self->{release_name} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( distribution pauseid release_author release_name )];
    return( $self );
}

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub pauseid { return( shift->_set_get_scalar_as_object( 'pauseid', @_ ) ); }

sub release_author { return( shift->_set_get_scalar_as_object( 'release_author', @_ ) ); }

sub release_name { return( shift->_set_get_scalar_as_object( 'release_name', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Contributor - Meta CPAN API Contributor Class

=head1 SYNOPSIS

    use Net::API::CPAN::Contributor;
    my $string = $obj->distribution;
    my $str = $obj->object;
    my $string = $obj->pauseid;
    my $string = $obj->release_author;
    my $string = $obj->release_name;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate contributors.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Contributor> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 distribution

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<contributor>

=head2 pauseid

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 release_author

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 release_name

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

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

