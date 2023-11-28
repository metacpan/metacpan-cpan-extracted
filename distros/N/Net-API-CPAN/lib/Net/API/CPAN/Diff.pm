##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Diff.pm
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
package Net::API::CPAN::Diff;
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
    $self->{diff}       = undef unless( CORE::exists( $self->{diff} ) );
    $self->{object}     = 'diff';
    $self->{source}     = undef unless( CORE::exists( $self->{source} ) );
    $self->{statistics} = [] unless( CORE::exists( $self->{statistics} ) );
    $self->{target}     = undef unless( CORE::exists( $self->{target} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( diff source statistics target )];
    return( $self );
}

sub diff { return( shift->_set_get_scalar_as_object( 'diff', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub source { return( shift->_set_get_scalar_as_object( 'source', @_ ) ); }

sub statistics { return( shift->_set_get_class_array_object( 'statistics', {
    deletions => "integer",
    diff => "scalar_as_object",
    insertions => "integer",
    source => "scalar_as_object",
    target => "scalar_as_object",
}, @_ ) ); }

sub target { return( shift->_set_get_scalar_as_object( 'target', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Diff - Meta CPAN API Diff Class

=head1 SYNOPSIS

    use Net::API::CPAN::Diff;
    my $obj = Net::API::CPAN::Diff->new( {
      source => "MOMOTARO/Folklore-Japan-v1.2.2",
      statistics => [
        {
          deletions => 0,
          diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n\@\@ -2,5 +3,5 \@\@\n v0.1.1 2023-08-19T13:10:37+0900\n    - Updated name returned\n",
          insertions => 1,
          source => "MOMOTARO/Folklore-Japan-v1.2.2/CHANGES",
          target => "MOMOTARO/Folklore-Japan-v1.2.3/CHANGES",
        },
        {
          deletions => 1,
          diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n\@\@ -32 +32 \@\@\n - The versioning style used is dotted decimal, such as `v0.1.0`\n + The versioning style used is dotted decimal, such as `v0.1.1`\n",
          insertions => 1,
          source => "MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md",
          target => "MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md",
        },
        {
          deletions => 5,
          diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n\@\@ -3 +3 \@\@\n - ## Version v0.1.0\n + Version v0.1.1\n\@\@ -7 +7 \@\@\n - ## Modified 2023/08/15\n + ## Modified 2023/08/19\n\@\@ -19 +19 \@\@\n - \$VERSION = 'v0.1.0';\n + \$VERSION = 'v0.1.1';\n\@\@ -29 +29 \@\@\n - sub name { return( \"John Doe\" ); }\n + sub name { return( \"Urashima Taro\" ); }\n\@\@ -48 + 48 \@\@\n -     v0.1.0\n +     v0.1.1",
          insertions => 5,
          source => "MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm",
          target => "MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm",
        },
        {
          deletions => 1,
          diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n\@\@ -60 +60 \@\@\n -    \"version\" : \"v0.1.0\",\n +    \"version\" : \"v0.1.1\",\n",
          insertions => 1,
          source => "MOMOTARO/Folklore-Japan-v1.2.2/META.json",
          target => "MOMOTARO/Folklore-Japan-v1.2.3/META.json",
        },
        {
          deletions => 1,
          diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n\@\@ -32 +32 \@\@\n - version: v0.1.0\n + version: v0.1.1\n",
          insertions => 1,
          source => "MOMOTARO/Folklore-Japan-v1.2.2/META.yml",
          target => "MOMOTARO/Folklore-Japan-v1.2.3/META.yml",
        },
      ],
      target => "MOMOTARO/Folklore-Japan-v1.2.3",
    } ) || die( Net::API::CPAN::Diff->error );
    
    my $string = $obj->diff;
    my $str = $obj->object;
    my $string = $obj->source;
    my $array = $obj->statistics;
    foreach my $this ( @$array )
    {
        my $integer = $this->deletions;
        my $scalar = $this->diff;
        my $integer = $this->insertions;
        my $scalar = $this->source;
        my $scalar = $this->target;
    }
    my $string = $obj->target;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate diffs.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Diff> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 diff

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 object

Returns the object type for this class, which is C<diff>

=head2 source

    $obj->source( "MOMOTARO/Folklore-Japan-v1.2.2" );
    my $string = $obj->source;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head2 statistics

    $obj->statistics( [
      {
        deletions => 0,
        diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n\@\@ -2,5 +3,5 \@\@\n v0.1.1 2023-08-19T13:10:37+0900\n    - Updated name returned\n",
        insertions => 1,
        source => "MOMOTARO/Folklore-Japan-v1.2.2/CHANGES",
        target => "MOMOTARO/Folklore-Japan-v1.2.3/CHANGES",
      },
      {
        deletions => 1,
        diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n\@\@ -32 +32 \@\@\n - The versioning style used is dotted decimal, such as `v0.1.0`\n + The versioning style used is dotted decimal, such as `v0.1.1`\n",
        insertions => 1,
        source => "MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md",
        target => "MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md",
      },
      {
        deletions => 5,
        diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n\@\@ -3 +3 \@\@\n - ## Version v0.1.0\n + Version v0.1.1\n\@\@ -7 +7 \@\@\n - ## Modified 2023/08/15\n + ## Modified 2023/08/19\n\@\@ -19 +19 \@\@\n - \$VERSION = 'v0.1.0';\n + \$VERSION = 'v0.1.1';\n\@\@ -29 +29 \@\@\n - sub name { return( \"John Doe\" ); }\n + sub name { return( \"Urashima Taro\" ); }\n\@\@ -48 + 48 \@\@\n -     v0.1.0\n +     v0.1.1",
        insertions => 5,
        source => "MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm",
        target => "MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm",
      },
      {
        deletions => 1,
        diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n\@\@ -60 +60 \@\@\n -    \"version\" : \"v0.1.0\",\n +    \"version\" : \"v0.1.1\",\n",
        insertions => 1,
        source => "MOMOTARO/Folklore-Japan-v1.2.2/META.json",
        target => "MOMOTARO/Folklore-Japan-v1.2.3/META.json",
      },
      {
        deletions => 1,
        diff => "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n\@\@ -32 +32 \@\@\n - version: v0.1.0\n + version: v0.1.1\n",
        insertions => 1,
        source => "MOMOTARO/Folklore-Japan-v1.2.2/META.yml",
        target => "MOMOTARO/Folklore-Japan-v1.2.3/META.yml",
      },
    ] );
    my $array = $obj->statistics;
    foreach my $this ( @$array )
    {
        $this->deletions( 0 );
        my $integer = $this->deletions;
        $this->diff( "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n\@\@ -2,5 +3,5 \@\@\n v0.1.1 2023-08-19T13:10:37+0900\n    - Updated name returned\n" );
        my $scalar = $this->diff;
        $this->insertions( 1 );
        my $integer = $this->insertions;
        $this->source( "MOMOTARO/Folklore-Japan-v1.2.2/CHANGES" );
        my $scalar = $this->source;
        $this->target( "MOMOTARO/Folklore-Japan-v1.2.3/CHANGES" );
        my $scalar = $this->target;
    }

Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::Diff::Statistics> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::Diff::Statistics> object will be instantiated with each value from the array provided and replace said value.

=over 4

=item * C<deletions> integer (L<number object|Module::Generic::Number>)

=item * C<diff> scalar_as_object

=item * C<insertions> integer (L<number object|Module::Generic::Number>)

=item * C<source> scalar_as_object

=item * C<target> scalar_as_object

=back

=head2 target

    $obj->target( "MOMOTARO/Folklore-Japan-v1.2.3" );
    my $string = $obj->target;

Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.

=head1 API SAMPLE

    {
       "source" : "MOMOTARO/Folklore-Japan-v1.2.2",
       "statistics" : [
          {
             "deletions" : 0,
             "diff" : "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CHANGES\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CHANGES\n@@ -2,5 +3,5 @@\n v0.1.1 2023-08-19T13:10:37+0900\n    - Updated name returned\n",
             "insertions" : 1,
             "source" : "MOMOTARO/Folklore-Japan-v1.2.2/CHANGES",
             "target" : "MOMOTARO/Folklore-Japan-v1.2.3/CHANGES"
          },
          {
             "deletions" : 1,
             "diff" : "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md\n@@ -32 +32 @@\n - The versioning style used is dotted decimal, such as `v0.1.0`\n + The versioning style used is dotted decimal, such as `v0.1.1`\n",
             "insertions" : 1,
             "source" : "MOMOTARO/Folklore-Japan-v1.2.2/CONTRIBUTING.md",
             "target" : "MOMOTARO/Folklore-Japan-v1.2.3/CONTRIBUTING.md"
          },
          {
             "deletions" : 5,
             "diff" : "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm\n@@ -3 +3 @@\n - ## Version v0.1.0\n + Version v0.1.1\n@@ -7 +7 @@\n - ## Modified 2023/08/15\n + ## Modified 2023/08/19\n@@ -19 +19 @@\n - $VERSION = 'v0.1.0';\n + $VERSION = 'v0.1.1';\n@@ -29 +29 @@\n - sub name { return( \"John Doe\" ); }\n + sub name { return( \"Urashima Taro\" ); }\n@@ -48 + 48 @@\n -     v0.1.0\n +     v0.1.1",
             "insertions" : 5,
             "source" : "MOMOTARO/Folklore-Japan-v1.2.2/lib/Foo/Bar.pm",
             "target" : "MOMOTARO/Folklore-Japan-v1.2.3/lib/Foo/Bar.pm"
          },
          {
             "deletions" : 1,
             "diff" : "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.json\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.json\n@@ -60 +60 @@\n -    \"version\" : \"v0.1.0\",\n +    \"version\" : \"v0.1.1\",\n",
             "insertions" : 1,
             "source" : "MOMOTARO/Folklore-Japan-v1.2.2/META.json",
             "target" : "MOMOTARO/Folklore-Japan-v1.2.3/META.json"
          },
          {
             "deletions" : 1,
             "diff" : "diff --git a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n--- a/var/tmp/source/MOMOTARO/Folklore-Japan-v1.2.2/META.yml\n+++ b/var/tmp/target/MOMOTARO/Folklore-Japan-v1.2.3/META.yml\n@@ -32 +32 @@\n - version: v0.1.0\n + version: v0.1.1\n",
             "insertions" : 1,
             "source" : "MOMOTARO/Folklore-Japan-v1.2.2/META.yml",
             "target" : "MOMOTARO/Folklore-Japan-v1.2.3/META.yml"
          }
       ],
       "target" : "MOMOTARO/Folklore-Japan-v1.2.3"
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

