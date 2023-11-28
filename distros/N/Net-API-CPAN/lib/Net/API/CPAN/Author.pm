##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Author.pm
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
package Net::API::CPAN::Author;
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
    $self->{asciiname}                  = undef unless( CORE::exists( $self->{asciiname} ) );
    $self->{blog}                       = [] unless( CORE::exists( $self->{blog} ) );
    $self->{city}                       = undef unless( CORE::exists( $self->{city} ) );
    $self->{country}                    = undef unless( CORE::exists( $self->{country} ) );
    $self->{donation}                   = [] unless( CORE::exists( $self->{donation} ) );
    $self->{email}                      = [] unless( CORE::exists( $self->{email} ) );
    $self->{gravatar_url}               = undef unless( CORE::exists( $self->{gravatar_url} ) );
    $self->{is_pause_custodial_account} = undef unless( CORE::exists( $self->{is_pause_custodial_account} ) );
    $self->{links}                      = undef unless( CORE::exists( $self->{links} ) );
    $self->{location}                   = [] unless( CORE::exists( $self->{location} ) );
    $self->{name}                       = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}                     = 'author';
    $self->{pauseid}                    = undef unless( CORE::exists( $self->{pauseid} ) );
    $self->{perlmongers}                = [] unless( CORE::exists( $self->{perlmongers} ) );
    $self->{profile}                    = [] unless( CORE::exists( $self->{profile} ) );
    $self->{region}                     = undef unless( CORE::exists( $self->{region} ) );
    $self->{release_count}              = undef unless( CORE::exists( $self->{release_count} ) );
    $self->{updated}                    = undef unless( CORE::exists( $self->{updated} ) );
    $self->{user}                       = undef unless( CORE::exists( $self->{user} ) );
    $self->{website}                    = [] unless( CORE::exists( $self->{website} ) );
    $self->{_init_preprocess} = sub
    {
        my $this = shift( @_ );
        if( $self->_is_hash( $this ) )
        {
            if( exists( $this->{perlmongers} ) &&
                ref( $this->{perlmongers} ) eq 'HASH' )
            {
                $this->{perlmongers} = [$this->{perlmongers}];
            }
        }
        return( $this );
    };
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        asciiname blog city country donation email gravatar_url is_pause_custodial_account
        links location name pauseid perlmongers profile region release_count updated user
        website
    )];
    return( $self );
}

sub asciiname { return( shift->_set_get_scalar_as_object( 'asciiname', @_ ) ); }

sub blog { return( shift->_set_get_class_array_object( 'blog', { feed => "scalar_as_object", url => "uri" }, @_ ) ); }

sub city { return( shift->_set_get_scalar_as_object( 'city', @_ ) ); }

sub country { return( shift->_set_get_scalar_as_object( 'country', @_ ) ); }

sub dir { return( shift->links->cpan_directory( @_ ) ); }

sub donation { return( shift->_set_get_class_array_object( 'donation', { id => "scalar_as_object", name => "scalar_as_object" }, @_ ) ); }

sub email { return( shift->_set_get_object_array_object( {
    field => 'email',
    callback => sub
    {
        my( $class, $args ) = @_;
        return( $class->parse_bare_address( $args->[0] ) );
    }
}, 'Email::Address::XS', @_ ) ); }

sub gravatar_url { return( shift->_set_get_uri( 'gravatar_url', @_ ) ); }

sub is_pause_custodial_account { return( shift->_set_get_boolean( 'is_pause_custodial_account', @_ ) ); }

sub links { return( shift->_set_get_class( 'links', {
    backpan_directory => "uri",
    cpan_directory => "uri",
    cpantesters_matrix => "uri",
    cpantesters_reports => "uri",
    cpants => "uri",
    metacpan_explorer => "uri",
    repology => "uri",
}, @_ ) ); }

sub location { return( shift->_set_get_array_as_object( 'location', @_ ) ); }

sub metacpan_url
{
    my $self = shift( @_ );
    my $pauseid = $self->pauseid || 
        return( $self->error( "No pause ID is set to return a Meta CPAN URL for this author." ) );
    my $api_uri = $self->api->api_uri->clone;
    $api_uri->path( "/author/$pauseid" );
    return( $api_uri );
}

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub pauseid { return( shift->_set_get_scalar_as_object( 'pauseid', @_ ) ); }

sub perlmongers { return( shift->_set_get_class_array_object( 'perlmongers', { name => "scalar_as_object", url => "uri" }, @_ ) ); }

sub profile { return( shift->_set_get_class_array_object( 'profile', { id => "scalar_as_object", name => "scalar_as_object" }, @_ ) ); }

sub region { return( shift->_set_get_scalar_as_object( 'region', @_ ) ); }

