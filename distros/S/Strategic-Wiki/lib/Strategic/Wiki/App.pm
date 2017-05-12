package Strategic::Wiki::App;
use Mouse;
use Git::Wrapper;
use YAML::XS;
use Try::Tiny;
use Class::Throwable qw(Error);
use Strategic::Wiki::Config;
# use XXX;

has config => (
    is => 'ro',
    builder => sub {Strategic::Wiki::Config->new()},
);

sub handle_init {
    my $self = shift;
    throw Error "Can't init. Already is a wiki."
        if $self->config->is_wiki;
}

sub _config_build {
    return Strategic::Wiki::Config->new();
}

1;
