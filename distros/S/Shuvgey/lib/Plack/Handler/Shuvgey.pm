package Plack::Handler::Shuvgey;
use strict;
use warnings;
use Shuvgey::Server;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    Shuvgey::Server->new( %{ shift() } )->run(shift);
}

1;
