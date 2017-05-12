use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'FormFields';

post '/single_field' => sub {
    my $c = shift;
    my $f = $c->field('name');
    $f->is_required;

    my $json = { valid => $f->valid, error => $f->error };
    $c->render(json => $json);
};

post '/multiple_fields' => sub {
    my $c = shift;
    $c->field('name')->is_required;
    $c->field('password')->is_required;

    my $json = { valid => $c->valid, errors => $c->errors };
    $c->render(json => $json);
};

post '/single_scoped_field' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->is_required('name');

    my $json = { valid => $user->valid, errors => $user->errors('name') };
    $c->render(json => $json);
};

post '/multiple_scoped_fields' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->is_required('name');
    $user->is_required('password');

    my $json = { valid => $user->valid, errors => $user->errors };
    $c->render(json => $json);
};

my $custom_rule = sub { $_[0] =~ /^sshaw$/ ?  undef : 'what what what' };
post '/custom_validation_rule' => sub {
    my $c = shift;
    $c->field('name')->check($custom_rule);

    my $json = { valid => $c->valid, errors => $c->errors };
    $c->render(json => $json);
};

post '/scoped_field_custom_validation_rule' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->check(name => $custom_rule);

    my $json = { valid => $user->valid, errors => $user->errors };
    $c->render(json => $json);
};

post '/validation_rules_can_be_chained' => sub {
    my $c = shift;
    $c->field('name')->is_required->is_like(qr/\d/);
    $c->field('password')->is_like(qr/\d/)->is_required;

    my $json = { valid => $c->valid, errors => $c->errors };
    $c->render(json => $json);
};

post '/scoped_validation_rules_can_be_chained' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->is_required('name')->is_like(name => qr/\d/);
    $user->is_like(password => qr/\d/)->is_required('password');

    my $json = { valid => $c->valid, errors => $user->errors };
    $c->render(json => $json);
};

post '/is_equal' => sub {
    my $c = shift;
    $c->field('password')->is_required->is_equal('confirm_password');

    my $json = { valid => $c->valid, errors => $c->errors };
    $c->render(json => $json);
};

post '/scoped_field_is_equal' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->is_required('password')->is_equal(password => 'confirm_password');

    my $json = { valid => $user->valid, errors => $user->errors };
    $c->render(json => $json);
};

my $t = Test::Mojo->new;
$t->post_ok('/single_field')->status_is(200)->json_is({valid => 0, error => 'Required'});
$t->post_ok('/single_field',
	    form => { name => 'sshaw' })->status_is(200)->json_is({valid => 1, error => undef});

$t->post_ok('/multiple_fields')->status_is(200)->json_is({valid => 0, errors => { 'name' => 'Required', 'password' => 'Required' }});
$t->post_ok('/multiple_fields',
	    form => { name => 'sshaw', password => '@s5' })->status_is(200)->json_is({valid => 1, errors => {}});

$t->post_ok('/single_scoped_field')->status_is(200)->json_is({valid => 0, errors => 'Required'});
$t->post_ok('/single_scoped_field',
	    form => { 'user.name' => 'sshaw' })->status_is(200)->json_is({valid => 1, errors => undef});

$t->post_ok('/multiple_scoped_fields')->status_is(200)->json_is({valid => 0, errors => { 'name' => 'Required', 'password' => 'Required' }});
$t->post_ok('/multiple_scoped_fields',
	    form => { 'user.name' => 'sshaw', 'user.password' => 'piu piu piu' })->status_is(200)->json_is({valid => 1, errors => {}});


$t->post_ok('/custom_validation_rule',
	    form => { 'name' => 'fofinha' })->status_is(200)->json_is({valid => 0, errors => { 'name' => 'what what what' }});
$t->post_ok('/custom_validation_rule',
	    form => { 'name' => 'sshaw' })->status_is(200)->json_is({valid => 1, errors => {}});

$t->post_ok('/scoped_field_custom_validation_rule',
	    form => { 'user.name' => 'fofinha' })->status_is(200)->json_is({valid => 0, errors => { 'name' => 'what what what' }});
$t->post_ok('/scoped_field_custom_validation_rule',
	    form => { 'user.name' => 'sshaw' })->status_is(200)->json_is({valid => 1, errors => {}});

$t->post_ok('/validation_rules_can_be_chained',
	    form => { 'name' => 'ABC', 'password' => 'XYZ' })->status_is(200)->json_is({valid => 0,
											errors => { 'name' => 'Invalid value',
												    'password' => 'Invalid value' }});
$t->post_ok('/scoped_validation_rules_can_be_chained',
	    form => { 'user.name' => 'ABC', 'user.password' => 'XYZ' })->status_is(200)->json_is({valid => 0,
												  errors => { name => 'Invalid value',
													      password => 'Invalid value' }});
$t->post_ok('/is_equal',
	    form => { password => 'a', confirm_password => 'b' })->status_is(200)->json_is({valid => 0, errors => { password => 'Invalid value' }});
$t->post_ok('/is_equal',
	    form => { password => 'a', confirm_password => 'a' })->status_is(200)->json_is({valid => 1, errors => {}});

$t->post_ok('/scoped_field_is_equal',
	    form => { 'user.password' => 'a', 'user.confirm_password' => 'b' })->status_is(200)->json_is({valid => 0, errors => { password => 'Invalid value' }});
$t->post_ok('/scoped_field_is_equal',
	    form => { 'user.password' => 'a', 'user.confirm_password' => 'a' })->status_is(200)->json_is({valid => 1, errors => {}});

done_testing();
