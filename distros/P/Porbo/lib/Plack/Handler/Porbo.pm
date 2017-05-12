package Plack::Handler::Porbo;
use strict;
use Porbo::Server;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, $app) = @_;
    Porbo::Server->new(%{$self})->run($app);
}

1;
