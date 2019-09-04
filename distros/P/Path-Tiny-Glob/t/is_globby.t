use Test2::V0;

use Path::Tiny::Glob qw/ is_globby /;

my %tests = (
    './foo/bar' => 0,
    './foo/*/bar' =>  1,
    './foo/this?/bar' => 1,
);

plan tests => scalar keys %tests;

while( my( $string, $globby ) = each %tests ) {
    is is_globby($string), !!$globby, $string;
}
