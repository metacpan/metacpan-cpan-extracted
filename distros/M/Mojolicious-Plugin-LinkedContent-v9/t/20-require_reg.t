use Mojo::Base -strict;

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

plugin 'LinkedContent::v9';

get '/require_reg' => sub {
    my $self = shift;
    $self->render('require_reg');
};

$t->get_ok('/require_reg')->status_is(200)
    ->content_like(qr/bootstrap\.min\.js/, 'Bootstrap library found')
    ->content_like(qr/bootstrap\.min\.css/, 'Bootstrap CSS found')
    ->content_like(qr/jquery\.min\.js/, 'JQuery dependence found');


done_testing();

__DATA__
@@ require_reg.html.ep
% require_reg	'bootstrap';

%== include_js;
%== include_css;
