use Mojo::Base -strict;

use Test::More;    # tests => 14;
use lib 'lib';

use Mojolicious::Lite;
use Test::Mojo;

# Load plugin
plugin 'Mobi';

# All user agents can access this URL
get '/' => sub {
    my $self = shift;
    $self->render( text => $self->is_mobile ? 'mobile' : 'regular' );
};

# Only mobile devices can access this URL /mobile-only
get '/mobile-only' => ( mobile => 1 ) => sub {
    my $self = shift;
    $self->render( text => "over mobile" );
};

my $t = Test::Mojo->new;

# Test for no mobile
$t->get_ok('/')->content_is('regular');

# Some mobile devices test
$t->ua->transactor->name($_)
  and $t->get_ok('/')->content_is( 'mobile', "$_ test" )
  for (qw(nokia 1207 6310 blackberry iphone));

# Test for "over mobile"
$t->ua->transactor->name('iphone');
$t->get_ok('/mobile-only')->content_is('over mobile');

# Test for error 404 for non-mobile devices
$t->ua->transactor->name('something strange');
$t->get_ok('/mobile-only')->status_is(404);

done_testing();

