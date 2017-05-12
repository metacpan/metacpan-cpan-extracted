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
plugin 'TimeAgo' => { default => 'en' };


get '/' => sub {
    my $self = shift;
    $self->render( text => $self->time_ago(DateTime->now) );
};

get '/not-datetime' => sub {
    my $self = shift;
    $self->render( text => $self->time_ago(""));
};

##############################
## test plugin
##############################
my $t = Test::Mojo->new;

# use test
use_ok 'Mojolicious::Plugin::TimeAgo'; 

$t->get_ok('/')
    ->status_is(200)
    ->content_is('just now');

$t->get_ok('/not-datetime')
    ->status_is(200)
    ->content_is('');

done_testing();

