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
    use_ok( 'Net::API::CPAN::Changes' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Changes->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Changes' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Changes->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Changes.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'authorized' );
can_ok( $obj, 'binary' );
can_ok( $obj, 'category' );
can_ok( $obj, 'content' );
can_ok( $obj, 'date' );
can_ok( $obj, 'deprecated' );
can_ok( $obj, 'directory' );
can_ok( $obj, 'dist_fav_count' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'download_url' );
can_ok( $obj, 'id' );
can_ok( $obj, 'indexed' );
can_ok( $obj, 'level' );
can_ok( $obj, 'maturity' );
can_ok( $obj, 'mime' );
can_ok( $obj, 'module' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'path' );
can_ok( $obj, 'pod' );
can_ok( $obj, 'pod_lines' );
can_ok( $obj, 'release' );
can_ok( $obj, 'sloc' );
can_ok( $obj, 'slop' );
can_ok( $obj, 'stat' );
can_ok( $obj, 'status' );
can_ok( $obj, 'version' );
can_ok( $obj, 'version_numified' );

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
is( $obj->category, $test_data->{category}, 'category' );
is( $obj->content, $test_data->{content}, 'content' );
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
$this = $obj->pod_lines;
ok( ( Scalar::Util::reftype( $this ) eq 'ARRAY' && Scalar::Util::blessed( $this ) ), 'pod_lines returns an array object' );
if( defined( $test_data->{pod_lines} ) )
{
    ok( scalar( @$this ) == scalar( @{$test_data->{pod_lines}} ), 'pod_lines -> array size matches' );
    for( my $i = 0; $i < @$this; $i++ )
    {
        is( $this->[$i], $test_data->{pod_lines}->[$i], 'pod_lines -> value offset $i' );
    }
}
else
{
    ok( !scalar( @$this ), 'pod_lines -> array is empty' );
}
is( $obj->release, $test_data->{release}, 'release' );
is( $obj->sloc, $test_data->{sloc}, 'sloc' );
is( $obj->slop, $test_data->{slop}, 'slop' );
$this = $obj->stat;
ok( Scalar::Util::blessed( $this ), 'stat returns a dynamic class' );
is( $obj->status, $test_data->{status}, 'status' );
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
   "author" : "MOMOTARO",
   "authorized" : true,
   "binary" : false,
   "category" : "changelog",
   "content" : "Revision history for Perl module Folklore::Japan\n\nv1.2.3 2023-07-29T09:12:10+0900\n    - Initial release\n",
   "date" : "2023-07-29T23:14:52",
   "deprecated" : false,
   "directory" : false,
   "distribution" : "Folklore-Japan",
   "download_url" : "https://cpan.metacpan.org/authors/id/M/MO/MOMOTARO/Folklore-Japan-v1.2.3.tar.gz",
   "id" : "Jp_IsS0oC00l_CoM3OveR",
   "indexed" : false,
   "level" : 0,
   "maturity" : "released",
   "mime" : "",
   "module" : [],
   "name" : "CHANGES",
   "path" : "CHANGES",
   "pod" : "",
   "pod_lines" : [],
   "release" : "Folklore-Japan-v1.2.3",
   "sloc" : 487,
   "slop" : 0,
   "stat" : {
      "mode" : 33188,
      "mtime" : 1690618397,
      "size" : 108
   },
   "status" : "latest",
   "version" : "v1.2.3",
   "version_numified" : 1.002003
}
