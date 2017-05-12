use Plack::Loader;

Plack::Loader.auto('port', 5000).run(-> $env {
    [200, [], ['ok']]
});
