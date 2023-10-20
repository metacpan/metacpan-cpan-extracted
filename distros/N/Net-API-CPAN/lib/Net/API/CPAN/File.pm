##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/File.pm
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
package Net::API::CPAN::File;
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
    $self->{author}           = [] unless( CORE::exists( $self->{author} ) );
    $self->{authorized}       = undef unless( CORE::exists( $self->{authorized} ) );
    $self->{binary}           = undef unless( CORE::exists( $self->{binary} ) );
    $self->{category}         = undef unless( CORE::exists( $self->{category} ) );
    $self->{date}             = undef unless( CORE::exists( $self->{date} ) );
    $self->{deprecated}       = undef unless( CORE::exists( $self->{deprecated} ) );
    $self->{description}      = undef unless( CORE::exists( $self->{description} ) );
    $self->{dir}              = undef unless( CORE::exists( $self->{dir} ) );
    $self->{directory}        = undef unless( CORE::exists( $self->{directory} ) );
    $self->{dist_fav_count}   = undef unless( CORE::exists( $self->{dist_fav_count} ) );
    $self->{distribution}     = undef unless( CORE::exists( $self->{distribution} ) );
    $self->{documentation}    = undef unless( CORE::exists( $self->{documentation} ) );
    $self->{download_url}     = undef unless( CORE::exists( $self->{download_url} ) );
    $self->{id}               = undef unless( CORE::exists( $self->{id} ) );
    $self->{indexed}          = undef unless( CORE::exists( $self->{indexed} ) );
    $self->{level}            = undef unless( CORE::exists( $self->{level} ) );
    $self->{maturity}         = undef unless( CORE::exists( $self->{maturity} ) );
    $self->{mime}             = undef unless( CORE::exists( $self->{mime} ) );
    $self->{module}           = [] unless( CORE::exists( $self->{module} ) );
    $self->{name}             = undef unless( CORE::exists( $self->{name} ) );
    $self->{object}           = 'file';
    $self->{path}             = undef unless( CORE::exists( $self->{path} ) );
    $self->{pod}              = undef unless( CORE::exists( $self->{pod} ) );
    $self->{pod_lines}        = [] unless( CORE::exists( $self->{pod_lines} ) );
    $self->{release}          = [] unless( CORE::exists( $self->{release} ) );
    $self->{sloc}             = undef unless( CORE::exists( $self->{sloc} ) );
    $self->{slop}             = undef unless( CORE::exists( $self->{slop} ) );
    $self->{stat}             = undef unless( CORE::exists( $self->{stat} ) );
    $self->{status}           = undef unless( CORE::exists( $self->{status} ) );
    $self->{suggest}          = undef unless( CORE::exists( $self->{suggest} ) );
    $self->{version}          = '' unless( CORE::exists( $self->{version} ) );
    $self->{version_numified} = undef unless( CORE::exists( $self->{version_numified} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        abstract author authorized binary category date deprecated description dir
        directory dist_fav_count distribution documentation download_url id indexed level
        maturity mime module name path pod pod_lines release sloc slop stat status suggest
        version version_numified
    )];
    return( $self );
}

sub abstract { return( shift->_set_get_scalar_as_object( 'abstract', @_ ) ); }

sub author { return( shift->_set_get_scalar_or_object( 'author', 'Net::API::CPAN::Author', @_ ) ); }

sub authorized { return( shift->_set_get_boolean( 'authorized', @_ ) ); }

sub binary { return( shift->_set_get_boolean( 'binary', @_ ) ); }

sub category { return( shift->_set_get_scalar_as_object( 'category', @_ ) ); }

sub date { return( shift->_set_get_datetime( 'date', @_ ) ); }

sub deprecated { return( shift->_set_get_boolean( 'deprecated', @_ ) ); }

sub description { return( shift->_set_get_scalar_as_object( 'description', @_ ) ); }

sub dir { return( shift->_set_get_scalar_as_object( 'dir', @_ ) ); }

sub directory { return( shift->_set_get_boolean( 'directory', @_ ) ); }

sub dist_fav_count { return( shift->_set_get_number( 'dist_fav_count', @_ ) ); }

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

sub documentation { return( shift->_set_get_scalar_as_object( 'documentation', @_ ) ); }

sub download_url { return( shift->_set_get_uri( 'download_url', @_ ) ); }

sub id { return( shift->_set_get_scalar_as_object( 'id', @_ ) ); }

sub indexed { return( shift->_set_get_boolean( 'indexed', @_ ) ); }

sub level { return( shift->_set_get_number( 'level', @_ ) ); }

