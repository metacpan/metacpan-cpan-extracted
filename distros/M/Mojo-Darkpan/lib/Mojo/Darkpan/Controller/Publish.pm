package Mojo::Darkpan::Controller::Publish;
use v5.20;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use File::Copy ();
use File::Spec;
use File::Temp ();
use OrePAN2::Injector;
use OrePAN2::Indexer;
use Data::Dumper;
use Mojo::Darkpan::Util;
use Nice::Try;

sub upload($self) {
    my $util = Mojo::Darkpan::Util->new(controller => $self);
    
    try {
        if ($util->authorized) {
            $util->publish();
            $self->render(text => 'OK');
        }
    }
    catch($e) {
        my ($message, $location) = split(' at ', $e->message);
        $self->render(
            text   => "unable to process upload, bad or missing parameters: $message",
            status => '400'
        );
    };

}

1;