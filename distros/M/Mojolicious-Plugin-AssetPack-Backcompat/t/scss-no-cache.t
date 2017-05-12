BEGIN { $ENV{MOJO_ASSETPACK_NO_CACHE} = 1 }
use lib '.';
use t::Helper;
use Mojo::File 'path';

my $file;
my $t = t::Helper->t_old({minify => 0});

plan skip_all => 'Could not find preprocessors for scss' unless $t->app->asset->preprocessors->can_process('scss');

$file = File::Spec->catfile($t->app->static->paths->[0], 'sass', 'no-cache.scss');
$t->app->asset('no-cache.css' => '/sass/no-cache.scss');

path($file)->spurt('@import "x.scss";');
$t->get_ok('/test1')->status_is(200)->content_like(qr{\#abcdef});

path($file)->spurt('@import "y.scss";');
$t->get_ok('/test1')->status_is(200)->content_like(qr{underline});

END { unlink $file }

done_testing;

__DATA__
@@ test1.html.ep
%= asset 'no-cache.css', {inline => 1}