sub maturity { return( shift->_set_get_scalar_as_object( 'maturity', @_ ) ); }

sub mime { return( shift->_set_get_scalar_as_object( 'mime', @_ ) ); }

sub module { return( shift->_set_get_class_array_object( 'module', {
    associated_pod => "scalar_as_object",
    authorized => "boolean",
    indexed => "boolean",
    name => "scalar_as_object",
    version => "scalar_as_object",
    version_numified => "number",
}, @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub path { return( shift->_set_get_scalar_as_object( 'path', @_ ) ); }

sub pod { return( shift->_set_get_scalar_as_object( 'pod', @_ ) ); }

sub pod_lines { return( shift->_set_get_array_as_object( 'pod_lines', @_ ) ); }

sub release { return( shift->_set_get_scalar_or_object( 'release', 'Net::API::CPAN::Release', @_ ) ); }

sub sloc { return( shift->_set_get_number( 'sloc', @_ ) ); }

sub slop { return( shift->_set_get_number( 'slop', @_ ) ); }

sub stat { return( shift->_set_get_class( 'stat', {
    gid => "integer",
    mode => "integer",
    mtime => "datetime",
    size => "integer",
    uid => "integer",
}, @_ ) ); }

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

sub suggest { return( shift->_set_get_class( 'suggest', {
    input => "array_as_object",
    payload => "hash_as_object",
    weight => "integer",
}, @_ ) ); }

sub version { return( shift->_set_get_version( { class => "Changes::Version", field => "version" }, @_ ) ); }

sub version_numified { return( shift->_set_get_number( 'version_numified', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::File - Meta CPAN API File Class

=head1 SYNOPSIS

    use Net::API::CPAN::File;
    my $obj = Net::API::CPAN::File->new( {
      abstract => "Japan Folklore Object Class",
      author => "MOMOTARO",
      authorized => \1,
      binary => \0,
      date => "2023-07-29T05:10:12",
      deprecated => \0
    ,
      description => "Folklore::Japan is a totally fictious perl 5 module designed to serve as an example for the MetaCPAN API.",
      directory => \0
    ,
      dist_fav_count => 1,
      distribution => "Folklore::Japan",
      documentation => "Folklore::Japan",
      download_url => "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
      id => "l0tsOf1192fuN100",
      indexed => \1
    ,
      level => 1,
      maturity => "released",
      mime => "text/x-script.perl-module",
      module => [
        {
          associated_pod => "MOMOTARO/Folklore-Japan-v1.2.3/lib/Folklore/Japan.pm",
          authorized => \1
    ,
          indexed => \1
    ,
          name => "Folklore::Japan",
          version => "v1.2.3",
          version_numified => "1.002003",
        },
      ],
      name => "Japan.pm",
      path => "lib/Folklore/Japan.pm",
      pod => "NAME Folklore::Japan - Japan Folklore Object Class VERSION version v1.2.3 SYNOPSIS use Folklore::Japan; my \$fun = Folklore::Japan->new; DESCRIPTION This is an imaginary class object to Japan folklore to only serve as dummy example AUTHOR Momo Taro <momo.taro\@example.jp> COPYRIGHT AND LICENSE This software is copyright (c) 2023 by Okayama, Inc.. This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.",
      pod_lines => [
        [
          1192,
          1868,
        ],
      ],
      release => "Folklore-Japan-v1.2.3",
      sloc => 202,
      slop => 637,
      stat => {
        gid => 12345,
        mode => 33188,
        mtime => 1690618397,
        size => 10240,
        uid => 16790,
      },
      status => "latest",
      suggest => {
        input => [
          "Folklore::Japan",
        ],
        payload => {
          doc_name => "Folklore::Japan",
        },
        weight => 985,
      },
      version => "v1.2.3",
      version_numified => "1.002003",
    } ) || die( Net::API::CPAN::File->error );
    
    my $string = $obj->abstract;
    # Returns a scalar object when this is a string, or an Net::API::CPAN::Author object
    my $author = $obj->author;
    my $bool = $obj->authorized;
    my $bool = $obj->binary;
    my $string = $obj->category;
    my $date = $obj->date;
    my $bool = $obj->deprecated;
    my $string = $obj->description;
    my $string = $obj->dir;
    my $bool = $obj->directory;
    my $num = $obj->dist_fav_count;
    my $string = $obj->distribution;
    my $string = $obj->documentation;
    my $uri = $obj->download_url;
    my $string = $obj->id;
    my $bool = $obj->indexed;
    my $num = $obj->level;
    my $string = $obj->maturity;
    my $string = $obj->mime;
    my $array = $obj->module;
    foreach my $this ( @$array )
    {
        my $scalar = $this->associated_pod;
        my $boolean = $this->authorized;
        my $boolean = $this->indexed;
        my $scalar = $this->name;
        my $scalar = $this->version;
        my $number = $this->version_numified;
    }
    my $string = $obj->name;
    my $str = $obj->object;
    my $string = $obj->path;
    my $string = $obj->pod;
    my $array = $obj->pod_lines;
    # Returns a scalar object when this is a string, or an Net::API::CPAN::Release object
    my $release = $obj->release;
    my $num = $obj->sloc;
    my $num = $obj->slop;
    my $this = $obj->stat;
    my $integer = $obj->stat->gid;
    my $integer = $obj->stat->mode;
    my $datetime = $obj->stat->mtime;
    my $integer = $obj->stat->size;
    my $integer = $obj->stat->uid;
    my $string = $obj->status;
    my $this = $obj->suggest;
    my $array = $obj->suggest->input;
    my $hash = $obj->suggest->payload;
    my $integer = $obj->suggest->weight;
    my $vers = $obj->version;
    my $num = $obj->version_numified;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate files.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::File> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 abstract

    $obj->abstract( "Japan Folklore Object Class" );
    my $string = $obj->abstract;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 author

    $obj->author( "MOMOTARO" );
    # Returns a scalar object when this is a string, or an Net::API::CPAN::Author object
    my $author = $obj->author;

Sets or gets either a string or an L<Net::API::CPAN::Author> object, and returns either a L<scalar object|Module::Generic::Array> or an L<Net::API::CPAN::Author object|Net::API::CPAN::Author>, or C<undef> if nothing was set.

=head2 authorized

    $obj->authorized(1);
    my $bool = $obj->authorized;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 binary

    $obj->binary(1);
    my $bool = $obj->binary;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 category

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 date

    $obj->date( "2023-07-29T05:10:12" );
    my $datetime_obj = $obj->date;

Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.

=head2 deprecated

    $obj->deprecated(1);
    my $bool = $obj->deprecated;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 description

    $obj->description( "Folklore::Japan is a totally fictious perl 5 module designed to serve as an example for the MetaCPAN API." );
    my $string = $obj->description;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 dir

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 directory

    $obj->directory(1);
    my $bool = $obj->directory;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 dist_fav_count

    $obj->dist_fav_count(1);
    my $number = $obj->dist_fav_count;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head2 distribution

    $obj->distribution( "Folklore::Japan" );
    my $string = $obj->distribution;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 documentation

    $obj->documentation( "Folklore::Japan" );
    my $string = $obj->documentation;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 download_url

    $obj->download_url( "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz" );
    my $uri = $obj->download_url;

Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.

=head2 id

    $obj->id( "l0tsOf1192fuN100" );
    my $string = $obj->id;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 indexed

    $obj->indexed(1);
    my $bool = $obj->indexed;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 level

    $obj->level(1);
    my $number = $obj->level;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head2 maturity

    $obj->maturity( "released" );
    my $string = $obj->maturity;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 mime

    $obj->mime( "text/x-script.perl-module" );
    my $string = $obj->mime;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 module

    $obj->module( [
      {
        associated_pod => "MOMOTARO/Folklore-Japan-v1.2.3/lib/Folklore/Japan.pm",
        authorized => \1,
        indexed => $VAR1->[0]{authorized},
        name => "Folklore::Japan",
        version => "v1.2.3",
        version_numified => "1.002003",
      },
    ] );
    my $array = $obj->module;
    foreach my $this ( @$array )
    {
        $this->associated_pod( "MOMOTARO/Folklore-Japan-v1.2.3/lib/Folklore/Japan.pm" );
        my $scalar = $this->associated_pod;
        $this->authorized( \1 );
        my $boolean = $this->authorized;
        $this->indexed( \1 );
        my $boolean = $this->indexed;
        $this->name( "Folklore::Japan" );
        my $scalar = $this->name;
        $this->version( "v1.2.3" );
        my $scalar = $this->version;
        $this->version_numified( 1.002003 );
        my $number = $this->version_numified;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::File::Module> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::File::Module> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<associated_pod> scalar_as_object

=item * C<authorized> boolean (L<boolean object|Module::Generic::Boolean>)

=item * C<indexed> boolean (L<boolean object|Module::Generic::Boolean>)

=item * C<name> scalar_as_object

=item * C<version> scalar_as_object

=item * C<version_numified> number

=back

=head2 name

    $obj->name( "Japan.pm" );
    my $string = $obj->name;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<file>

=head2 path

    $obj->path( "lib/Folklore/Japan.pm" );
    my $string = $obj->path;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 pod

    $obj->pod( "NAME Folklore::Japan - Japan Folklore Object Class VERSION version v1.2.3 SYNOPSIS use Folklore::Japan; my \$fun = Folklore::Japan->new; DESCRIPTION This is an imaginary class object to Japan folklore to only serve as dummy example AUTHOR Momo Taro <momo.taro\@example.jp> COPYRIGHT AND LICENSE This software is copyright (c) 2023 by Okayama, Inc.. This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself." );
    my $string = $obj->pod;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 pod_lines

    $obj->pod_lines( [
      [
        1192,
        1868,
      ],
    ] );
    my $array = $obj->pod_lines;

Sets or gets an array of pod_lines and returns an L<array object|Module::Generic::Array>, even if there is no value.

=head2 release

    $obj->release( "Folklore-Japan-v1.2.3" );
    # Returns a scalar object when this is a string, or an Net::API::CPAN::Release object
    my $release = $obj->release;

Sets or gets either a string or an L<Net::API::CPAN::Release> object, and returns either a L<scalar object|Module::Generic::Array> or an L<Net::API::CPAN::Release object|Net::API::CPAN::Release>, or C<undef> if nothing was set.

=head2 sloc

    $obj->sloc(202);
    my $number = $obj->sloc;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head2 slop

    $obj->slop(637);
    my $number = $obj->slop;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

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

Sets or gets a dynamic class object with class name C<Net::API::CPAN::File::Stat> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

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

=head2 suggest

    $obj->suggest( {
      input => [
        "Folklore::Japan",
      ],
      payload => {
        doc_name => "Folklore::Japan",
      },
      weight => 985,
    } );
    my $this = $obj->suggest;
    $obj->suggest->input( [
      "Folklore::Japan",
    ] );
    my $array = $obj->suggest->input;
    $obj->suggest->payload( {
      doc_name => "Folklore::Japan",
    } );
    my $hash = $obj->suggest->payload;
    $obj->suggest->weight( 985 );
    my $integer = $obj->suggest->weight;

Sets or gets a dynamic class object with class name C<Net::API::CPAN::File::Suggest> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

=over 4

=item * C<input> array (L<array object|Module::Generic::Array>)

=item * C<payload> hash_as_object

=item * C<weight> integer (L<number object|Module::Generic::Number>)

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
       "author" : "MOMOTARO",
       "authorized" : true,
       "binary" : false,
       "date" : "2023-07-29T05:10:12",
       "deprecated" : false,
       "description" : "Folklore::Japan is a totally fictious perl 5 module designed to serve as an example for the MetaCPAN API.",
       "directory" : false,
       "dist_fav_count" : 1,
       "distribution" : "Folklore::Japan",
       "documentation" : "Folklore::Japan",
       "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
       "id" : "l0tsOf1192fuN100",
       "indexed" : true,
       "level" : 1,
       "maturity" : "released",
       "mime" : "text/x-script.perl-module",
       "module" : [
          {
             "associated_pod" : "MOMOTARO/Folklore-Japan-v1.2.3/lib/Folklore/Japan.pm",
             "authorized" : true,
             "indexed" : true,
             "name" : "Folklore::Japan",
             "version" : "v1.2.3",
             "version_numified" : 1.002003
          }
       ],
       "name" : "Japan.pm",
       "path" : "lib/Folklore/Japan.pm",
       "pod" : "NAME Folklore::Japan - Japan Folklore Object Class VERSION version v1.2.3 SYNOPSIS use Folklore::Japan; my $fun = Folklore::Japan->new; DESCRIPTION This is an imaginary class object to Japan folklore to only serve as dummy example AUTHOR Momo Taro <momo.taro@example.jp> COPYRIGHT AND LICENSE This software is copyright (c) 2023 by Okayama, Inc.. This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.",
       "pod_lines" : [
          [
             1192,
             1868
          ]
       ],
       "release" : "Folklore-Japan-v1.2.3",
       "sloc" : 202,
       "slop" : 637,
       "stat" : {
          "gid" : 12345,
          "mode" : 33188,
          "mtime" : 1690618397,
          "size" : 10240,
          "uid" : 16790
       },
       "status" : "latest",
       "suggest" : {
          "weight" : 985,
          "payload" : {
             "doc_name" : "Folklore::Japan"
          },
          "input" : [
             "Folklore::Japan"
          ]
       },
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

