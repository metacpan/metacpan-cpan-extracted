use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Mojolicious::Plugin::SecurityHeader;
use Test::Mojo;

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;

my $plugin = Mojolicious::Plugin::SecurityHeader->new;

{
    my $success = $plugin->register( $t );
    is $success, undef, 'No headers';
}

{
    my $success = $plugin->register( $t, undef );
    is $success, undef, 'undef headers';
}

{
    my $success = $plugin->register( $t, 'invalid' );
    is $success, undef, '"invalid" header';
}


$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');



done_testing();
