use strict;
use warnings;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use File::Spec::Functions;

get '/' => 'front';
# plugin alias => { '/people/fry/photos' => $FindBin::Bin };


# plugin alias => { '/people/fry/photos' => $FindBin::Bin };

my $t = Test::Mojo->new(app);
$t->app->static->paths([catdir($FindBin::Bin, 'public')]);

plugin alias => { '/people' => {classes => ['main']} }; # order doesn't really matter - ?
plugin alias => { '/people/fry/photos' => catdir($FindBin::Bin, 'frang', 'zoop') };
plugin alias => { '/people/leela' => { paths => [ catdir($FindBin::Bin, 'frang') ] } };
plugin alias => { '/people/leela/photos' =>
      { paths => [
                   catdir( $FindBin::Bin, 'frang', 'zoop' ),
                   catdir( $FindBin::Bin, 'public' )
                 ] } };

plugin alias => { '/people/bender/photos' =>
      { paths => [
                   catdir( $FindBin::Bin, 'public' ),
                   catdir( $FindBin::Bin, 'frang', 'zoop' )
                 ] } };
plugin  alias => { '/images' => catdir( $FindBin::Bin, 'frang', 'zoop' ),
                   '/css' =>  catdir($FindBin::Bin, 'frang') } ;

$t->get_ok('/')->content_like(qr/Phone Numbers/);
for my $path (qw(/cat.png /people/fry/photos/cat.png)) {
     $t->get_ok($path)->status_is(200)->content_type_is('image/png');
}

$t->get_ok('/say.txt')->content_is("GLOOM\n");
$t->get_ok('/people/leela/say.txt')->content_is("DOOM\n");


$t->get_ok('/people/say.txt')->status_is(200)->content_is("ROOM!\n");
$t->get_ok('/people/leela/photos/cat.png')->status_is(200);
$t->get_ok('/people/leela/photos/cat.json')->status_is(200)->json_is('/mood', 'grumpy');

$t->get_ok('/people/bender/photos/cat.png')->status_is(200);
$t->get_ok('/people/bender/photos/cat.json')->status_is(200)->json_is('/mood', 'happy');
# file not found - should return file not found error
$t->get_ok('/people/bender/photos/cat.jpg')->status_is(404);
$t->get_ok('/images/cat.png')->status_is(200);
$t->get_ok('/css/say.txt')->status_is(200)->content_is("DOOM\n");

done_testing();

__DATA__

@@ front.html.ep
<html>
<body>
<img src="cat.png" alt="not really an image">
<a href="/people/phones.txt">Phone Numbers</a>
<img src="/people/fry/photos/cat.png">
</body>
</html>

@@ say.txt
ROOM!
