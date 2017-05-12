use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Builder;

use Plack::App::OpenVPN::Status;

sub my_custom_view { <<'EOTMPL' }
% my $vars = $_[0];
<html>
    <head>
        <title>Customized OpenVPN Status</title>
    </head>
    <body>
        <h1>Updated: <%= $vars->{updated} %>; Status Version #<%= $vars->{version} %></h1>
        <h2>Connected <%= scalar(@{$vars->{users}}) %> user(s)</h2>
    </body>
</html>
EOTMPL

eval { builder { Plack::App::OpenVPN::Status->new(status_from => 't/status-v1.log', custom_view => [])->to_app } };
like $@, qr/'custom_view' must be a CODEREF/, 'Got an invalid custom_view exception';

test_psgi
    app => Plack::App::OpenVPN::Status->new(status_from => 't/status-v1.log', custom_view => \&my_custom_view)->to_app,
    client => sub {
        my ($cb) = @_;
        my $res = $cb->(GET '/');
        is $res->code, 200, 'Customized view response code';
        like $res->content, qr|Customized OpenVPN Status|, 'Customized view title';
        like $res->content, qr|Updated: Tue Dec  4 11:05:56 2012|, 'Customized view status date, time';
    };

done_testing;