sub release_count { return( shift->_set_get_class( 'release_count', { backpan_only => "integer", cpan => "integer", latest => "integer" }, @_ ) ); }

# Taken from MetaCPAN::Client::Author for compatibility
sub releases
{
    my $self = shift( @_ );
    my $id   = $self->pauseid;
    return( $self->api->release({
        all => [
            { author => $id },
            { status => 'latest' },
        ]
    }) );
}

sub updated { return( shift->_set_get_datetime( 'updated', @_ ) ); }

sub user { return( shift->_set_get_scalar_as_object( 'user', @_ ) ); }

sub website { return( shift->_set_get_object_array_object( 'website', 'URI', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Author - Meta CPAN API Author Class

=head1 SYNOPSIS

    use Net::API::CPAN::Author;
    my $obj = Net::API::CPAN::Author->new( {
      asciiname => "Taro Momo",
      blog => [
        {
          feed => "",
          url => "https://momotaro.example.jp/",
        },
        {
          feed => "https://blogs.perl.org/users/momotaro/atom.xml",
          url => "https://blogs.perl.org/users/momotaro/",
        },
      ],
      city => "Okayama",
      country => "JP",
      donation => [
        {
          id => "momo.taro\@example.jp",
          name => "stripe",
        },
      ],
      email => [
        "momo.taro\@example.jp",
      ],
      gravatar_url => "https://secure.gravatar.com/avatar/a123abc456def789ghi0jkl?s=130&d=identicon",
      links => {
        backpan_directory => "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO",
        cpan_directory => "http://cpan.org/authors/id/M/MO/MOMOTARO",
        cpantesters_matrix => "http://matrix.cpantesters.org/?author=MOMOTARO",
        cpantesters_reports => "http://cpantesters.org/author/M/MOMOTARO.html",
        cpants => "http://cpants.cpanauthors.org/author/MOMOTARO",
        metacpan_explorer => "https://explorer.metacpan.org/?url=/author/MOMOTARO",
        repology => "https://repology.org/maintainer/MOMOTARO%40cpan",
      },
      location => [
        "34.7338553",
        "133.7660595",
      ],
      name => "\x{6843}\x{592a}\x{90ce}",
      pauseid => "MOMOTARO",
      perlmongers => [
        {
          name => "momo.taro",
        },
      ],
      profile => [
        {
          id => "momotaro",
          name => "coderwall",
        },
        {
          id => "momotaro",
          name => "github",
        },
        {
          id => "momotaro",
          name => "linkedin",
        },
        {
          id => "momotaro",
          name => "twitter",
        },
        {
          id => "momotaro",
          name => "gitlab",
        },
      ],
      region => "Okayama",
      release_count => {
        "backpan-only" => 12,
        cpan => 420,
        latest => 17,
      },
      updated => "2023-07-29T04:45:10",
      user => "j_20ap7aNOkaYA11m9a2",
      website => [
        "https://www.momotaro.jp/",
      ],
    } ) || die( Net::API::CPAN::Author->error );
    
    my $string = $obj->asciiname;
    my $array = $obj->blog;
    foreach my $this ( @$array )
    {
        my $scalar = $this->feed;
        my $uri = $this->url;
    }
    my $string = $obj->city;
    my $string = $obj->country;
    my $string = $obj->dir;
    my $array = $obj->donation;
    foreach my $this ( @$array )
    {
        my $scalar = $this->id;
        my $scalar = $this->name;
    }
    my $array = $obj->email;
    my $uri = $obj->gravatar_url;
    my $bool = $obj->is_pause_custodial_account;
    my $this = $obj->links;
    my $uri = $obj->links->backpan_directory;
    my $uri = $obj->links->cpan_directory;
    my $uri = $obj->links->cpantesters_matrix;
    my $uri = $obj->links->cpantesters_reports;
    my $uri = $obj->links->cpants;
    my $uri = $obj->links->metacpan_explorer;
    my $uri = $obj->links->repology;
    my $array = $obj->location;
    my $uri = $obj->metacpan_url;
    my $string = $obj->name;
    my $str = $obj->object;
    my $string = $obj->pauseid;
    my $array = $obj->perlmongers;
    foreach my $this ( @$array )
    {
        my $scalar = $this->name;
        my $uri = $this->url;
    }
    my $array = $obj->profile;
    foreach my $this ( @$array )
    {
        my $scalar = $this->id;
        my $scalar = $this->name;
    }
    my $string = $obj->region;
    my $this = $obj->release_count;
    my $integer = $obj->release_count->backpan_only;
    my $integer = $obj->release_count->cpan;
    my $integer = $obj->release_count->latest;
    my $this = $obj->releases;
    my $date = $obj->updated;
    my $string = $obj->user;
    my $array = $obj->website;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate authors.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Author> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 asciiname

    $obj->asciiname( "Taro Momo" );
    my $string = $obj->asciiname;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 blog

    $obj->blog( [
      {
        feed => "",
        url => "https://momotaro.example.jp/",
      },
      {
        feed => "https://blogs.perl.org/users/momotaro/atom.xml",
        url => "https://blogs.perl.org/users/momotaro/",
      },
    ] );
    my $array = $obj->blog;
    foreach my $this ( @$array )
    {
        my $scalar = $this->feed;
        $this->url( "https://momotaro.example.jp/" );
        my $uri = $this->url;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Author::Blog> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Author::Blog> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<feed> scalar_as_object

=item * C<url> URI (L<uri object|URI>)

=back

=head2 city

    $obj->city( "Okayama" );
    my $string = $obj->city;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 country

    $obj->country( "JP" );
    my $string = $obj->country;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 dir

Sets or gets the C<cpan_directory> link property.

This is actually a shortcut to accessing the property C<cpan_directory> in L</links>

It returns an L<URI> object, or C<undef> if no value is set.

=head2 donation

    $obj->donation( [
      {
        id => "momo.taro\@example.jp",
        name => "stripe",
      },
    ] );
    my $array = $obj->donation;
    foreach my $this ( @$array )
    {
        $this->id( "momo.taro\@example.jp" );
        my $scalar = $this->id;
        $this->name( "stripe" );
        my $scalar = $this->name;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Author::Donation> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Author::Donation> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<id> scalar_as_object

=item * C<name> scalar_as_object

=back

=head2 email

    $obj->email( [
      "momo.taro\@example.jp",
    ] );
    my $array = $obj->email;

Sets or gets an array of L<Email::Address::XS> objects, or creates an L<Email::Address::XS> instance for each email provided in the array, and returns an L<array object|Module::Generic::Array>, even if no value was provided.

=head2 gravatar_url

    $obj->gravatar_url( "https://secure.gravatar.com/avatar/a123abc456def789ghi0jkl?s=130&d=identicon" );
    my $uri = $obj->gravatar_url;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 is_pause_custodial_account

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 links

    $obj->links( {
      backpan_directory => "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO",
      cpan_directory => "http://cpan.org/authors/id/M/MO/MOMOTARO",
      cpantesters_matrix => "http://matrix.cpantesters.org/?author=MOMOTARO",
      cpantesters_reports => "http://cpantesters.org/author/M/MOMOTARO.html",
      cpants => "http://cpants.cpanauthors.org/author/MOMOTARO",
      metacpan_explorer => "https://explorer.metacpan.org/?url=/author/MOMOTARO",
      repology => "https://repology.org/maintainer/MOMOTARO%40cpan",
    } );
    my $this = $obj->links;
    $obj->links->backpan_directory( "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO" );
    my $uri = $obj->links->backpan_directory;
    $obj->links->cpan_directory( "http://cpan.org/authors/id/M/MO/MOMOTARO" );
    my $uri = $obj->links->cpan_directory;
    $obj->links->cpantesters_matrix( "http://matrix.cpantesters.org/?author=MOMOTARO" );
    my $uri = $obj->links->cpantesters_matrix;
    $obj->links->cpantesters_reports( "http://cpantesters.org/author/M/MOMOTARO.html" );
    my $uri = $obj->links->cpantesters_reports;
    $obj->links->cpants( "http://cpants.cpanauthors.org/author/MOMOTARO" );
    my $uri = $obj->links->cpants;
    $obj->links->metacpan_explorer( "https://explorer.metacpan.org/?url=/author/MOMOTARO" );
    my $uri = $obj->links->metacpan_explorer;
    $obj->links->repology( "https://repology.org/maintainer/MOMOTARO%40cpan" );
    my $uri = $obj->links->repology;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Author::Links> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<backpan_directory> URI (L<uri object|URI>)

=item * C<cpan_directory> URI (L<uri object|URI>)

=item * C<cpantesters_matrix> URI (L<uri object|URI>)

=item * C<cpantesters_reports> URI (L<uri object|URI>)

=item * C<cpants> URI (L<uri object|URI>)

=item * C<metacpan_explorer> URI (L<uri object|URI>)

=item * C<repology> URI (L<uri object|URI>)

=back

=head2 location

    $obj->location( [
      "34.7338553",
      "133.7660595",
    ] );
    my $array = $obj->location;

Sets or gets an array of locations and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 metacpan_url

Returns a link, as an L<URI> object, to the author's page on MetaCPAN, or C<undef> if no C<pauseid> is currently set.

=head2 name

    $obj->name( "\x{6843}\x{592a}\x{90ce}" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<author>

=head2 pauseid

    $obj->pauseid( "MOMOTARO" );
    my $string = $obj->pauseid;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 perlmongers

    $obj->perlmongers( [
      {
        name => "momo.taro",
      },
    ] );
    my $array = $obj->perlmongers;
    foreach my $this ( @$array )
    {
        $this->name( "momo.taro" );
        my $scalar = $this->name;
        my $uri = $this->url;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Author::Perlmongers> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Author::Perlmongers> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<name> scalar_as_object

=item * C<url> URI (L<uri object|URI>)

=back

=head2 profile

    $obj->profile( [
      {
        id => "momotaro",
        name => "coderwall",
      },
      {
        id => "momotaro",
        name => "github",
      },
      {
        id => "momotaro",
        name => "linkedin",
      },
      {
        id => "momotaro",
        name => "twitter",
      },
      {
        id => "momotaro",
        name => "gitlab",
      },
    ] );
    my $array = $obj->profile;
    foreach my $this ( @$array )
    {
        $this->id( "momotaro" );
        my $scalar = $this->id;
        $this->name( "coderwall" );
        my $scalar = $this->name;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Author::Profile> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Author::Profile> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<id> scalar_as_object

=item * C<name> scalar_as_object

=back

=head2 region

    $obj->region( "Okayama" );
    my $string = $obj->region;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 release_count

    $obj->release_count( {
      "backpan-only" => 12,
      cpan => 420,
      latest => 17,
    } );
    my $this = $obj->release_count;
    my $integer = $obj->release_count->backpan_only;
    $obj->release_count->cpan( 420 );
    my $integer = $obj->release_count->cpan;
    $obj->release_count->latest( 17 );
    my $integer = $obj->release_count->latest;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Author::ReleaseCount> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<backpan_only> integer (L<number object|Module::Generic::Number>)

=item * C<cpan> integer (L<number object|Module::Generic::Number>)

=item * C<latest> integer (L<number object|Module::Generic::Number>)

=back

=head2 releases

Returns an L<Net::API::CPAN::ResultSet> oject containing all the author latest releases as L<release objects|Net::API::CPAN::Release>.

=head2 updated

    $obj->updated( "2023-07-29T04:45:10" );
    my $datetime_obj = $obj->updated;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 user

    $obj->user( "j_20ap7aNOkaYA11m9a2" );
    my $string = $obj->user;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 website

    $obj->website( [
      "https://www.momotaro.jp/",
    ] );
    my $array = $obj->website;

Sets or gets an array of L<URI> objects, or creates an L<URI> instance for each website provided in the array, and returns an L<array object|Module::Generic::Array>, even if no value was provided.

=head1 API SAMPLE

    {
       "asciiname" : "Taro Momo",
       "blog" : [
          {
             "feed" : "",
             "url" : "https://momotaro.example.jp/"
          },
          {
             "feed" : "https://blogs.perl.org/users/momotaro/atom.xml",
             "url" : "https://blogs.perl.org/users/momotaro/"
          },
       ],
       "city" : "Okayama",
       "country" : "JP",
       "donation" : [
          {
             "name" : "stripe",
             "id" : "momo.taro@example.jp"
          }
       ],
       "perlmongers": [
          {
             "name": "momo.taro"
          }
       ],
       "email" : [
          "momo.taro@example.jp"
       ],
       "gravatar_url" : "https://secure.gravatar.com/avatar/a123abc456def789ghi0jkl?s=130&d=identicon",
       "links" : {
          "backpan_directory" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO",
          "cpan_directory" : "http://cpan.org/authors/id/M/MO/MOMOTARO",
          "cpantesters_matrix" : "http://matrix.cpantesters.org/?author=MOMOTARO",
          "cpantesters_reports" : "http://cpantesters.org/author/M/MOMOTARO.html",
          "cpants" : "http://cpants.cpanauthors.org/author/MOMOTARO",
          "metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/MOMOTARO",
          "repology" : "https://repology.org/maintainer/MOMOTARO%40cpan"
       },
       "location" : [
          34.7338553,
          133.7660595
       ],
       "name" : "桃太郎",
       "pauseid" : "MOMOTARO",
       "profile" : [
          {
             "id" : "momotaro",
             "name" : "coderwall"
          },
          {
             "id" : "momotaro",
             "name" : "github"
          },
          {
             "id" : "momotaro",
             "name" : "linkedin"
          },
          {
             "id" : "momotaro",
             "name" : "twitter"
          },
          {
             "id" : "momotaro",
             "name" : "gitlab"
          }
       ],
       "region" : "Okayama",
       "release_count" : {
          "backpan-only" : 12,
          "cpan" : 420,
          "latest" : 17
       },
       "updated" : "2023-07-29T04:45:10",
       "user" : "j_20ap7aNOkaYA11m9a2",
       "website" : [
          "https://www.momotaro.jp/"
       ]
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

