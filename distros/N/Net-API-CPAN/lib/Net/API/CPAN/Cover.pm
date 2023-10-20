##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Cover.pm
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
package Net::API::CPAN::Cover;
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
    $self->{criteria}     = undef unless( CORE::exists( $self->{criteria} ) );
    $self->{distribution} = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{object}       = 'cover';
    $self->{release}      = undef unless( CORE::exists( $self->{release} ) );
    $self->{url}          = undef unless( CORE::exists( $self->{url} ) );
    $self->{version}      = '' unless( CORE::exists( $self->{version} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( criteria distribution release url version )];
    return( $self );
}

sub criteria { return( shift->_set_get_class( 'criteria', {
    branch => "float",
    condition => "float",
    statement => "float",
    subroutine => "float",
    total => "float",
}, @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub release { return( shift->_set_get_scalar_as_object( 'release', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

sub version { return( shift->_set_get_version( { class => "Changes::Version", field => "version" }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Cover - Meta CPAN API Cover Class

=head1 SYNOPSIS

    use Net::API::CPAN::Cover;
    my $obj = Net::API::CPAN::Cover->new( {
      criteria => {
        branch => "54.68",
        condition => "57.56",
        statement => "78.14",
        subroutine => "80.00",
        total => "67.65",
      },
      distribution => "Folklore-Japan",
      release => "Folklore-Japan-v1.2.3",
      url => "http://cpancover.com/latest/Folklore-Japan-v1.2.3/index.html",
      version => "v1.2.3",
    } ) || die( Net::API::CPAN::Cover->error );
    
    my $this = $obj->criteria;
    my $float = $obj->criteria->branch;
    my $float = $obj->criteria->condition;
    my $float = $obj->criteria->statement;
    my $float = $obj->criteria->subroutine;
    my $float = $obj->criteria->total;
    my $string = $obj->distribution;
    my $str = $obj->object;
    my $string = $obj->release;
    my $uri = $obj->url;
    my $vers = $obj->version;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate covers.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Cover> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 criteria

    $obj->criteria( {
      branch => "54.68",
      condition => "57.56",
      statement => "78.14",
      subroutine => "80.00",
      total => "67.65",
    } );
    my $this = $obj->criteria;
    $obj->criteria->branch( "54.68" );
    my $float = $obj->criteria->branch;
    $obj->criteria->condition( "57.56" );
    my $float = $obj->criteria->condition;
    $obj->criteria->statement( "78.14" );
    my $float = $obj->criteria->statement;
    $obj->criteria->subroutine( "80.00" );
    my $float = $obj->criteria->subroutine;
    $obj->criteria->total( "67.65" );
    my $float = $obj->criteria->total;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Cover::Criteria> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<branch> integer (L<number object|Module::Generic::Number>)

=item * C<condition> integer (L<number object|Module::Generic::Number>)

=item * C<statement> integer (L<number object|Module::Generic::Number>)

=item * C<subroutine> integer (L<number object|Module::Generic::Number>)

=item * C<total> integer (L<number object|Module::Generic::Number>)

=back

=head2 distribution

    $obj->distribution( "Folklore-Japan" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<cover>

=head2 release

    $obj->release( "Folklore-Japan-v1.2.3" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 url

    $obj->url( "http://cpancover.com/latest/Folklore-Japan-v1.2.3/index.html" );
    my $uri = $obj->url;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 version

    $obj->version( "v1.2.3" );
    my $version = $obj->version;

Sets or gets a version value and returns a version object using L<Changes::Version>.

=head1 API SAMPLE

    {
       "criteria" : {
          "branch" : "54.68",
          "total" : "67.65",
          "condition" : "57.56",
          "subroutine" : "80.00",
          "statement" : "78.14"
       },
       "version" : "v1.2.3",
       "distribution" : "Folklore-Japan",
       "url" : "http://cpancover.com/latest/Folklore-Japan-v1.2.3/index.html",
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

