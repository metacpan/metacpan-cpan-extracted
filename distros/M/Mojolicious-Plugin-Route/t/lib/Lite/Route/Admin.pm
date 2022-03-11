package Lite::Route::Admin;
use Mojo::Base 'MojoX::Route';

sub under {
    my ($self, $r) = @_;

    my $under = $r->under('/admin' => sub {
        my $c = shift;

        return 1 if $c->req->url->to_abs->userinfo eq 'Admin:Password';
        
        $c->res->headers->www_authenticate('Basic');
        $c->render(text => 'Authentication required!', status => 401);
        
        return;
    });
}

sub route {
    my ($self, $under_above, $r) = @_;
    
    $r->get('/login' => sub {
        shift->render(text => 'Login');
    });
    
    $under_above->get('/' => sub {
        shift->render(text => 'Admin');
    });
}

1;
