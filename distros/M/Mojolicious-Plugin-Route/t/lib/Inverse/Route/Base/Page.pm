package Inverse::Route::Base::Page;
use Mojo::Base 'MojoX::Route';
 
sub under {
    my ($self, $r, $base) = @_;
 
    $base->under('/page');
}    
 
sub route {    
    my ($self, $r, $base, $under_above) = @_;
     
    # /base/page/foo
    $under_above->get('/foo' => sub {
        shift->render(text => 'Foo');
    }); 
     
    # /base/bar
    $base->get('/bar' => sub {
        shift->render(text => 'Bar');
    });
     
    # /baz
    $r->get('/baz' => sub {
        shift->render(text => 'Baz');
    });                       
}
 
1;
