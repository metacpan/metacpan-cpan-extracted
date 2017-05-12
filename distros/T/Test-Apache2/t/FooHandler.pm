package t::FooHandler;
use strict;
use warnings;
use Apache2::Const;

sub handler :method {
    my ($class_or_obj, $req) = @_;

    $req->content_type('text/plain');
    $req->print('hello world');
    return Apache2::Const::OK;
}

1;
