##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Changes/Release.pm
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
package Net::API::CPAN::Changes::Release;
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
    $self->{changes_file} = undef unless( CORE::exists( $self->{changes_file} ) );
    $self->{changes_text} = undef unless( CORE::exists( $self->{changes_text} ) );
    $self->{object}       = 'changes_release';
    $self->{release}      = undef unless( CORE::exists( $self->{release} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( author changes_file changes_text release )];
    return( $self );
}

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub changes_file { return( shift->_set_get_scalar_as_object( 'changes_file', @_ ) ); }

sub changes_text { return( shift->_set_get_scalar_as_object( 'changes_text', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub release { return( shift->_set_get_scalar_as_object( 'release', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Changes::Release - Meta CPAN API Changes::Release Class

=head1 SYNOPSIS

    use Net::API::CPAN::Changes::Release;
    my $obj = Net::API::CPAN::Changes::Release->new( {
      author => "MOMOTARO",
      changes_file => "CHANGES",
      changes_text => "Revision history for Perl module Folklore::Japan\n\nv1.2.3 2023-07-29T09:12:10+0900\n    - Initial release\n",
      release => "Folklore-Japan-v1.2.3",
    } ) || die( Net::API::CPAN::Changes::Release->error );
    
    my $string = $obj->author;
    my $string = $obj->changes_file;
    my $string = $obj->changes_text;
    my $str = $obj->object;
    my $string = $obj->release;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate changes_releases.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Changes::Release> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 changes_file

    $obj->changes_file( "CHANGES" );
    my $string = $obj->changes_file;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 changes_text

    $obj->changes_text( "Revision history for Perl module Folklore::Japan\n\nv1.2.3 2023-07-29T09:12:10+0900\n    - Initial release\n" );
    my $string = $obj->changes_text;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<changes_release>

=head2 release

    $obj->release( "Folklore-Japan-v1.2.3" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
        "author" : "MOMOTARO",
        "changes_file" : "CHANGES",
        "changes_text" : "Revision history for Perl module Folklore::Japan\n\nv1.2.3 2023-07-29T09:12:10+0900\n    - Initial release\n",
        "release" : "Folklore-Japan-v1.2.3"
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

