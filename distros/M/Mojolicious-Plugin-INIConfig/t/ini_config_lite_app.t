use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More 'no_plan';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Mojolicious::Lite;
use Test::Mojo;

# Default
app->config(section => {it => 'works'});
is_deeply app->config, {section => {it => 'works'}}, 'right value';

# Load plugins
my $config
  = plugin i_n_i_config => {default => {section => {foo => 'baz', hello => 'there'}}};
plugin INIConfig => {file =>
    abs_path(catfile(dirname(__FILE__), 'ini_config_lite_app_abs.ini'))};
is $config->{section}{foo},          'bar',            'right value';
is $config->{section}{hello},        'there',          'right value';
is $config->{section}{utf},          'утф',         'right value';
is $config->{section}{absolute},     'works too!',     'right value';
is $config->{section}{absolute_dev}, 'dev works too!', 'right value';
is app->config->{section}{foo},          'bar',            'right value';
is app->config->{section}{hello},        'there',          'right value';
is app->config->{section}{utf},          'утф',         'right value';
is app->config->{section}{absolute},     'works too!',     'right value';
is app->config->{section}{absolute_dev}, 'dev works too!', 'right value';
is app->config('section')->{foo},          'bar',            'right value';
is app->config('section')->{hello},        'there',          'right value';
is app->config('section')->{utf},          'утф',         'right value';
is app->config('section')->{absolute},     'works too!',     'right value';
is app->config('section')->{absolute_dev}, 'dev works too!', 'right value';
is app->config('section')->{it},           'works',          'right value';

get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is("barbarbar\n");

# No config file, default only
$config
  = plugin INIConfig => {file => 'nonexistent', default => {section => {foo => 'qux'}}};
is $config->{section}{foo}, 'qux', 'right value';
is app->config->{section}{foo}, 'qux', 'right value';
is app->config('section')->{foo}, 'qux',   'right value';
is app->config('section')->{it},  'works', 'right value';

# No config file, no default
{
  ok !(eval { plugin INIConfig => {file => 'nonexistent'} }),
    'no config file';
  local $ENV{MOJO_CONFIG} = 'nonexistent';
  ok !(eval { plugin 'INIConfig' }), 'no config file';
}

__DATA__
@@ index.html.ep
<%= $config->{section}{foo} %><%= config->{section}{foo} %><%= config('section')->{foo} %>
