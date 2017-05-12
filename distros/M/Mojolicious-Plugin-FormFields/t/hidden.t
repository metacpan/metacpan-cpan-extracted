use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 7;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/hidden' => sub { render_input(shift, 'hidden') };

my %base_attr = (id => 'user-name', name => 'user.name', type => 'hidden');
my $t = Test::Mojo->new;
$t->get_ok('/hidden')->status_is(200);
is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', { %base_attr, value => 'sshaw' }); 

$t->get_ok('/hidden?user.name=xxx')->status_is(200);
is_field_attrs($t, 'input', { %base_attr, value => 'xxx' }); 
