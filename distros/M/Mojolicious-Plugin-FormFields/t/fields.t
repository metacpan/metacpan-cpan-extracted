use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 43;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/fields' => sub {
    my $self = shift;
    $self->stash(user => user());
    $self->render(f => $self->fields('user'));
};

get '/fields_with_target_object' => sub {
    my $self = shift;
    $self->render('fields', f => $self->fields('user', user()));
};

get '/fields_object' => sub {
    my $self = shift;
    my $fields = $self->fields('user', user());
    $self->render(text => $fields->object->name);
};

get '/collection_of_fields_object' => sub {
    my $self = shift;
    my $orders = orders($self);
    $self->render(text => join ',', map $_->object->{id}, @$orders);
};

get '/collection_of_fields_index' => sub {
    my $self = shift;
    my $orders = orders($self);
    $self->render(text => join ',', map $_->index, @$orders);
};

sub orders
{
    shift->fields('user', user())->fields('orders');
}

sub fields_exist
{
    my $t = shift;
    $t->element_exists('input[type="file"][name="user.name"][id="fff"]');
    $t->element_exists('input[type="checkbox"][name="user.admin"]');
    $t->element_exists('input[type="hidden"][name="user.admin"][value="1"]');
    $t->element_exists('label');
    $t->text_is('label','Name');
    $t->element_exists('input[type="password"][name="user.name"][size="10"]');
    $t->element_exists('input[type="radio"][value="yungsta"]');
    $t->element_exists('select[name="user.age"]');
    $t->element_exists('option[value="10"]');
    $t->element_exists('option[value="20"]');
    $t->element_exists('option[value="30"]');
    $t->element_exists('input[type="text"][name="user.name"][value="sshaw"][size="10"]');
    $t->element_exists('textarea[name="user.bio"][rows="20"]');
    $t->element_exists('input[type="hidden"][name="user.orders.0.id"][value="1"]');
    $t->element_exists('input[type="hidden"][name="user.orders.1.id"][value="2"]');
}

my $t = Test::Mojo->new;
$t->get_ok('/fields')->status_is(200);
fields_exist($t);

$t->get_ok('/fields_with_target_object')->status_is(200);
fields_exist($t);

$t->get_ok('/fields_object')
  ->status_is(200)
  ->content_is('sshaw');

$t->get_ok('/collection_of_fields_object')
  ->status_is(200)
  ->content_is('1,2');

$t->get_ok('/collection_of_fields_index')
  ->status_is(200)
  ->content_is('0,1');

__DATA__
@@ fields.html.ep
%= $f->file('name', id => 'fff')
%= $f->checkbox('admin')
%= $f->hidden('admin')
%= $f->label('name')
%= $f->password('name', size => 10)
%= $f->radio('age', 'yungsta')
%= $f->select('age', [10,20,30])
%= $f->text('name', size => 10)
%= $f->textarea('bio', rows => '20')
% for(@{$f->fields('orders')}) {
    %= $_->hidden('id');
% }
