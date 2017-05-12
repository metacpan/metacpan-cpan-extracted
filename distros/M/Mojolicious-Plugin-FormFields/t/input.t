use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 4;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

get '/input' => sub { render_input(shift, 'input', input => ['email']) };

my %base_attr = (type => 'email', id => 'user-name', name  => 'user.name', value => 'sshaw');
my $t = Test::Mojo->new;
$t->get_ok('/input')->status_is(200);

is_field_count($t, 'input', 1);
is_field_attrs($t, 'input', \%base_attr);
