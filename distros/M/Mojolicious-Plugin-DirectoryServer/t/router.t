use Mojolicious::Lite -strict;

use Test::More;
use Test::Mojo;
use Encode ();
use Mojo::File;

my $dir = Mojo::File->curfile->dirname;

plugin 'DirectoryServer',
    router => app->routes->under('/dir'),
    root   => $dir;

plugin 'DirectoryServer',
    router => app->routes->under('/file'),
    root   => $dir->child('dummy.txt');

my $t = Test::Mojo->new;

# Root is left alone
$t->get_ok('/')
    ->status_is(404);

subtest 'file' => sub {
    $t->get_ok('/file')
        ->status_is(200)
        ->content_like(qr/^DUMMY$/);

    $t->get_ok('/file/foo/bar/buz')
        ->status_is(200)
        ->content_like(qr/^DUMMY$/);
};

subtest 'dir' => sub {
    $t->get_ok('/dir')->status_is(200);

    $dir->list->map( to_rel => $dir )->each( sub {
        my $ent = Encode::decode_utf8($_);
        $t->content_like(qr/$ent/);
    });
};

done_testing;
