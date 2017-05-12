use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 11;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/text' => sub { render_input(shift, 'text') };
get '/text_with_options' => sub { render_input(shift, 'text', input => [size => 10, id => 'luser-mayne']) };

my %base_attr = (type => "text", id => 'user-name', name  => 'user.name', value => 'sshaw');
my $t = Test::Mojo->new;
$t->get_ok('/text')->status_is(200);

is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', \%base_attr);

$t->get_ok('/text?user.name=jkat')->status_is(200);
is_field_attrs($t, 'input', { %base_attr, value => 'jkat' });

$t->get_ok('/text_with_options')->status_is(200);
is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', { %base_attr, id => 'luser-mayne', size => 10 });
