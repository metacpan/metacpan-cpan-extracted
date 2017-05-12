use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 8;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/password' => sub { render_input(shift, 'password') };
get '/password_with_options' => sub { render_input(shift, 'password', input => [size => 10, maxlength => 20, id => 'pASS']) };

my %base_attr = (name => 'user.name', type => 'password');
my $t = Test::Mojo->new;
$t->get_ok('/password')->status_is(200);

is_field_count($t, 'input', 1);
# Mojolicious' password_field does not render a value attr
is_field_attrs($t, 'input', { %base_attr, id => 'user-name' }); 

$t->get_ok('/password_with_options')->status_is(200);

is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', { %base_attr, id => 'pASS', size => 10, maxlength => 20 }); 
