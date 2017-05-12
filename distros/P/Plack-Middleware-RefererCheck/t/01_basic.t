use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Cwd;

my $default_handler = builder {
    enable "RefererCheck", no_warn => 1;
    sub { ['200', ['Content-Type' => 'text/html'], ['hello world']] };
};
my $host_handler = builder {
    enable "RefererCheck", no_warn => 1, host => 'www.example.com';
    sub { ['200', ['Content-Type' => 'text/html'], ['hello world']] };
};
my $same_scheme_handler = builder {
    enable "RefererCheck", no_warn => 1, same_scheme => 1;
    sub { ['200', ['Content-Type' => 'text/html'], ['hello world']] };
};
my $error_app_handler = builder {
    enable "RefererCheck", no_warn => 1, error_app => sub {[500, [], ['Internal Server Error']]};
    sub { ['200', ['Content-Type' => 'text/html'], ['hello world']] };
};

sub ok_referer {
    is $_[0]->code    => 200;
    is $_[0]->content => 'hello world';
}
sub ng_referer {
    is $_[0]->code    => 403;
    is $_[0]->content => 'Forbidden';
}
sub ng_referer_special {
    is $_[0]->code    => 500;
    is $_[0]->content => 'Internal Server Error';
}



test_psgi app => $default_handler, client => sub {
    my $cb = shift;

    {
        # GET is not checked
        my $req = GET "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ok_referer $cb->($req);
    }
    {
        my $req = POST "https://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'https://www.example.com',
        ;
        ok_referer $cb->($req);
    }
    {
        # default same_scheme is off
        my $req = POST "https://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ok_referer $cb->($req);
    }
    {
        # default same_scheme is off
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'https://www.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ng_referer $cb->($req);
    }
};

test_psgi app => $host_handler, client => sub {
    my $cb = shift;

    {
        # GET is not checked
        my $req = GET "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ok_referer $cb->($req);
    }
    {
        my $req = POST "http://other.example.com/",
            Host    => 'other.example.com',
            Referer => 'http://other.example.com',
        ;
        ng_referer $cb->($req);
    }
};

test_psgi app => $same_scheme_handler, client => sub {
    my $cb = shift;

    {
        # GET is not checked
        my $req = GET "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "https://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'https://www.example.com',
        ;
        ok_referer $cb->($req);
    }
    {
        # default same_scheme is off
        my $req = POST "https://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ng_referer $cb->($req);
    }
    {
        # default same_scheme is off
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'https://www.example.com',
        ;
        ng_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ng_referer $cb->($req);
    }
};

test_psgi app => $error_app_handler, client => sub {
    my $cb = shift;

    {
        # GET is not checked
        my $req = GET "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://www.example.com',
        ;
        ok_referer $cb->($req);
    }

    {
        my $req = POST "http://www.example.com/",
            Host    => 'www.example.com',
            Referer => 'http://other.example.com',
        ;
        ng_referer_special $cb->($req);
    }
};

done_testing;
