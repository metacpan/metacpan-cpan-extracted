use Mojo::Base -strict;
use Mojolicious::Lite;
use Test::More tests => 12;
use Test::Mojo;

sub qs { join '&', @_ }

my $qs;
my $t = Test::Mojo->new;

get '/params_are_expanded' => sub {
    my $self   = shift;
    my $params = {
	hash   => $self->param('hash'),
	scalar => $self->param('scalar'),
	array  => $self->can('every_param') ? $self->every_param('array') : [ $self->param('array') ]
    };


    $self->render(params => $params);
};

get '/flattened_params_still_exist';
get '/no_params' => sub { shift->render(text => 'ok!') };

plugin 'ParamExpand';

$qs = qs 'hash.a=a',
	 'hash.b.c=b',
	 'array.0=0',
	 'array.1=1',
	 'scalar=scalar';

$t->get_ok("/params_are_expanded?$qs")
    ->status_is(200)
    ->content_like(qr/\Qa,b|0,1|scalar/);

$t->get_ok("/flattened_params_still_exist?$qs")
    ->status_is(200)
    ->content_like(qr/\Qa,b|0,1/);

$t->get_ok('/no_params')
    ->status_is(200)
    ->content_is('ok!');


plugin 'ParamExpand', separator => ',';

$qs = qs 'hash,a=a',
	 'hash,b,c=b',
	 'array,0=0',
	 'array,1=1',
	 'scalar=scalar';

$t->get_ok("/params_are_expanded?$qs")
    ->status_is(200)
    ->content_like(qr/\Qa,b|0,1|scalar/);

__DATA__
@@ params_are_expanded.html.ep
<% my @a = @{ $params->{array} }; %>
<%= $params->{hash}->{a} %>,<%= $params->{hash}->{b}->{c} %>|<%= $a[0] %>,<%= $a[1] %>|<%= $params->{scalar} %>

@@ flattened_params_still_exist.html.ep
<%= param('hash.a') %>,<%= param('hash.b.c') %>|<%= param('array.0') %>,<%= param('array.1') %>
