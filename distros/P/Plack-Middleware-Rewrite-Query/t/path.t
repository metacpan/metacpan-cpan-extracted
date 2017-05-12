use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

unless ( eval { require Plack::Middleware::Rewrite; 1; } ) {
    plan skip_all => 'Plack::Middleware::Rewrite not installed';
}

use Plack::Middleware::Rewrite::Query qw(rewrite_query);

my $app = builder {
    enable 'Rewrite', rules => sub {
        if ( s{/([0-9]+)$}{} ) {
            my $id = $1;
            rewrite_query( $_[0], modify => sub { $_->set('id',$id) } );
        }    
    };
    sub {
        [ 200, ['Content-Type' => 'text/plain'], [
            $_[0]->{PATH_INFO}.'?'.$_[0]->{'QUERY_STRING'}
        ] ]
    };
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET "/path/123?format=xy");
    is $res->content, '/path?format=xy&id=123';
};

done_testing;
