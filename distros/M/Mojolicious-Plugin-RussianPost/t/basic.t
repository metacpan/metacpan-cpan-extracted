use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Mojo::Util qw(dumper);

get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');


#say dumper $t->;

done_testing();
