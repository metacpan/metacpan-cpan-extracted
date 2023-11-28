##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Distribution.pm
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
package Net::API::CPAN::Distribution;
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
    $self->{bugs}             = undef unless( CORE::exists( $self->{bugs} ) );
    $self->{external_package} = undef unless( CORE::exists( $self->{external_package} ) );
    $self->{name}             = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}           = 'distribution';
    $self->{river}            = undef unless( CORE::exists( $self->{river} ) );
    $self->{_init_preprocess} = sub
    {
        my $this = shift( @_ );
        if( $self->_is_array( $this ) )
        {
            for( my $i = 0; $i < scalar( @$this ); $i += 2 )
            {
                if( $this->[$i] eq 'bugs' )
                {
                    my $ref = $this->[$i + 1];
                    if( ref( $ref ) eq 'HASH' &&
                        exists( $ref->{rt} ) &&
                        ref( $ref->{rt} ) eq 'HASH' &&
                        exists( $ref->{rt}->{new} ) )
                    {
                        $ref->{rt}->{recent} = CORE::delete( $ref->{rt}->{new} );
                        $this->[$i + 1] = $ref;
                    }
                }
            }
        }
        elsif( $self->_is_hash( $this ) )
        {
            if( exists( $this->{bugs} ) &&
                ref( $this->{bugs} ) eq 'HASH' &&
                exists( $this->{bugs}->{rt} ) &&
                ref( $this->{bugs}->{rt} ) eq 'HASH' &&
                exists( $this->{bugs}->{rt}->{new} ) )
            {
                $this->{bugs}->{rt}->{recent} = CORE::delete( $this->{bugs}->{rt}->{new} );
            }
        }
        return( $this );
    };
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( bugs external_package name river )];
    return( $self );
}

sub bugs { return( shift->_set_get_class( 'bugs', {
    github => {
        def => {
            active => "integer",
            closed => "integer",
            open => "integer",
            source => "uri",
        },
        type => "class",
    },
    rt => {
        def => {
            active => "integer",
            closed => "integer",
            open => "integer",
            patched => "integer",
            recent => "integer",
            rejected => "integer",
            resolved => "integer",
            source => "uri",
            stalled => "integer",
        },
        type => "class",
    },
}, @_ ) ); }

sub external_package { return( shift->_set_get_class( 'external_package', {
    cygwin => "scalar_as_object",
    debian => "scalar_as_object",
    fedora => "scalar_as_object",
}, @_ ) ); }

sub github { return( shift->bugs->github ); }

sub metacpan_url
{
    my $self = shift( @_ );
    my $name = $self->name || 
        return( $self->error( "No distribution name is set to return a Meta CPAN URL for this distribution." ) );
    my $api_uri = $self->api->api_uri->clone;
    $api_uri->path( "/release/$name" );
    return( $api_uri );
}

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub river { return( shift->_set_get_class( 'river', {
    bucket => "integer",
    bus_factor => "integer",
    immediate => "integer",
    total => "integer",
}, @_ ) ); }

