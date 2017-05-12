use strict;
use warnings;
use utf8;

use Test::More;
use Net::Airbrake::Error;

use_ok 'Net::Airbrake::Request';

subtest 'conceal secure parametes' => sub {
    eval { die 'Oops' };
    my $error = Net::Airbrake::Error->new($@);
    my $req = Net::Airbrake::Request->new({
        errors => [ $error ],
        environment => {
            Cookie => 'awesomecookie',
        },
        params => {
            name     => 'myname',
            password => 'awesomepassword',
        },
    });
    ok $req;
    is $req->environment->{Cookie}, '*************';
    is $req->params->{name}, 'myname';
    is $req->params->{password}, '***************';
};

done_testing;
