use Mojolicious::Lite;
use Plack::Builder;

get '/' => 'index';

builder {
    enable "Profiler::KYTProf", 
        enable_profile_if => sub { $$ % 11 == 0 },
        profiles => [
            # See Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine
            'Your::Profile::SomeModule1',
            'Your::Profile::SomeModule2'
        ],
        threshold => 100,
        # KYTProf logger
        logger => YourConfig->get_logger()
    ;
    app->start;
};

__DATA__

@@ index.html.ep
<html><body>Hello World</body></html>
