use strict;
use warnings;
use Plack::Builder;
use Plack::App::SourceViewer;

builder {
    mount "/source" => Plack::App::SourceViewer->new(root => \@INC)->to_app;
    mount "/"     => sub { [200, [], ['OK']  ] };
};
