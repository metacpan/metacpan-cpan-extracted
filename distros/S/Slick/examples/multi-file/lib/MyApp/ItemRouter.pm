package MyApp::ItemRouter;

use base qw(Slick::Router);

my $router = __PACKAGE__->new(base => '/items');

$router->get('/{id}' => sub {
    my ($app, $context) = @_;
    my $item = $app->database('items')->select_one({ id => $context->param('id') });
    $context->json($item);
});

$router->post('' => sub {
    my ($app, $context) = @_;
    my $new_item = $context->content;
    
    # Do some sort of validation
    if (not $app->helper('item_validator')->($new_item)) {
        $context->status(400)->json({ error => 'Bad Request' });
    } 
    else {
        $app->database('items')->insert('items', $new_item);
        $context->json($new_item);
    }
});

sub router {
    return $router;
}

1;
