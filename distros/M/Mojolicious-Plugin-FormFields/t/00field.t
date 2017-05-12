use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 30;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/with_object_as_target' => sub {
    my $self = shift;
    $self->stash(user => user());
    $self->render(text => $self->field('user.name'));
};

get '/with_hash_as_target' => sub {
    my $self = shift;
    $self->stash(user => { name => 'skye' });
    $self->render(text => $self->field('user.name'));
};

get '/with_array_as_target' => sub {
    my $self = shift;
    my @users = ({ name => 'coelinha' });
    $self->stash(users => \@users);
    $self->render(text => $self->field('users.0.name'));
};

get '/with_hash_argument_as_target' => sub {
    my $self = shift;
    my $object = { name => 'xxx' };
    $self->stash(user => user());
    # should use $object not user()
    $self->render(text => $self->field('user.name', $object));
};

get '/with_object_argument_as_target' => sub {
    my $self = shift;
    my $object = user(name => 'xxx');
    $self->stash(user => user());
    # should use $object not user()
    $self->render(text => $self->field('user.name', $object));
};

# Error cases
get '/with_a_missing_param_name' => sub {
    shift->field
};

get '/with_a_invalid_param_name' => sub {
    shift->field('not_in_stash')->text
};

get '/with_a_non_reference'=> sub {
    shift->field('x.y', 123)->text
};

get '/with_a_non_existant_accessor' => sub {
    shift->field('user.x', user())->text
};

get '/array_with_a_non_numeric_index' => sub {
    shift->field('array.x', [])->text
};

my $t = Test::Mojo->new;
$t->get_ok('/with_object_as_target')
    ->status_is(200)
    ->content_is('sshaw');

$t->get_ok('/with_hash_as_target')
    ->status_is(200)
    ->content_is('skye');

$t->get_ok('/with_array_as_target')
    ->status_is(200)
    ->content_is('coelinha');

$t->get_ok('/with_hash_argument_as_target')
    ->status_is(200)
    ->content_is('xxx');

$t->get_ok('/with_object_argument_as_target')
    ->status_is(200)
    ->content_is('xxx');

$t->get_ok('/with_a_missing_param_name')
    ->status_is(500)
    ->content_like(qr/name required/);

$t->get_ok('/with_a_invalid_param_name')
    ->status_is(500)
    ->content_like(qr/nothing in the stash/);

$t->get_ok('/with_a_non_reference')
    ->status_is(500)
    ->content_like(qr/not a reference/);

$t->get_ok('/with_a_non_existant_accessor')
    ->status_is(500)
    ->content_like(qr/on a User/);

$t->get_ok('/array_with_a_non_numeric_index')
    ->status_is(500)
    ->content_like(qr/non-numeric index/);

__DATA__
@@ exception.html.ep
%= stash('exception')
