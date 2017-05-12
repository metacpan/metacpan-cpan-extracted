use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

plugin 'AdvancedMod';

get 'button';

# button_to
diag("Tag: button_to");
my $button_to = $t->get_ok('/button')->tx->res->dom;
is $button_to->at('form')->attr('action'), '/api', 'action';
is $button_to->at('form')->attr('method'), 'post', 'method';
is $button_to->at('form')->attr('class'), 'foo bar', 'class';
is $button_to->tree->[1][3][1][4][2]{name}, 'user', 'user field name';
is $button_to->tree->[1][3][1][4][2]{value}, 'root', 'user field value';
is $button_to->tree->[1][3][1][5][2]{name}, 'password', 'password field name';
is $button_to->tree->[1][3][1][5][2]{value}, 'q1w2e3', 'password field value';
is $button_to->tree->[1][3][1][6][2]{type}, 'submit', 'submit type';
is $button_to->tree->[1][3][1][6][2]{value}, 'GoGo', 'submit value';
is $button_to->tree->[1][3][1][6][2]{class}, 'btn', 'submit class';

done_testing();

__DATA__
@@ button.html.ep
%== button_to 'GoGo', action => '/api', class => 'foo bar', data => [qw/user root password q1w2e3/], submit_class => 'btn'


