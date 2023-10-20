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
    use_ok( 'Net::API::CPAN::Diff' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Diff->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Diff' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Diff->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Diff.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'diff' );
can_ok( $obj, 'object' );
can_ok( $obj, 'source' );
can_ok( $obj, 'statistics' );
can_ok( $obj, 'target' );

is( $obj->diff, $test_data->{diff}, 'diff' );
is( $obj->source, $test_data->{source}, 'source' );
$this = $obj->statistics;
isa_ok( $this => 'Module::Generic::Array', 'statistics returns an array object' );
is( $obj->target, $test_data->{target}, 'target' );

done_testing();

__END__
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
