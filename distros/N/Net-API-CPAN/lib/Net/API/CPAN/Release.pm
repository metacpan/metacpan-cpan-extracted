##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Release.pm
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
package Net::API::CPAN::Release;
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
    $self->{abstract}         = undef unless( CORE::exists( $self->{abstract} ) );
    $self->{archive}          = undef unless( CORE::exists( $self->{archive} ) );
    $self->{author}           = undef unless( CORE::exists( $self->{author} ) );
    $self->{authorized}       = undef unless( CORE::exists( $self->{authorized} ) );
    $self->{changes_file}     = undef unless( CORE::exists( $self->{changes_file} ) );
    $self->{checksum_md5}     = undef unless( CORE::exists( $self->{checksum_md5} ) );
    $self->{checksum_sha256}  = undef unless( CORE::exists( $self->{checksum_sha256} ) );
    $self->{date}             = undef unless( CORE::exists( $self->{date} ) );
    $self->{dependency}       = [] unless( CORE::exists( $self->{dependency} ) );
    $self->{deprecated}       = undef unless( CORE::exists( $self->{deprecated} ) );
    $self->{distribution}     = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{download_url}     = undef unless( CORE::exists( $self->{download_url} ) );
    $self->{first}            = undef unless( CORE::exists( $self->{first} ) );
    $self->{id}               = undef unless( CORE::exists( $self->{id} ) );
    $self->{license}          = [] unless( CORE::exists( $self->{license} ) );
    $self->{main_module}      = undef unless( CORE::exists( $self->{main_module} ) );
    $self->{maturity}         = undef unless( CORE::exists( $self->{maturity} ) );
    $self->{metadata}         = undef unless( CORE::exists( $self->{metadata} ) );
    $self->{name}             = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}           = 'release';
    $self->{provides}         = [] unless( CORE::exists( $self->{provides} ) );
    $self->{resources}        = undef unless( CORE::exists( $self->{resources} ) );
    $self->{stat}             = undef unless( CORE::exists( $self->{stat} ) );
    $self->{status}           = undef unless( CORE::exists( $self->{status} ) );
    $self->{tests}            = undef unless( CORE::exists( $self->{tests} ) );
    $self->{version}          = '' unless( CORE::exists( $self->{version} ) );
    $self->{version_numified} = undef unless( CORE::exists( $self->{version_numified} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        abstract archive author authorized changes_file checksum_md5 checksum_sha256 date
        dependency deprecated distribution download_url first id license main_module
        maturity metadata name provides resources stat status tests version
        version_numified
    )];
    return( $self );
}

sub abstract { return( shift->_set_get_scalar_as_object( 'abstract', @_ ) ); }

sub archive { return( shift->_set_get_scalar_as_object( 'archive', @_ ) ); }

sub author { return( shift->_set_get_scalar_as_object( 'author', @_ ) ); }

sub authorized { return( shift->_set_get_boolean( 'authorized', @_ ) ); }

sub changes_file { return( shift->_set_get_scalar_as_object( 'changes_file', @_ ) ); }

sub checksum_md5 { return( shift->_set_get_scalar_as_object( 'checksum_md5', @_ ) ); }

