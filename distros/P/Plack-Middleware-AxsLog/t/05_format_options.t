use strict;
use warnings;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Builder;
use Plack::Test;
use Test::More;

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', 
            format => '%z %{X_MYAPP_VARIABLE}Z', 
            format_options => +{
                char_handlers => +{
                    'z' => sub { 'z' },
                },
                block_handlers => +{
                    'Z' => sub { 'Z' },
                },
            },
            logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            is $log, qq!z Z\n!;
        };
}

done_testing();

