#!/usr/bin/env plackup
use lib qw!../blib/lib!;

use strict;
use warnings;

use Plack::Builder;
use Plack::App::CGIBin::Streaming;

(my $root=__FILE__)=~s![^/]*$!cgi-bin!;

$main::app=Plack::App::CGIBin::Streaming->new
    (
     root => $root,
     preload => ['*.cgi'],
     request_params => [
                        parse_headers => 1,
                        on_status_output => sub {
                            my $r=$_[0];

                            $r->print_header('X-Accel-Buffering', 'no')
                                if $r->status==200 and
                                   $r->content_type=~m!^text/html!i;
                        },
                        filter_after => sub {
                            my ($r, $list)=@_;

                            unless ($r->status==200 and
                                    $r->content_type=~m!^text/html!i) {
                                $r->filter_after=sub{};
                                return;
                            }

                            for my $chunk (@$list) {
                                if ($chunk=~/<!-- FlushHead -->/) {
                                    $r->filter_after=sub{};
                                    $r->flush;
                                    return;
                                }
                            }
                        },
                       ],
    );

open ACCESS_LOG, '>>', 'access_log' or die "Cannot open access_log: $!";
select +(select(ACCESS_LOG), $|=1)[0];

{
    open my $fh, '>>', 'error_log' or die "Cannot open error_log: $!";
    select +(select($fh), $|=1)[0];
    close STDERR;
    open STDERR, '>&', $fh;
}

builder {
    enable 'AccessLog::Timed' => (
                                  format => '%h %l %u %t "%r" %>s %b %D',
                                  logger => sub {print ACCESS_LOG $_[0]},
                                 );
    $main::app->to_app;
};
