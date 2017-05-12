#!/usr/bin/perl

use strict;
use warnings;

package Nginx::ParseLog;

our $VERSION = '1.03';

use Regexp::IPv6 qw($IPv6_re);


=head1 NAME

Nginx::ParseLog - module for parsing Nginx access log files (nginx.net).

=head1 SYNOPSIS

 use Nginx::ParseLog;
 use Data::Dumper;

 my $log_string = '92.241.180.118 - - [28/Mar/2009:20:59:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"';

 my $deparsed = Nginx::ParseLog::parse($log_string);
 warn Data::Dumper($deparsed);
  
 {
    'request' => 'GET / HTTP/1.1',
    'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
    'status' => '200',
    'time' => '28/Mar/2009:20:59:02 +0300',
    'ip' => '92.241.180.118',
    'bytes_send' => '1706',
    'remote_user' => '-',
    'referer' => '-'
 }

=cut

# use re 'debug';

sub parse {
    my $log_string = shift;
    chomp $log_string;

    # print "$log_string\n";
    my $IPv4_re = qr/(?:\d+\.){3}\d+/;
  
    #                      ip                       remote_user   time         request    status   bytes_send  referer    user_agent
    if ( $log_string =~ m/^($IPv4_re|$IPv6_re)\s-\s (.*?)\s         \[(.*?)\]\s  "(.*?)"\s  (\d+)\s  (\d+)\s     "(.*?)"\s  "(.*?)"$/x) {
        my $deparsed = { };
        my $c = 0;
        
        my @field_list = qw/
            ip
            remote_user
            time     
            request 
            status  
            bytes_send
            referer  
            user_agent 
        /;

        {
            no strict 'refs'; # some Perl magic

            for (@field_list) {
                $deparsed->{ $_  } = ${ ++$c };
            }
        }

        return $deparsed;
    } else {
        return;
    }
}

1;

