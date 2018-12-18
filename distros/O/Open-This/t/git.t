use strict;
use warnings;

use Git::Helpers qw( is_inside_work_tree );
use Open::This qw( maybe_get_url_from_parsed_text );
use Test::More;
use Test::Requires::Git;
use URI ();

test_requires_git();

SKIP: {
    skip 'must be inside Git checkout', 1 unless is_inside_work_tree();
    is( maybe_get_url_from_parsed_text(), undef, 'undef on undef' );
    is( maybe_get_url_from_parsed_text( {} ), undef, 'undef on empty hash' );

    my $url = maybe_get_url_from_parsed_text(
        { file_name => 'lib/Open/This.pm' } );
    ok( $url, 'got url' );
    my $uri = URI->new($url);
    ok( $uri->path =~ m{lib/Open/This.pm\z}, 'path' );
    is( $uri->scheme, 'https', 'scheme' );
}

done_testing();
