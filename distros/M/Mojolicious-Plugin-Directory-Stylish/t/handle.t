use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 3;
use Test::Mojo;

use File::Basename;
use File::Spec;
use Encode ();

my $dir = dirname(__FILE__);
plugin 'Directory::Stylish', root => $dir, handler => sub {
    my ($c, $path) = @_;
    $c->render( data => $path, format => 'txt' ) if (-f $path);
};

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    while ( defined( my $ent = $dh->read ) ) {
        $ent = Encode::decode_utf8($ent);
        next if $ent eq '.' or $ent eq '..';
        my $path = File::Spec->catdir( $dir, $ent );
        if (-f $path) {
            $t->get_ok("/$ent")->status_is(200)->content_is( Encode::encode_utf8($path) );
        }
        elsif (-d $path) {
            $t->get_ok("/$ent")->status_is(200)->content_like( qr/Parent Directory/ );
        }
        else { ok 0 }
    }
}
