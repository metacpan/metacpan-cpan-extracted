use strict;
use Test::More;

use Plack::Builder;
use Plack::Test;
use Scope::Container;

sub container {
    if ( my $container = scope_container('key') ) {
        return $container;
    }
    else {
        my $container = {};
        scope_container('key',$container);
        return $container;
    }
}

my $app = builder {
  enable 'Scope::Container';
  sub {
    my $env = shift;
    my $val1 = container();
    my $val2 = container();
    ["200",["Content-Type"=>"text/plain"],["$val1 $val2"]];
  }
};


test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        ok( $res->is_success );
        my @content = split / /, $res->content;
        ok( $content[0] );
        is( $content[0], $content[1] );

        my $req2 = HTTP::Request->new(GET => "http://localhost/");
        my $res2 = $cb->($req2);
        ok( $res2->is_success );
        my @content2 = split / /, $res2->content;
        ok( $content2[0] );
        isnt( $content2[0], $content[0]);

    };

done_testing();

