package Mojo::Darkpan::Controller::Index;
use v5.20;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use OrePAN2::Indexer;
use Data::Dumper;
use IO::Zlib;
use Mojo::Darkpan::Util;

sub list($self) {
    my $util = Mojo::Darkpan::Util->new(controller => $self);

    $self->render(json => $util->list) if ($util->authorized);
}

sub reindex($self) {
    my $util = Mojo::Darkpan::Util->new(controller => $self);

    $util->createIndex();

    $self->render(text => 'reindexing scheduled, may take some time to complete...') if ($util->authorized);
}


1;