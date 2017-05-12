use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 15;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/label' => sub { render_input(shift, 'label') }; 
get '/label_with_content' => sub { render_input(shift, 'label', input => ['content']) }; 
get '/label_with_content_escaped' => sub { render_input(shift, 'label', input => ['Gin & Juice']) }; 
get '/label_with_block_content' => sub { render_input(shift, 'label', input => [sub{'BLOCK'}]) }; 
get '/label_with_options' => sub { 
    render_input(shift, 'label', input => ['UserName', id => 'id-X', class => 'x']);
}; 

my $t = Test::Mojo->new;
$t->get_ok('/label')
    ->status_is(200)
    ->content_is('<label for="user-name">Name</label>');

$t->get_ok('/label_with_content')
    ->status_is(200)
    ->content_is('<label for="user-name">content</label>');

$t->get_ok('/label_with_content_escaped')
    ->status_is(200)
    ->content_is('<label for="user-name">Gin &amp; Juice</label>');

$t->get_ok('/label_with_block_content')
    ->status_is(200)
    ->content_is('<label for="user-name">BLOCK</label>');

$t->get_ok('/label_with_options')
    ->status_is(200)
    ->element_exists('label[for="user-name"][id="id-X"][class="x"]');

