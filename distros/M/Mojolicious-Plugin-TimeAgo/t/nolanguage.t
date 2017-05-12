use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use DateTime;

use FindBin;
use lib "$FindBin::Bin/../lib";


##############################
## web app
##############################
plugin 'TimeAgo'; # no lang set

get '/' => sub {
    my $self = shift;
    $self->render( text => $self->time_ago(DateTime->now) );
};

get '/lang-stash' => sub {
    my $self = shift;
    $self->render( text => $self->stash('lang_default') || '' );
};

get '/nolang-stash' => sub {
    my $self = shift;
    $self->stash(lang_default => undef );
    $self->render( text => $self->stash('lang_default') || '' );
};


##############################
## test plugin
##############################
my $t = Test::Mojo->new;

# use test
use_ok 'Mojolicious::Plugin::TimeAgo'; 

$t->get_ok('/lang-stash')
    ->status_is(200)
    ->content_is('en');

$t->get_ok('/nolang-stash')
    ->status_is(200)
    ->content_is('');


done_testing();
