#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Test;
use Plack::Builder;
use Benchmark qw/cmpthese timethese/;

my $app = builder {
    sub{ [ 200, [], [ "Hello "] ] };
};

my $log_app = builder {
    enable 'AccessLog', format => "combined", logger => sub {};
    sub{ [ 200, [], [ "Hello "] ] };
};


my $axslog_app = builder {
    enable 'AxsLog', combined => 1, response_time => 1, logger => sub {};
    sub{ [ 200, [], [ "Hello "] ] };
};

my $axslog_format_app = builder {
    enable 'AxsLog', format => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D', logger => sub {};
    sub{ [ 200, [], [ "Hello "] ] };
};


my $axslog_error_only_app = builder {
    enable 'AxsLog', combined => 1, response_time => 1, error_only => 1, logger => sub {};
    sub{ [ 200, [], [ "Hello "] ] };
};


my $env = req_to_psgi(GET "/");
open(STDERR,'>','/dev/null');

cmpthese(timethese(0,{
#    'nolog' => sub {
#        $app->($env);
#    },
    'log'   => sub {
        $log_app->($env);
    },
    'axslog'   => sub {
        $axslog_app->($env);
    },
#    'axslog_format'   => sub {
#        $axslog_format_app->($env);
#    },
#    'error_only_axslog'   => sub {
#        $axslog_error_only_app->($env);
#    }
}));

__END__
Benchmark: running axslog, log for at least 3 CPU seconds...
    axslog:  3 wallclock secs ( 3.11 usr +  0.01 sys =  3.12 CPU) @ 60029.49/s (n=187292)
       log:  3 wallclock secs ( 3.12 usr +  0.01 sys =  3.13 CPU) @ 56956.23/s (n=178273)
          Rate    log axslog
log    56956/s     --    -5%
axslog 60029/s     5%     --

