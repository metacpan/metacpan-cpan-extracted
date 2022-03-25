package Inverse::Route::Base;
use Mojo::Base 'MojoX::Route';
 
sub under {
    my ($self, $r) = @_;
 
    $r->under('/base');
}  
 
1;
