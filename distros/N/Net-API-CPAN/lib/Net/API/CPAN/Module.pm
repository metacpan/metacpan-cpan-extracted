##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Module.pm
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
package Net::API::CPAN::Module;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::File );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{abstract}         = undef unless( CORE::exists( $self->{abstract} ) );
    $self->{author}           = undef unless( CORE::exists( $self->{author} ) );
    $self->{authorized}       = undef unless( CORE::exists( $self->{authorized} ) );
    $self->{binary}           = undef unless( CORE::exists( $self->{binary} ) );
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
    $self->{object}           = 'module';
    $self->{path}             = undef unless( CORE::exists( $self->{path} ) );
    $self->{pod}              = undef unless( CORE::exists( $self->{pod} ) );
    $self->{pod_lines}        = undef unless( CORE::exists( $self->{pod_lines} ) );
    $self->{release}          = undef unless( CORE::exists( $self->{release} ) );
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
        abstract author authorized binary date deprecated description dir directory
        dist_fav_count distribution documentation download_url id indexed level maturity
        mime module name path pod pod_lines release sloc slop stat status suggest version
        version_numified
    )];
    return( $self );
}

# NOTE: sub abstract is inherited from Net::API::CPAN::File

# NOTE: sub author is inherited from Net::API::CPAN::File

# NOTE: sub authorized is inherited from Net::API::CPAN::File

# NOTE: sub binary is inherited from Net::API::CPAN::File

# NOTE: sub date is inherited from Net::API::CPAN::File

# NOTE: sub deprecated is inherited from Net::API::CPAN::File

# NOTE: sub description is inherited from Net::API::CPAN::File

# NOTE: sub dir is inherited from Net::API::CPAN::File

# NOTE: sub directory is inherited from Net::API::CPAN::File

# NOTE: sub dist_fav_count is inherited from Net::API::CPAN::File

# NOTE: sub distribution is inherited from Net::API::CPAN::File

# NOTE: sub documentation is inherited from Net::API::CPAN::File

# NOTE: sub download_url is inherited from Net::API::CPAN::File

# NOTE: sub id is inherited from Net::API::CPAN::File

# NOTE: sub indexed is inherited from Net::API::CPAN::File

# NOTE: sub level is inherited from Net::API::CPAN::File

# NOTE: sub maturity is inherited from Net::API::CPAN::File

sub metacpan_url
{
    my $self = shift( @_ );
    my $author = $self->author || 
        return( $self->error( "No module author is set to return a Meta CPAN URL for this module." ) );
    my $release = $self->release ||
        return( $self->error( "No module release is set to return a Meta CPAN URL for this module." ) );
    my $path = $self->path ||
        return( $self->error( "No module path is set to return a Meta CPAN URL for this module." ) );
    my $api_uri = $self->api->api_uri->clone;
    $api_uri->path( "/pod/$author/$release/$path" );
    return( $api_uri );
}

# NOTE: sub mime is inherited from Net::API::CPAN::File

# NOTE: sub module is inherited from Net::API::CPAN::File

# NOTE: sub name is inherited from Net::API::CPAN::File

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub package
{
    my $self = shift( @_ );
    my $doc = $self->documentation || 
        return( $self->error( "No documentation module class is set to call Net::API::CPAN->package" ) );
    my $result = $self->api->package( $doc ) || return( $self->pass_error );
    return( $result );
}

# NOTE: sub path is inherited from Net::API::CPAN::File

sub permission
{
    my $self = shift( @_ );
    my $doc = $self->documentation || 
        return( $self->error( "No documentation module class is set to call Net::API::CPAN->package" ) );
    my $result = $self->api->permission( $doc ) || return( $self->pass_error );
    return( $result );
}

# NOTE: sub pod is inherited from Net::API::CPAN::File

# NOTE: sub pod_lines is inherited from Net::API::CPAN::File

# NOTE: sub release is inherited from Net::API::CPAN::File

# NOTE: sub sloc is inherited from Net::API::CPAN::File

# NOTE: sub slop is inherited from Net::API::CPAN::File

# NOTE: sub stat is inherited from Net::API::CPAN::File

# NOTE: sub status is inherited from Net::API::CPAN::File

# NOTE: sub suggest is inherited from Net::API::CPAN::File

# NOTE: sub version is inherited from Net::API::CPAN::File

# NOTE: sub version_numified is inherited from Net::API::CPAN::File

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Module - Meta CPAN API Module Class

=head1 SYNOPSIS

    use Net::API::CPAN::Module;
    my $obj = Net::API::CPAN::Module->new( {
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
    } ) || die( Net::API::CPAN::Module->error );
    
    my $string = $obj->abstract;
    my $string = $obj->author;
    my $bool = $obj->authorized;
    my $bool = $obj->binary;
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
    my $uri = $obj->metacpan_url;
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
    my $this = $obj->package;
    my $string = $obj->path;
    my $this = $obj->permission;
    my $string = $obj->pod;
    my $string = $obj->pod_lines;
    my $string = $obj->release;
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

This class serves to retrieve and manipulate modules.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Module> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 abstract

    $obj->abstract( "Japan Folklore Object Class" );
    my $string = $obj->abstract;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 author

    $obj->author( "MOMOTARO" );
    my $string = $obj->author;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 authorized

    $obj->authorized(1);
    my $bool = $obj->authorized;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

=head2 binary

    $obj->binary(1);
    my $bool = $obj->binary;

Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.

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

=head2 metacpan_url

Returns a link, as an L<URI> object, to the module's page on MetaCPAN, or C<undef> if no module L<author|/author>, L<release|/release>. or L<path|/path> is currently set.

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

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Module::Module> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Module::Module> object will be instantiated with each value from the array provided and replace said value.

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

Returns the object type for this class, which is C<module>

=head2 package

Returns an L<Net::API::CPAN::Package> object for this module, or upon error, sets an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

An error is returned if the L<documentation property|/documentation> is not set.

=head2 path

    $obj->path( "lib/Folklore/Japan.pm" );
    my $string = $obj->path;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 permission

Returns an L<Net::API::CPAN::Permission> object for this module, or upon error, sets an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

An error is returned if the L<documentation property|/documentation> is not set.

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
    my $string = $obj->pod_lines;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 release

    $obj->release( "Folklore-Japan-v1.2.3" );
    my $string = $obj->release;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

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

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Module::Stat> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

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

Sets or gets a dynamic class object with class name C<Net::API::CPAN::Module::Suggest> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

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
       "version_numified" : "1.002003"
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

