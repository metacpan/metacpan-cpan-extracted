##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Release/Suggest.pm
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
package Net::API::CPAN::Release::Suggest;
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
    $self->{deprecated}   = undef unless( CORE::exists( $self->{deprecated} ) );
    $self->{distribution} = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{name}         = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}       = 'suggest';
    $self->{release}      = undef unless( CORE::exists( $self->{release} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( author date deprecated distribution name release )];
    return( $self );
}

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub deprecated { return( shift->_set_get_boolean( 'deprecated', @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub release { return( shift->_set_get_scalar_as_object( 'release', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Release::Suggest - Meta CPAN API Release::Suggest Class

=head1 SYNOPSIS

    use Net::API::CPAN::Release::Suggest;
    my $obj = Net::API::CPAN::Release::Suggest->new( {
      author => "MOMOTARO",
      date => "2023-09-01T10:12:42",
      deprecated => \0,
      distribution => "Japan-Folklore",
      name => "Japan::Folklore",
      release => "Japan-Folklore-v1.2.3",
    } ) || die( Net::API::CPAN::Release::Suggest->error );
    
    my $string = $obj->author;
    my $date = $obj->date;
    my $bool = $obj->deprecated;
    my $string = $obj->distribution;
    my $string = $obj->name;
    my $str = $obj->object;
    my $string = $obj->release;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate suggests.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Release::Suggest> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 date

    $obj->date( "2023-09-01T10:12:42" );
    my $datetime_obj = $obj->date;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 deprecated

    $obj->deprecated(1);
    my $bool = $obj->deprecated;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 distribution

    $obj->distribution( "Japan-Folklore" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 name

    $obj->name( "Japan::Folklore" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<suggest>

=head2 release

    $obj->release( "Japan-Folklore-v1.2.3" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
        "author" : "MOMOTARO",
        "name" : "Japan::Folklore",
        "deprecated" : false,
        "distribution" : "Japan-Folklore",
        "date" : "2023-09-01T10:12:42",
        "release" : "Japan-Folklore-v1.2.3"
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