sub checksum_sha256 { return( shift->_set_get_scalar_as_object( 'checksum_sha256', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub dependency { return( shift->_set_get_class_array_object( 'dependency', {
    module => "scalar_as_object",
    phase => "scalar_as_object",
    relationship => "scalar_as_object",
    version => { class => "Changes::Version", type => "version" },
}, @_ ) ); }

sub deprecated { return( shift->_set_get_boolean( 'deprecated', @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub download_url { return( shift->_set_get_uri( 'download_url', @_ ) ); }

sub first { return( shift->_set_get_boolean( 'first', @_ ) ); }

sub id { return( shift->_set_get_scalar_as_object( 'id', @_ ) ); }

sub license { return( shift->_set_get_array_as_object( 'license', @_ ) ); }

sub main_module { return( shift->_set_get_scalar_as_object( 'main_module', @_ ) ); }

sub maturity { return( shift->_set_get_scalar_as_object( 'maturity', @_ ) ); }

sub metadata { return( shift->_set_get_class( 'metadata', {
    abstract => "scalar_as_object",
    author => "array_as_object",
    dynamic_config => "boolean",
    generated_by => "scalar_as_object",
    license => "array_as_object",
    meta_spec => {
        def => {
            url => "uri",
            version => { class => "Changes::Version", type => "version" },
        },
        type => "class",
    },
    name => "scalar_as_object",
    no_index => {
        def => { directory => "array_as_object", package => "array_as_object" },
        type => "class",
    },
    prereqs => {
        def => {
            build => {
                def => {
                    recommends => "hash_as_object",
                    requires => "hash_as_object",
                    suggests => "hash_as_object",
                },
                type => "class",
            },
            configure => {
                def => {
                    recommends => "hash_as_object",
                    requires => "hash_as_object",
                    suggests => "hash_as_object",
                },
                type => "class",
            },
            develop => {
                def => {
                    recommends => "hash_as_object",
                    requires => "hash_as_object",
                    suggests => "hash_as_object",
                },
                type => "class",
            },
            runtime => {
                def => {
                    recommends => "hash_as_object",
                    requires => "hash_as_object",
                    suggests => "hash_as_object",
                },
                type => "class",
            },
            test => {
                def => {
                    recommends => "hash_as_object",
                    requires => "hash_as_object",
                    suggests => "hash_as_object",
                },
                type => "class",
            },
        },
        type => "class",
    },
    release_status => "scalar_as_object",
    resources => {
        def => {
            bugtracker => {
                def => { mailto => "uri", type => "string", web => "uri" },
                type => "class",
            },
            homepage => {
                def => { web => "uri" },
                type => "class",
            },
            license => "array_as_object",
            repository => {
                def => { type => "scalar", url => "uri", web => "uri" },
                type => "class",
            },
        },
        type => "class",
    },
    version => { class => "Changes::Version", type => "version" },
    version_numified => "float",
    x_contributors => { type => "array" },
    x_generated_by_perl => { type => "string" },
    x_serialization_backend => { type => "string" },
    x_spdx_expression => { type => "string" },
    x_static_install => { type => "string" },
}, @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub provides { return( shift->_set_get_array_as_object( 'provides', @_ ) ); }

sub resources { return( shift->_set_get_class( 'resources', {
    bugtracker => {
        def => { mailto => "uri", type => "string", web => "uri" },
        type => "class",
    },
    homepage => {
        def => { web => "uri" },
        type => "class",
    },
    license => "array_as_object",
    repository => {
        def => { type => "scalar", url => "uri", web => "uri" },
        type => "class",
    },
}, @_ ) ); }

sub stat { return( shift->_set_get_class( 'stat', {
    gid => "integer",
    mode => "integer",
    mtime => "datetime",
    size => "integer",
    uid => "integer",
}, @_ ) ); }

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

sub tests { return( shift->_set_get_class( 'tests', { fail => "integer", na => "integer", pass => "integer", unknown => "integer" }, @_ ) ); }

sub version { return( shift->_set_get_version( { class => "Changes::Version", field => "version" }, @_ ) ); }

sub version_numified { return( shift->_set_get_number( 'version_numified', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Release - Meta CPAN API Release Class

=head1 SYNOPSIS

    use Net::API::CPAN::Release;
    my $obj = Net::API::CPAN::Release->new( {
      abstract => "Japan Folklore Object Class",
      archive => "Folklore-Japan-v1.2.3.tar.gz",
      author => "MOMOTARO",
      authorized => \1,
      changes_file => "CHANGES",
      checksum_md5 => "71682907d95a4b0a4b74da8c16e88d2d",
      checksum_sha256 => "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
      date => "2023-07-29T05:10:12",
      dependency => [
        {
          module => "ExtUtils::MakeMaker",
          phase => "configure",
          relationship => "requires",
          version => 0,
        },
        {
          module => "ExtUtils::MakeMaker",
          phase => "build",
          relationship => "requires",
          version => 0,
        },
        {
          module => "Module::Generic",
          phase => "runtime",
          relationship => "requires",
          version => "v0.30.6",
        },
        {
          module => "DateTime::Format::JP",
          phase => "runtime",
          relationship => "requires",
          version => "v0.1.3",
        },
        {
          module => "Mock::Person::JP",
          phase => "runtime",
          relationship => "requires",
          version => "0.07",
        },
        {
          module => "Net::Airline::ANA",
          phase => "runtime",
          relationship => "requires",
          version => "2.34",
        },
        {
          module => "Transport::Limousine::Bus",
          phase => "runtime",
          relationship => "requires",
          version => "3.45",
        },
        {
          module => "Net::Reservation::KorakuenGarden",
          phase => "runtime",
          relationship => "requires",
          version => "v0.2.3",
        },
        {
          module => "Net::Reservation::OkayamaCastle",
          phase => "runtime",
          relationship => "requires",
          version => "4.03",
        },
        {
          module => "strict",
          phase => "runtime",
          relationship => "requires",
          version => 0,
        },
        {
          module => "warnings",
          phase => "runtime",
          relationship => "requires",
          version => 0,
        },
        {
          module => "parent",
          phase => "runtime",
          relationship => "requires",
          version => 0,
        },
        {
          module => "perl",
          phase => "runtime",
          relationship => "requires",
          version => "5.026001",
        },
        {
          module => "Test::Pod",
          phase => "test",
          relationship => "requires",
          version => "1.52",
        },
        {
          module => "Test::More",
          phase => "test",
          relationship => "requires",
          version => "1.302162",
        },
      ],
      deprecated => \0,
      distribution => "Folklore-Japan",
      download_url => "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v0.30.5.tar.gz",
      first => \0
    ,
      id => "Wo09n3d3er4s_56Of7_J8ap9an",
      license => [
        "perl_5",
      ],
      main_module => "Folklore::Japan",
      maturity => "released",
      metadata => {
        abstract => "Japan Folklore Object Class",
        author => [
          "Taro Momo <momo.taro\@example.jp>",
        ],
        dynamic_config => 1,
        generated_by => "ExtUtils::MakeMaker version 7.64, CPAN::Meta::Converter version 2.150010, CPAN::Meta::Converter version 2.150005",
        license => [
          "perl_5",
        ],
        "meta-spec" => {
          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
          version => 2,
        },
        name => "Folklore-Japan",
        no_index => {
          directory => [
            "t",
            "inc",
            "t",
            "xt",
            "inc",
            "local",
            "perl5",
            "fatlib",
            "example",
            "blib",
            "examples",
            "eg",
          ],
        },
        prereqs => {
          build => {
            requires => {
              "ExtUtils::MakeMaker" => 0,
            },
          },
          configure => {
            requires => {
              "ExtUtils::MakeMaker" => 0,
            },
          },
          runtime => {
            requires => {
              "DateTime::Format::JP" => "v0.1.3",
              "ExtUtils::MakeMaker" => 0,
              "Mock::Person::JP" => "0.07",
              "Module::Generic" => "v0.30.6",
              "Net::Airline::ANA" => "2.34",
              "Net::Reservation::KorakuenGarden" => "v0.2.3",
              "Net::Reservation::OkayamaCastle" => "4.03",
              "Test::More" => "1.302162",
              "Test::Pod" => "1.52",
              "Transport::Limousine::Bus" => "3.45",
              parent => 0,
              perl => "5.026001",
              strict => 0,
              warnings => 0,
            },
          },
          test => {
            requires => {
              "Test::More" => "1.302162",
              "Test::Pod" => "1.52",
            },
          },
        },
        release_status => "stable",
        resources => {
          bugtracker => {
            web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
          },
          homepage => {
            web => "https://www.okayama-japan.jp/en/feature/momotaro",
          },
          repository => {
            type => "git",
            web => "https://gitlab.com/momotaro/Folklore-Japan",
          },
        },
        version => "v1.2.3",
      },
      name => "Folklore-Japan-v1.2.3",
      provides => [
        "Folklore::Japan",
        "Folklore::Japan::AmaterasuOmikami",
        "Folklore::Japan::Izumo",
        "Folklore::Japan::Kintaro",
        "Folklore::Japan::Kitsune",
        "Folklore::Japan::Kojiki",
        "Folklore::Japan::MomoTaro",
        "Folklore::Japan::NihonShoki",
        "Folklore::Japan::Okayama",
        "Folklore::Japan::Susanoo",
        "Folklore::Japan::Tanuki",
        "Folklore::Japan::Tengu",
        "Folklore::Japan::UrashimaTaro",
      ],
      resources => {
        bugtracker => {
          web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
        },
        repository => {
          type => "git",
          web => "https://gitlab.com/momotaro/Folklore-Japan",
        },
      },
      stat => {
        gid => 12345,
        mode => 33188,
        mtime => 1690618397,
        size => 10240,
        uid => 16790,
      },
      status => "latest",
      version => "v1.2.3",
      version_numified => "1.002003",
    } ) || die( Net::API::CPAN::Release->error );
    
    my $string = $obj->abstract;
    my $string = $obj->archive;
    my $string = $obj->author;
    my $bool = $obj->authorized;
    my $string = $obj->changes_file;
    my $string = $obj->checksum_md5;
    my $string = $obj->checksum_sha256;
    my $date = $obj->date;
    my $array = $obj->dependency;
    foreach my $this ( @$array )
    {
        my $scalar = $this->module;
        my $scalar = $this->phase;
        my $scalar = $this->relationship;
        my $HASH(0xaaaac89729f0) = $this->version;
    }
    my $bool = $obj->deprecated;
    my $string = $obj->distribution;
    my $uri = $obj->download_url;
    my $bool = $obj->first;
    my $string = $obj->id;
    my $array = $obj->license;
    my $string = $obj->main_module;
    my $string = $obj->maturity;
    my $this = $obj->metadata;
    my $scalar = $obj->metadata->abstract;
    my $array = $obj->metadata->author;
    my $boolean = $obj->metadata->dynamic_config;
    my $scalar = $obj->metadata->generated_by;
    my $array = $obj->metadata->license;
    my $meta_spec_obj = $obj->metadata->meta_spec;
    my $scalar = $obj->metadata->name;
    my $no_index_obj = $obj->metadata->no_index;
    my $prereqs_obj = $obj->metadata->prereqs;
    my $scalar = $obj->metadata->release_status;
    my $resources_obj = $obj->metadata->resources;
    my $version_obj = $obj->metadata->version;
    my $float = $obj->metadata->version_numified;
    my $x_contributors_obj = $obj->metadata->x_contributors;
    my $x_generated_by_perl_obj = $obj->metadata->x_generated_by_perl;
    my $x_serialization_backend_obj = $obj->metadata->x_serialization_backend;
    my $x_spdx_expression_obj = $obj->metadata->x_spdx_expression;
    my $x_static_install_obj = $obj->metadata->x_static_install;
    my $string = $obj->name;
    my $str = $obj->object;
    my $array = $obj->provides;
    my $this = $obj->resources;
    my $bugtracker_obj = $obj->resources->bugtracker;
    my $homepage_obj = $obj->resources->homepage;
    my $array = $obj->resources->license;
    my $repository_obj = $obj->resources->repository;
    my $this = $obj->stat;
    my $integer = $obj->stat->gid;
    my $integer = $obj->stat->mode;
    my $datetime = $obj->stat->mtime;
    my $integer = $obj->stat->size;
    my $integer = $obj->stat->uid;
    my $string = $obj->status;
    my $this = $obj->tests;
    my $integer = $obj->tests->fail;
    my $integer = $obj->tests->na;
    my $integer = $obj->tests->pass;
    my $integer = $obj->tests->unknown;
    my $vers = $obj->version;
    my $num = $obj->version_numified;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate releases.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Release> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 abstract

    $obj->abstract( "Japan Folklore Object Class" );
    my $string = $obj->abstract;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 archive

    $obj->archive( "Folklore-Japan-v1.2.3.tar.gz" );
    my $string = $obj->archive;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 authorized

    $obj->authorized(1);
    my $bool = $obj->authorized;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 changes_file

    $obj->changes_file( "CHANGES" );
    my $string = $obj->changes_file;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

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

=head2 dependency

    $obj->dependency( [
      {
        module => "ExtUtils::MakeMaker",
        phase => "configure",
        relationship => "requires",
        version => 0,
      },
      {
        module => "ExtUtils::MakeMaker",
        phase => "build",
        relationship => "requires",
        version => 0,
      },
      {
        module => "Module::Generic",
        phase => "runtime",
        relationship => "requires",
        version => "v0.30.6",
      },
      {
        module => "DateTime::Format::JP",
        phase => "runtime",
        relationship => "requires",
        version => "v0.1.3",
      },
      {
        module => "Mock::Person::JP",
        phase => "runtime",
        relationship => "requires",
        version => "0.07",
      },
      {
        module => "Net::Airline::ANA",
        phase => "runtime",
        relationship => "requires",
        version => "2.34",
      },
      {
        module => "Transport::Limousine::Bus",
        phase => "runtime",
        relationship => "requires",
        version => "3.45",
      },
      {
        module => "Net::Reservation::KorakuenGarden",
        phase => "runtime",
        relationship => "requires",
        version => "v0.2.3",
      },
      {
        module => "Net::Reservation::OkayamaCastle",
        phase => "runtime",
        relationship => "requires",
        version => "4.03",
      },
      {
        module => "strict",
        phase => "runtime",
        relationship => "requires",
        version => 0,
      },
      {
        module => "warnings",
        phase => "runtime",
        relationship => "requires",
        version => 0,
      },
      {
        module => "parent",
        phase => "runtime",
        relationship => "requires",
        version => 0,
      },
      {
        module => "perl",
        phase => "runtime",
        relationship => "requires",
        version => "5.026001",
      },
      {
        module => "Test::Pod",
        phase => "test",
        relationship => "requires",
        version => "1.52",
      },
      {
        module => "Test::More",
        phase => "test",
        relationship => "requires",
        version => "1.302162",
      },
    ] );
    my $array = $obj->dependency;
    foreach my $this ( @$array )
    {
        $this->module( "ExtUtils::MakeMaker" );
        my $scalar = $this->module;
        $this->phase( "configure" );
        my $scalar = $this->phase;
        $this->relationship( "requires" );
        my $scalar = $this->relationship;
        $this->version( 0 );
        my $HASH(0xaaaac89729f0) = $this->version;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Release::Dependency> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Release::Dependency> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<module> scalar_as_object

=item * C<phase> scalar_as_object

=item * C<relationship> scalar_as_object

=item * C<version> L<version object|Changes::Version>

=back

=head2 deprecated

    $obj->deprecated(1);
    my $bool = $obj->deprecated;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 distribution

    $obj->distribution( "Folklore-Japan" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 download_url

    $obj->download_url( "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v0.30.5.tar.gz" );
    my $uri = $obj->download_url;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 first

    $obj->first(1);
    my $bool = $obj->first;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 id

    $obj->id( "Wo09n3d3er4s_56Of7_J8ap9an" );
    my $string = $obj->id;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 license

    $obj->license( [
      "perl_5",
    ] );
    my $array = $obj->license;

Sets or gets an array of licenses and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 main_module

    $obj->main_module( "Folklore::Japan" );
    my $string = $obj->main_module;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 maturity

    $obj->maturity( "released" );
    my $string = $obj->maturity;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 metadata

    $obj->metadata( {
      abstract => "Japan Folklore Object Class",
      author => [
        "Taro Momo <momo.taro\@example.jp>",
      ],
      dynamic_config => 1,
      generated_by => "ExtUtils::MakeMaker version 7.64, CPAN::Meta::Converter version 2.150010, CPAN::Meta::Converter version 2.150005",
      license => [
        "perl_5",
      ],
      "meta-spec" => {
        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
        version => 2,
      },
      name => "Folklore-Japan",
      no_index => {
        directory => [
          "t",
          "inc",
          "t",
          "xt",
          "inc",
          "local",
          "perl5",
          "fatlib",
          "example",
          "blib",
          "examples",
          "eg",
        ],
      },
      prereqs => {
        build => {
          requires => {
            "ExtUtils::MakeMaker" => 0,
          },
        },
        configure => {
          requires => {
            "ExtUtils::MakeMaker" => 0,
          },
        },
        runtime => {
          requires => {
            "DateTime::Format::JP" => "v0.1.3",
            "ExtUtils::MakeMaker" => 0,
            "Mock::Person::JP" => "0.07",
            "Module::Generic" => "v0.30.6",
            "Net::Airline::ANA" => "2.34",
            "Net::Reservation::KorakuenGarden" => "v0.2.3",
            "Net::Reservation::OkayamaCastle" => "4.03",
            "Test::More" => "1.302162",
            "Test::Pod" => "1.52",
            "Transport::Limousine::Bus" => "3.45",
            parent => 0,
            perl => "5.026001",
            strict => 0,
            warnings => 0,
          },
        },
        test => {
          requires => {
            "Test::More" => "1.302162",
            "Test::Pod" => "1.52",
          },
        },
      },
      release_status => "stable",
      resources => {
        bugtracker => {
          web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
        },
        homepage => {
          web => "https://www.okayama-japan.jp/en/feature/momotaro",
        },
        repository => {
          type => "git",
          web => "https://gitlab.com/momotaro/Folklore-Japan",
        },
      },
      version => "v1.2.3",
    } );
    my $this = $obj->metadata;
    $obj->metadata->abstract( "Japan Folklore Object Class" );
    my $scalar = $obj->metadata->abstract;
    $obj->metadata->author( [
      "Taro Momo <momo.taro\@example.jp>",
    ] );
    my $array = $obj->metadata->author;
    $obj->metadata->dynamic_config( 1 );
    my $boolean = $obj->metadata->dynamic_config;
    $obj->metadata->generated_by( "ExtUtils::MakeMaker version 7.64, CPAN::Meta::Converter version 2.150010, CPAN::Meta::Converter version 2.150005" );
    my $scalar = $obj->metadata->generated_by;
    $obj->metadata->license( [
      "perl_5",
    ] );
    my $array = $obj->metadata->license;
    my $meta_spec_obj = $obj->metadata->meta_spec;
    $obj->metadata->name( "Folklore-Japan" );
    my $scalar = $obj->metadata->name;
    $obj->metadata->no_index( {
      directory => [
        "t",
        "inc",
        "t",
        "xt",
        "inc",
        "local",
        "perl5",
        "fatlib",
        "example",
        "blib",
        "examples",
        "eg",
      ],
    } );
    my $no_index_obj = $obj->metadata->no_index;
    $obj->metadata->prereqs( {
      build => {
        requires => {
          "ExtUtils::MakeMaker" => 0,
        },
      },
      configure => {
        requires => {
          "ExtUtils::MakeMaker" => 0,
        },
      },
      runtime => {
        requires => {
          "DateTime::Format::JP" => "v0.1.3",
          "ExtUtils::MakeMaker" => 0,
          "Mock::Person::JP" => "0.07",
          "Module::Generic" => "v0.30.6",
          "Net::Airline::ANA" => "2.34",
          "Net::Reservation::KorakuenGarden" => "v0.2.3",
          "Net::Reservation::OkayamaCastle" => "4.03",
          "Test::More" => "1.302162",
          "Test::Pod" => "1.52",
          "Transport::Limousine::Bus" => "3.45",
          parent => 0,
          perl => "5.026001",
          strict => 0,
          warnings => 0,
        },
      },
      test => {
        requires => {
          "Test::More" => "1.302162",
          "Test::Pod" => "1.52",
        },
      },
    } );
    my $prereqs_obj = $obj->metadata->prereqs;
    $obj->metadata->release_status( "stable" );
    my $scalar = $obj->metadata->release_status;
    $obj->metadata->resources( {
      bugtracker => {
        web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
      },
      homepage => {
        web => "https://www.okayama-japan.jp/en/feature/momotaro",
      },
      repository => {
        type => "git",
        web => "https://gitlab.com/momotaro/Folklore-Japan",
      },
    } );
    my $resources_obj = $obj->metadata->resources;
    $obj->metadata->version( "v1.2.3" );
    my $version_obj = $obj->metadata->version;
    my $float = $obj->metadata->version_numified;
    my $x_contributors_obj = $obj->metadata->x_contributors;
    my $x_generated_by_perl_obj = $obj->metadata->x_generated_by_perl;
    my $x_serialization_backend_obj = $obj->metadata->x_serialization_backend;
    my $x_spdx_expression_obj = $obj->metadata->x_spdx_expression;
    my $x_static_install_obj = $obj->metadata->x_static_install;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Release::Metadata> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<abstract> scalar_as_object

=item * C<author> array (L<array object|Module::Generic::Array>)

=item * C<dynamic_config> boolean (L<boolean object|Module::Generic::Boolean>)

=item * C<generated_by> scalar_as_object

=item * C<license> array (L<array object|Module::Generic::Array>)

=item * C<meta_spec> dynamic subclass (hash reference)

=over 8

=item * C<url> URI (L<uri object|URI>)

=item * C<version> L<version object|Changes::Version>

=back

=item * C<name> scalar_as_object

=item * C<no_index> dynamic subclass (hash reference)

=over 8

=item * C<directory> array (L<array object|Module::Generic::Array>)

=item * C<package> array (L<array object|Module::Generic::Array>)

=back

=item * C<prereqs> dynamic subclass (hash reference)

=over 8

=item * C<build> dynamic subclass (hash reference)

=over 12

=item * C<recommends> hash_as_object

=item * C<requires> hash_as_object

=item * C<suggests> hash_as_object

=back

=item * C<configure> dynamic subclass (hash reference)

=over 12

=item * C<recommends> hash_as_object

=item * C<requires> hash_as_object

=item * C<suggests> hash_as_object

=back

=item * C<develop> dynamic subclass (hash reference)

=over 12

=item * C<recommends> hash_as_object

=item * C<requires> hash_as_object

=item * C<suggests> hash_as_object

=back

=item * C<runtime> dynamic subclass (hash reference)

=over 12

=item * C<recommends> hash_as_object

=item * C<requires> hash_as_object

=item * C<suggests> hash_as_object

=back

=item * C<test> dynamic subclass (hash reference)

=over 12

=item * C<recommends> hash_as_object

=item * C<requires> hash_as_object

=item * C<suggests> hash_as_object

=back

=back

=item * C<release_status> scalar_as_object

=item * C<resources> dynamic subclass (hash reference)

=over 8

=item * C<bugtracker> dynamic subclass (hash reference)

=over 12

=item * C<mailto> URI (L<uri object|URI>)

=item * C<type> string

=item * C<web> URI (L<uri object|URI>)

=back

=item * C<homepage> dynamic subclass (hash reference)

=over 12

=item * C<web> URI (L<uri object|URI>)

=back

=item * C<license> array (L<array object|Module::Generic::Array>)

=item * C<repository> dynamic subclass (hash reference)

=over 12

=item * C<type> string (L<scalar object|Module::Generic::Scalar>)

=item * C<url> URI (L<uri object|URI>)

=item * C<web> URI (L<uri object|URI>)

=back

=back

=item * C<version> L<version object|Changes::Version>

=item * C<version_numified> integer (L<number object|Module::Generic::Number>)

=item * C<x_contributors> array (L<array object|Module::Generic::Array>)

=item * C<x_generated_by_perl> string

=item * C<x_serialization_backend> string

=item * C<x_spdx_expression> string

=item * C<x_static_install> string

=back

=head2 name

    $obj->name( "Folklore-Japan-v1.2.3" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<release>

=head2 provides

    $obj->provides( [
      "Folklore::Japan",
      "Folklore::Japan::AmaterasuOmikami",
      "Folklore::Japan::Izumo",
      "Folklore::Japan::Kintaro",
      "Folklore::Japan::Kitsune",
      "Folklore::Japan::Kojiki",
      "Folklore::Japan::MomoTaro",
      "Folklore::Japan::NihonShoki",
      "Folklore::Japan::Okayama",
      "Folklore::Japan::Susanoo",
      "Folklore::Japan::Tanuki",
      "Folklore::Japan::Tengu",
      "Folklore::Japan::UrashimaTaro",
    ] );
    my $array = $obj->provides;

Sets or gets an array of module class names and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 resources

    $obj->resources( {
      bugtracker => {
        web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
      },
      repository => {
        type => "git",
        web => "https://gitlab.com/momotaro/Folklore-Japan",
      },
    } );
    my $this = $obj->resources;
    $obj->resources->bugtracker( {
      web => "https://gitlab.com/momotaro/Folklore-Japan/issues",
    } );
    my $bugtracker_obj = $obj->resources->bugtracker;
    my $homepage_obj = $obj->resources->homepage;
    my $array = $obj->resources->license;
    $obj->resources->repository( {
      type => "git",
      web => "https://gitlab.com/momotaro/Folklore-Japan",
    } );
    my $repository_obj = $obj->resources->repository;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Release::Resources> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<bugtracker> dynamic subclass (hash reference)

=over 8

=item * C<mailto> URI (L<uri object|URI>)

=item * C<type> string

=item * C<web> URI (L<uri object|URI>)

=back

=item * C<homepage> dynamic subclass (hash reference)

=over 8

=item * C<web> URI (L<uri object|URI>)

=back

=item * C<license> array (L<array object|Module::Generic::Array>)

=item * C<repository> dynamic subclass (hash reference)

=over 8

=item * C<type> string (L<scalar object|Module::Generic::Scalar>)

=item * C<url> URI (L<uri object|URI>)

=item * C<web> URI (L<uri object|URI>)

=back

=back

=head2 stat

    $obj->stat( {
      gid => 12345,
      mode => 33188,
      mtime => 1690618397,
      size => 10240,
      uid => 16790,
    } );
    my $this = $obj->stat;
    $obj->stat->gid( 12345 );
    my $integer = $obj->stat->gid;
    $obj->stat->mode( 33188 );
    my $integer = $obj->stat->mode;
    $obj->stat->mtime( 1690618397 );
    my $datetime = $obj->stat->mtime;
    $obj->stat->size( 10240 );
    my $integer = $obj->stat->size;
    $obj->stat->uid( 16790 );
    my $integer = $obj->stat->uid;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Release::Stat> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<gid> integer (L<number object|Module::Generic::Number>)

=item * C<mode> integer (L<number object|Module::Generic::Number>)

=item * C<mtime> datetime

=item * C<size> integer (L<number object|Module::Generic::Number>)

=item * C<uid> integer (L<number object|Module::Generic::Number>)

=back

=head2 status

    $obj->status( "latest" );
    my $string = $obj->status;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 tests

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Release::Tests> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<fail> integer (L<number object|Module::Generic::Number>)

=item * C<na> integer (L<number object|Module::Generic::Number>)

=item * C<pass> integer (L<number object|Module::Generic::Number>)

=item * C<unknown> integer (L<number object|Module::Generic::Number>)

=back

=head2 version

    $obj->version( "v1.2.3" );
    my $version = $obj->version;

Sets or gets a version value and returns a version object using L<Changes::Version>.

=head2 version_numified

    $obj->version_numified("1.002003");
    my $number = $obj->version_numified;

Sets or gets a float value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head1 API SAMPLE

    {
       "abstract" : "Japan Folklore Object Class",
       "archive" : "Folklore-Japan-v1.2.3.tar.gz",
       "author" : "MOMOTARO",
       "authorized" : true,
       "changes_file" : "CHANGES",
       "checksum_md5" : "71682907d95a4b0a4b74da8c16e88d2d",
       "checksum_sha256" : "27d4da9e772bc1922618b36fdefa768344d92c3d65a5e3cc427218cfc8d7491d",
       "date" : "2023-07-29T05:10:12",
       "dependency" : [
          {
             "module" : "ExtUtils::MakeMaker",
             "phase" : "configure",
             "relationship" : "requires",
             "version" : "0"
          },
          {
             "module" : "ExtUtils::MakeMaker",
             "phase" : "build",
             "relationship" : "requires",
             "version" : "0"
          },
          {
             "module" : "Module::Generic",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "v0.30.6"
          },
          {
             "module" : "DateTime::Format::JP",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "v0.1.3"
          },
          {
             "module" : "Mock::Person::JP",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "0.07"
          },
          {
             "module" : "Net::Airline::ANA",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "2.34"
          },
          {
             "module" : "Transport::Limousine::Bus",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "3.45"
          },
          {
             "module" : "Net::Reservation::KorakuenGarden",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "v0.2.3"
          },
          {
             "module" : "Net::Reservation::OkayamaCastle",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "4.03"
          },
          {
             "module" : "strict",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "0"
          },
          {
             "module" : "warnings",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "0"
          },
          {
             "module" : "parent",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "0"
          },
          {
             "module" : "perl",
             "phase" : "runtime",
             "relationship" : "requires",
             "version" : "5.026001"
          },
          {
             "module" : "Test::Pod",
             "phase" : "test",
             "relationship" : "requires",
             "version" : "1.52"
          },
          {
             "module" : "Test::More",
             "phase" : "test",
             "relationship" : "requires",
             "version" : "1.302162"
          }
       ],
       "deprecated" : false,
       "distribution" : "Folklore-Japan",
       "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v0.30.5.tar.gz",
       "first" : false,
       "id" : "Wo09n3d3er4s_56Of7_J8ap9an",
       "license" : [
          "perl_5"
       ],
       "main_module" : "Folklore::Japan",
       "maturity" : "released",
       "metadata" : {
          "abstract" : "Japan Folklore Object Class",
          "author" : [
             "Taro Momo <momo.taro@example.jp>"
          ],
          "dynamic_config" : 1,
          "generated_by" : "ExtUtils::MakeMaker version 7.64, CPAN::Meta::Converter version 2.150010, CPAN::Meta::Converter version 2.150005",
          "license" : [
             "perl_5"
          ],
          "meta-spec" : {
             "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
             "version" : 2
          },
          "name" : "Folklore-Japan",
          "no_index" : {
             "directory" : [
                "t",
                "inc",
                "t",
                "xt",
                "inc",
                "local",
                "perl5",
                "fatlib",
                "example",
                "blib",
                "examples",
                "eg"
             ]
          },
          "prereqs" : {
             "build" : {
                "requires" : {
                   "ExtUtils::MakeMaker" : "0"
                }
             },
             "configure" : {
                "requires" : {
                   "ExtUtils::MakeMaker" : "0"
                }
             },
             "runtime" : {
                "requires" : {
                   "DateTime::Format::JP" : "v0.1.3",
                   "ExtUtils::MakeMaker" : "0",
                   "Mock::Person::JP" : "0.07",
                   "Module::Generic" : "v0.30.6",
                   "Net::Airline::ANA" : "2.34",
                   "Net::Reservation::KorakuenGarden" : "v0.2.3",
                   "Net::Reservation::OkayamaCastle" : "4.03",
                   "Test::More" : "1.302162",
                   "Test::Pod" : "1.52",
                   "Transport::Limousine::Bus" : "3.45",
                   "parent" : "0",
                   "perl" : "5.026001",
                   "strict" : "0",
                   "warnings" : "0"
                }
             },
             "test" : {
                "requires" : {
                   "Test::More" : "1.302162",
                   "Test::Pod" : "1.52",
                }
             }
          },
          "release_status" : "stable",
          "resources" : {
             "bugtracker" : {
                "web" : "https://gitlab.com/momotaro/Folklore-Japan/issues"
             },
             "repository" : {
                "type" : "git",
                "web" : "https://gitlab.com/momotaro/Folklore-Japan"
             },
             "homepage" : {
                "web" : "https://www.okayama-japan.jp/en/feature/momotaro"
             }
          },
          "version" : "v1.2.3",
       },
       "name" : "Folklore-Japan-v1.2.3",
       "provides" : [
          "Folklore::Japan",
          "Folklore::Japan::AmaterasuOmikami",
          "Folklore::Japan::Izumo",
          "Folklore::Japan::Kintaro",
          "Folklore::Japan::Kitsune",
          "Folklore::Japan::Kojiki",
          "Folklore::Japan::MomoTaro",
          "Folklore::Japan::NihonShoki",
          "Folklore::Japan::Okayama",
          "Folklore::Japan::Susanoo",
          "Folklore::Japan::Tanuki",
          "Folklore::Japan::Tengu",
          "Folklore::Japan::UrashimaTaro",
       ],
       "resources" : {
          "bugtracker" : {
             "web" : "https://gitlab.com/momotaro/Folklore-Japan/issues"
          },
          "repository" : {
             "type" : "git",
             "web" : "https://gitlab.com/momotaro/Folklore-Japan"
          }
       },
       "stat" : {
          "gid" : 12345,
          "mode" : 33188,
          "mtime" : 1690618397,
          "size" : 10240,
          "uid" : 16790
       },
       "status" : "latest",
       "version" : "v1.2.3",
       "version_numified" : 1.002003
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