sub rt { return( shift->bugs->rt ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Distribution - Meta CPAN API Distribution Class

=head1 SYNOPSIS

    use Net::API::CPAN::Distribution;
    my $obj = Net::API::CPAN::Distribution->new( {
      bugs => {
        github => {
          active => 5,
          closed => 10,
          open => 3,
          source => "https://github.com/momotaro/Folkore-Japan",
        },
        rt => {
          active => 2,
          closed => 18,
          new => 0,
          open => 2,
          patched => 0,
          rejected => 0,
          resolved => 18,
          source => "https://rt.cpan.org/Public/Dist/Display.html?Name=Folkore-Japan",
          stalled => 0,
        },
      },
      external_package => {
        cygwin => "perl-Folkore-Japan",
        debian => "folklore-japan-perl",
        fedora => "perl-Folkore-Japan",
      },
      name => "Folklore-Japan",
      river => {
        bucket => 2,
        bus_factor => 1,
        immediate => 15,
        total => 19,
      },
    } ) || die( Net::API::CPAN::Distribution->error );
    
    my $this = $obj->bugs;
    my $github_obj = $obj->bugs->github;
    my $rt_obj = $obj->bugs->rt;
    my $this = $obj->external_package;
    my $scalar = $obj->external_package->cygwin;
    my $scalar = $obj->external_package->debian;
    my $scalar = $obj->external_package->fedora;
    my $this = $obj->github;
    my $uri = $obj->metacpan_url;
    my $string = $obj->name;
    my $str = $obj->object;
    my $this = $obj->river;
    my $integer = $obj->river->bucket;
    my $integer = $obj->river->bus_factor;
    my $integer = $obj->river->immediate;
    my $integer = $obj->river->total;
    my $this = $obj->rt;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate distributions.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Distribution> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 bugs

    $obj->bugs( {
      github => {
        active => 5,
        closed => 10,
        open => 3,
        source => "https://github.com/momotaro/Folkore-Japan",
      },
      rt => {
        active => 2,
        closed => 18,
        new => 0,
        open => 2,
        patched => 0,
        rejected => 0,
        resolved => 18,
        source => "https://rt.cpan.org/Public/Dist/Display.html?Name=Folkore-Japan",
        stalled => 0,
      },
    } );
    my $this = $obj->bugs;
    $obj->bugs->github( {
      active => 5,
      closed => 10,
      open => 3,
      source => "https://github.com/momotaro/Folkore-Japan",
    } );
    my $github_obj = $obj->bugs->github;
    $obj->bugs->rt( {
      active => 2,
      closed => 18,
      new => 0,
      open => 2,
      patched => 0,
      rejected => 0,
      resolved => 18,
      source => "https://rt.cpan.org/Public/Dist/Display.html?Name=Folkore-Japan",
      stalled => 0,
    } );
    my $rt_obj = $obj->bugs->rt;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Distribution::Bugs> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<github> dynamic subclass (hash reference)

=over 8

=item * C<active> integer (L<number object|Module::Generic::Number>)

=item * C<closed> integer (L<number object|Module::Generic::Number>)

=item * C<open> integer (L<number object|Module::Generic::Number>)

=item * C<source> URI (L<uri object|URI>)

=back

=item * C<rt> dynamic subclass (hash reference)

=over 8

=item * C<active> integer (L<number object|Module::Generic::Number>)

=item * C<closed> integer (L<number object|Module::Generic::Number>)

=item * C<open> integer (L<number object|Module::Generic::Number>)

=item * C<patched> integer (L<number object|Module::Generic::Number>)

=item * C<recent> integer (L<number object|Module::Generic::Number>)

=item * C<rejected> integer (L<number object|Module::Generic::Number>)

=item * C<resolved> integer (L<number object|Module::Generic::Number>)

=item * C<source> URI (L<uri object|URI>)

=item * C<stalled> integer (L<number object|Module::Generic::Number>)

=back

=back

=head2 external_package

    $obj->external_package( {
      cygwin => "perl-Folkore-Japan",
      debian => "folklore-japan-perl",
      fedora => "perl-Folkore-Japan",
    } );
    my $this = $obj->external_package;
    $obj->external_package->cygwin( "perl-Folkore-Japan" );
    my $scalar = $obj->external_package->cygwin;
    $obj->external_package->debian( "folklore-japan-perl" );
    my $scalar = $obj->external_package->debian;
    $obj->external_package->fedora( "perl-Folkore-Japan" );
    my $scalar = $obj->external_package->fedora;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Distribution::ExternalPackage> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<cygwin> scalar_as_object

=item * C<debian> scalar_as_object

=item * C<fedora> scalar_as_object

=back

=head2 github

Returns the object for the dynamic class C<Net::API::CPAN::Bugs::Github>, which provides access to a few methods.

See L</bugs> for more information.

It returns C<undef> if no value is set.

=head2 metacpan_url

Returns a link, as an L<URI> object, to the distribution's page on MetaCPAN, or C<undef> if no distribution C<name> is currently set.

=head2 name

    $obj->name( "Folklore-Japan" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<distribution>

=head2 river

    $obj->river( {
      bucket => 2,
      bus_factor => 1,
      immediate => 15,
      total => 19,
    } );
    my $this = $obj->river;
    $obj->river->bucket( 2 );
    my $integer = $obj->river->bucket;
    $obj->river->bus_factor( 1 );
    my $integer = $obj->river->bus_factor;
    $obj->river->immediate( 15 );
    my $integer = $obj->river->immediate;
    $obj->river->total( 19 );
    my $integer = $obj->river->total;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Distribution::River> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<bucket> integer (L<number object|Module::Generic::Number>)

=item * C<bus_factor> integer (L<number object|Module::Generic::Number>)

=item * C<immediate> integer (L<number object|Module::Generic::Number>)

=item * C<total> integer (L<number object|Module::Generic::Number>)

=back

=head2 rt

Returns the object for the dynamic class C<Net::API::CPAN::Bugs::Rt>, which provides access to a few methods.

See L</bugs> for more information.

It returns C<undef> if no value is set.

=head1 API SAMPLE

    {
       "bugs" : {
          "github" : {
             "active" : 5,
             "closed" : 10,
             "open" : 3,
             "source" : "https://github.com/momotaro/Folkore-Japan"
          },
          "rt" : {
             "active" : "2",
             "closed" : "18",
             "new" : 0,
             "open" : 2,
             "patched" : 0,
             "rejected" : 0,
             "resolved" : 18,
             "source" : "https://rt.cpan.org/Public/Dist/Display.html?Name=Folkore-Japan",
             "stalled" : 0
          }
       },
       "external_package" : {
          "cygwin" : "perl-Folkore-Japan",
          "debian" : "folklore-japan-perl",
          "fedora" : "perl-Folkore-Japan"
       },
       "name" : "Folklore-Japan",
       "river" : {
          "bucket" : 2,
          "bus_factor" : 1,
          "immediate" : 15,
          "total" : 19
       }
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

