use strict;
use warnings;
use Test::More 0.98;
use Test::Mojo;
use File::Temp ();
use Mojolicious;
use Mojo::File qw(path);

my $root = path( File::Temp::tempdir( CLEANUP => 1 ) );
$root->child('hello.txt')->spurt('hello');
$root->child('data.json')->spurt('{"a":1}');
$root->child('noext')->spurt('plain');
$root->child('a b.txt')->spurt('spaced');
$root->child('sub')->make_path->child('inner.txt')->spurt('inner');

sub tester {
    my %args = @_;
    my $app = Mojolicious->new;
    $app->log->level('fatal');
    $app->plugin( 'DirectoryHandler', { root => $root->to_string, delivery_path => 'files', %args } );
    return Test::Mojo->new($app);
}

subtest 'files' => sub {
    my $t = tester();
    $t->get_ok('/files/hello.txt')->status_is(200)->content_is('hello')->content_type_like(qr{text/plain});
    $t->get_ok('/files/data.json')->status_is(200)->content_type_like(qr{json})->content_is('{"a":1}');
    $t->get_ok('/files/noext')->status_is(200)->content_is('plain');
    $t->get_ok('/files/a%20b.txt')->status_is(200)->content_is('spaced');
    $t->get_ok('/files/sub/inner.txt')->status_is(200)->content_is('inner');
    $t->get_ok('/files/missing.txt')->status_is(404);
    $t->get_ok('/files/sub/missing.txt')->status_is(404);
};

subtest 'directory listings' => sub {
    my $t = tester();
    for my $p ( '/files', '/files/' ) {
        $t->get_ok($p)->status_is(200)->content_like(qr/Index of/)->content_like(qr{hello\.txt})
          ->content_like(qr{sub/});
    }

    $t->get_ok('/files/sub/')->status_is(200)->content_like(qr/inner\.txt/)
      ->content_like( qr/Parent Directory/, 'subdirectories link to their parent' );
};

subtest 'auto_index disabled' => sub {
    my $t = tester( auto_index => 0 );
    $t->get_ok('/files/sub/')->status_is(404);
    $t->get_ok('/files/hello.txt')->status_is(200)->content_is('hello');
};

subtest 'json listing' => sub {
    my $t = tester( json => 1 );
    $t->get_ok('/files/sub/' => { Accept => 'application/json' })->status_is(200)->content_type_like(qr{json})
      ->content_like(qr/inner\.txt/);
    $t->get_ok('/files/sub/')->status_is(200)->content_like( qr/Index of/, 'html is still the default' );
};

subtest 'handler callback' => sub {
    my @seen;
    my $t = tester( handler => sub { my ( $c, $path ) = @_; push @seen, "$path"; $c->render( text => 'handled' ) } );
    $t->get_ok('/files/hello.txt')->status_is(200)->content_is('handled');
    is scalar(@seen), 1, 'handler called once';
    like $seen[0], qr{hello\.txt$}, 'handler receives the resolved path';
};

subtest 'custom directory page' => sub {
    my $t = tester( dir_page => 'custom page for <%= $cur_path %>' );
    $t->get_ok('/files/sub/')->status_is(200)->content_like(qr{custom page for /files/sub/?});
};

subtest 'root that is a file' => sub {
    my $t = tester( root => $root->child('hello.txt')->to_string );
    $t->get_ok('/anything')->status_is(200)->content_is('hello');
};

subtest 'traversal inside the delivery path' => sub {
    my $t = tester();
    $t->get_ok('/files/sub/..%2fhello.txt')->status_is(404);
    $t->get_ok('/files/sub/%2e%2e/hello.txt')->status_is(404);
    $t->get_ok('/files/sub/..%5chello.txt')->status_is(404);
};

done_testing;
