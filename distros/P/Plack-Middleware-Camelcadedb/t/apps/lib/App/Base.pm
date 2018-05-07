package App::Base;

use strict;
use warnings;

use Plack::Request;

sub app {
    my ($env) = @_;
    my $req = Plack::Request->new($env);
    my $name = $req->parameters->{name} // 'world';

    return [ 200, [], ["Hello, ", $name] ];
};

1;
