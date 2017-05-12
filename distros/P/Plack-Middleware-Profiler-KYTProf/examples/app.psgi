use Plack::Builder;
use Text::Xslate;

my $app = sub {
    my $env = shift;
    my $tx  = Text::Xslate->new;

    my $template = q{
        <h1>hello</h1>
        <ul>
        </ul>
    };

    print $tx->render_string( $template, {} );

    return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
};

builder {
    enable "Plack::Middleware::Profiler::KYTProf";
    $app;
};
