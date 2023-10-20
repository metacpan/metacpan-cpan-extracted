#!perl
# This test file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic;
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::Module' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Module->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Module' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Module->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Module.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'abstract' );
can_ok( $obj, 'author' );
can_ok( $obj, 'authorized' );
can_ok( $obj, 'binary' );
can_ok( $obj, 'date' );
can_ok( $obj, 'deprecated' );
can_ok( $obj, 'description' );
can_ok( $obj, 'dir' );
can_ok( $obj, 'directory' );
can_ok( $obj, 'dist_fav_count' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'documentation' );
can_ok( $obj, 'download_url' );
can_ok( $obj, 'id' );
can_ok( $obj, 'indexed' );
can_ok( $obj, 'level' );
can_ok( $obj, 'maturity' );
can_ok( $obj, 'metacpan_url' );
can_ok( $obj, 'mime' );
can_ok( $obj, 'module' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'package' );
can_ok( $obj, 'path' );
can_ok( $obj, 'permission' );
can_ok( $obj, 'pod' );
can_ok( $obj, 'pod_lines' );
can_ok( $obj, 'release' );
can_ok( $obj, 'sloc' );
can_ok( $obj, 'slop' );
can_ok( $obj, 'stat' );
can_ok( $obj, 'status' );
can_ok( $obj, 'suggest' );
can_ok( $obj, 'version' );
can_ok( $obj, 'version_numified' );

is( $obj->abstract, $test_data->{abstract}, 'abstract' );
is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->authorized;
if( defined( $test_data->{authorized} ) )
{
    is( $this => $test_data->{authorized}, 'authorized returns a boolean value' );
}
else
{
    ok( !$this, 'authorized returns a boolean value' );
}
$this = $obj->binary;
if( defined( $test_data->{binary} ) )
{
    is( $this => $test_data->{binary}, 'binary returns a boolean value' );
}
else
{
    ok( !$this, 'binary returns a boolean value' );
}
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
$this = $obj->deprecated;
if( defined( $test_data->{deprecated} ) )
{
    is( $this => $test_data->{deprecated}, 'deprecated returns a boolean value' );
}
else
{
    ok( !$this, 'deprecated returns a boolean value' );
}
is( $obj->description, $test_data->{description}, 'description' );
is( $obj->dir, $test_data->{dir}, 'dir' );
$this = $obj->directory;
if( defined( $test_data->{directory} ) )
{
    is( $this => $test_data->{directory}, 'directory returns a boolean value' );
}
else
{
    ok( !$this, 'directory returns a boolean value' );
}
$this = $obj->dist_fav_count;
is( $this => $test_data->{dist_fav_count}, 'dist_fav_count' );
if( defined( $test_data->{dist_fav_count} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'dist_fav_count returns a number object' );
}
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->documentation, $test_data->{documentation}, 'documentation' );
$this = $obj->download_url;
is( $this => $test_data->{download_url}, 'download_url' );
if( defined( $test_data->{download_url} ) )
{
    isa_ok( $this => 'URI', 'download_url returns an URI object' );
}
is( $obj->id, $test_data->{id}, 'id' );
$this = $obj->indexed;
if( defined( $test_data->{indexed} ) )
{
    is( $this => $test_data->{indexed}, 'indexed returns a boolean value' );
}
else
{
    ok( !$this, 'indexed returns a boolean value' );
}
$this = $obj->level;
is( $this => $test_data->{level}, 'level' );
if( defined( $test_data->{level} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'level returns a number object' );
}
is( $obj->maturity, $test_data->{maturity}, 'maturity' );
is( $obj->mime, $test_data->{mime}, 'mime' );
$this = $obj->module;
isa_ok( $this => 'Module::Generic::Array', 'module returns an array object' );
is( $obj->name, $test_data->{name}, 'name' );
is( $obj->path, $test_data->{path}, 'path' );
is( $obj->pod, $test_data->{pod}, 'pod' );
is( $obj->pod_lines, $test_data->{pod_lines}, 'pod_lines' );
is( $obj->release, $test_data->{release}, 'release' );
$this = $obj->sloc;
is( $this => $test_data->{sloc}, 'sloc' );
if( defined( $test_data->{sloc} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'sloc returns a number object' );
}
$this = $obj->slop;
is( $this => $test_data->{slop}, 'slop' );
if( defined( $test_data->{slop} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'slop returns a number object' );
}
$this = $obj->stat;
ok( Scalar::Util::blessed( $this ), 'stat returns a dynamic class' );
is( $obj->status, $test_data->{status}, 'status' );
$this = $obj->suggest;
ok( Scalar::Util::blessed( $this ), 'suggest returns a dynamic class' );
$this = $obj->version;
is( $this, $test_data->{version}, 'version' );
$this = $obj->version_numified;
is( $this => $test_data->{version_numified}, 'version_numified' );
if( defined( $test_data->{version_numified} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'version_numified returns a number object' );
}

done_testing();

__END__
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
