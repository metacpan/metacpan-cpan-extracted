package Strategic::Wiki::PSGI;
use Mouse;
use Class::Throwable qw(Error);

use Plack::Builder;
use Strategic::Wiki::App;

sub app {
    my $self = shift;

    my $webapp = Strategic::Wiki::App->new();
    throw Error "Strategic Wiki is not set up"
        unless $webapp->config->is_wiki;

    return builder {
        mount "/static/" =>
            Plack::App::File(root => $webapp->config->static_dir);
        mount "/" => $webapp->dispatch;
    };
}

1;
