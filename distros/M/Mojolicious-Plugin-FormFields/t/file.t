use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 4;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/file' => sub { render_input(shift, 'file') }; 

my $t = Test::Mojo->new;
$t->get_ok('/file')->status_is(200);

is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', { type => 'file', name  => 'user.name', id => 'user-name' });
