use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::GitHub::WebHook;
use File::Temp;

use lib 't';

foreach my $hook ('Acme',['Acme'],'+GitHub::WebHook::Acme',{Acme => []}) {
    my $app = Plack::App::GitHub::WebHook->new(
        hook => $hook, access => 'all'
    );
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->( POST '/', Content => '{}' );
        is $res->code, 200, 'Ok';
    };
}

{
    my $hook = GitHub::WebHook::Acme->new;
    my $app = Plack::App::GitHub::WebHook->new( hook => $hook, access => 'all' );
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->( POST '/', Content => '{}' );
        is $res->code, 200, 'Ok';

        $hook->{status} = 0;
        $res = $cb->( POST '/', Content => '{}' );
        is $res->code, 202, 'Accepted';
    };    
}

{
    my $app = Plack::App::GitHub::WebHook->new( 
        hook => { Acme => [ status => 0 ] }, access => 'all' 
    );
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->( POST '/', Content => '{}' );
        is $res->code, 202, 'Accepted';
    };    
}

done_testing;
