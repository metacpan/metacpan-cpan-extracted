
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

# makes sure the element class used in testing is working

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 8;

use_ok( 'Element', 'can load Element' );

my $e = Element->new( tag => 'foo', parent => undef );
is( "$e", '<foo/>', 'simple element stringifies correctly' );

for my $tag (qw(a b c)) {
    my $child = Element->new( tag => $tag, parent => $e );
    push @{ $e->children }, $child;
}
is( "$e", '<foo><a/><b/><c/></foo>', 'complex element stringifies correctly' );

$e->attributes->{bar} = 'quux';
is( "$e", '<foo bar="quux"><a/><b/><c/></foo>', 'added attribute correctly' );

is( $e->attribute('bar'), 'quux', 'got attribute value correctly' );

ok( $e->has_attribute('bar'), 'has_attribute acknowledges existing attribute' );

ok( !$e->has_attribute('baz'),
    'has_attribute denies existence of non-existant attribute' );

is( $e->child(0)->to_string, '<a/>', 'got child correctly' );
