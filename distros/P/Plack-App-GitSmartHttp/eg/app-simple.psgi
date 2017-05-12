use File::Spec;
use File::Basename;
use lib File::Spec->catdir( dirname(__FILE__), '..', 'extlib', 'lib', 'perl5' );
use lib File::Spec->catdir( dirname(__FILE__), '..', 'lib' );
use Plack::Builder;
use Plack::App::GitSmartHttp;

builder {
    enable "Plack::Middleware::AccessLog", format => "combined";
    Plack::App::GitSmartHttp->new(
        root          => 'repos',
        git_path      => '/usr/bin/git',
        upload_pack   => 1,
        received_pack => 1
    )->to_app;
};
