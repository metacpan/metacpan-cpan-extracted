use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 10;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/checkbox' => sub { render_input(shift, 'checkbox') };
get '/checkbox_with_value' => sub { render_input(shift, 'checkbox', input => ['sshaw']) };

my %base_attr = (type => 'checkbox', name  => 'user.name', id => 'user-name');
my $t = Test::Mojo->new;
$t->get_ok('/checkbox')->status_is(200);

is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', {  %base_attr, value => '1', id => 'user-name' });

$t->get_ok('/checkbox_with_value')->status_is(200);
is_field_attrs($t, 'input', { %base_attr, value => 'sshaw', checked => 'checked' });

$t->get_ok('/checkbox_with_value?user.name=xxx')->status_is(200);
is_field_attrs($t, 'input', { %base_attr, value => 'sshaw' });
