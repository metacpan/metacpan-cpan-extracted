package ExampleController;
use Moose;

sub root_GET {
    my ($self, $req) = @_;
    return $self->_view($req, 'a list of things');
}

sub root_PUT {
    my ($self, $req) = @_;
    return $self->_view($req, 'create thing');
}

sub item_GET {
    my ($self, $req, $id) = @_;
    return $self->_view($req, 'view thing '.$id);
}

sub item_POST {
    my ($self, $req, $id) = @_;
    return $self->_view($req, 'update thing '.$id);
}

sub hase {
    my ($self, $req) = @_;
    return $self->_view($req, 'hase');

}

sub link {
    my ($self, $req) = @_;
    return $self->_view($req, $req->uri_for({controller=>'thing',action=>'item', id=>'123'}));
}

sub _view {
    my ($self, $req, $data) = @_;
    return [
        200,
        [ 'Content-type' => 'text/html' ],
        [ $data ]
    ]
}


no Moose; 1;
__END__
