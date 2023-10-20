##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Cve.pm
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
package Net::API::CPAN::Cve;
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
    $self->{affected_versions} = undef unless( CORE::exists( $self->{affected_versions} ) );
    $self->{cpansa_id}         = undef unless( CORE::exists( $self->{cpansa_id} ) );
    $self->{cves}              = undef unless( CORE::exists( $self->{cves} ) );
    $self->{description}       = undef unless( CORE::exists( $self->{description} ) );
    $self->{distribution}      = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{object}            = 'cve';
    $self->{references}        = undef unless( CORE::exists( $self->{references} ) );
    $self->{releases}          = undef unless( CORE::exists( $self->{releases} ) );
    $self->{reported}          = undef unless( CORE::exists( $self->{reported} ) );
    $self->{severity}          = undef unless( CORE::exists( $self->{severity} ) );
    $self->{versions}          = undef unless( CORE::exists( $self->{versions} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        affected_versions cpansa_id cves description distribution references releases
        reported severity versions
    )];
    return( $self );
}

sub affected_versions { return( shift->_set_get_scalar_as_object( 'affected_versions', @_ ) ); }

sub cpansa_id { return( shift->_set_get_scalar_as_object( 'cpansa_id', @_ ) ); }

sub cves { return( shift->_set_get_scalar_as_object( 'cves', @_ ) ); }

sub description { return( shift->_set_get_scalar_as_object( 'description', @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub references { return( shift->_set_get_scalar_as_object( 'references', @_ ) ); }

sub releases { return( shift->_set_get_scalar_as_object( 'releases', @_ ) ); }

sub reported { return( shift->_set_get_datetime( 'reported', @_ ) ); }

sub severity { return( shift->_set_get_scalar_as_object( 'severity', @_ ) ); }

sub versions { return( shift->_set_get_scalar_as_object( 'versions', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Cve - Meta CPAN API Cve Class

=head1 SYNOPSIS

    use Net::API::CPAN::Cve;
    my $string = $obj->affected_versions;
    my $string = $obj->cpansa_id;
    my $string = $obj->cves;
    my $string = $obj->description;
    my $string = $obj->distribution;
    my $str = $obj->object;
    my $string = $obj->references;
    my $string = $obj->releases;
    my $date = $obj->reported;
    my $string = $obj->severity;
    my $string = $obj->versions;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate cves.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Cve> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 affected_versions

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 cpansa_id

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 cves

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 description

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 distribution

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<cve>

=head2 references

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 releases

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 reported

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 severity

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 versions

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

