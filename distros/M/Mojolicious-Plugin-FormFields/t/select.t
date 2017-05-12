use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 28;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/select' => sub { render_input(shift, 'select', input => [ [qw|a b|] ]) };
get '/select_with_options' => sub { render_input(shift, 'select', input => [ [qw|a b|], 'data-x' => 'x' ]) };
get '/select_with_fields_value_selected' => sub {
    render_input(shift, 'select', input => [ [qw|a sshaw|] ])
};

my %base_attr = (id => 'user-name', name => 'user.name');
my $t = Test::Mojo->new;
$t->get_ok('/select')->status_is(200);

is_field_count($t, 'select', 1);
is_field_attrs($t, 'select', \%base_attr);
is_field_count($t, 'option', 2);
is_field_attrs($t, 'select :nth-child(1)', { value => 'a' });
is_field_attrs($t, 'select :nth-child(2)', { value => 'b' });

$t->get_ok('/select_with_options')->status_is(200);

is_field_count($t, 'select', 1);
is_field_attrs($t, 'select', { %base_attr, 'data-x' => 'x' });
is_field_count($t, 'option', 2);
is_field_attrs($t, 'select :nth-child(1)', { value => 'a' });
is_field_attrs($t, 'select :nth-child(2)', { value => 'b' });

$t->get_ok('/select_with_fields_value_selected')->status_is(200);
is_field_count($t, 'select', 1);
is_field_attrs($t, 'select', \%base_attr);
is_field_count($t, 'option', 2);
is_field_attrs($t, 'select :nth-child(1)', { value => 'a' });
# field()'s object arg has a user.name of 'sshaw';
is_field_attrs($t, 'select :nth-child(2)', { selected => 'selected', value => 'sshaw' });

$t->get_ok('/select_with_fields_value_selected?user.name=a')->status_is(200);
is_field_attrs($t, 'select :nth-child(1)', { selected => "selected", value => 'a' });
is_field_attrs($t, 'select :nth-child(2)', { value => 'sshaw' });

# '123' is not in the select list
$t->get_ok('/select_with_fields_value_selected?user.name=123')->status_is(200);
$t->element_exists_not('option[selected="selected"]');
