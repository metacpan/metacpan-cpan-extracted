use SVN::Web;

# load config
SVN::Web::load_config('config.yaml');

my $handler = sub { SVN::Web->run_psgi(@_) };

# uncomment this __END__ if you dont want to have plack deliver /css
#__END__

use Plack::Builder;
use Plack::App::Directory;

my $css = Plack::App::Directory->new({ root => './css' })->to_app;

builder {

    mount '/css' => $css,

    mount '/' => $handler,

}
