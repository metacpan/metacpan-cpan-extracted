#!/usr/local/bin/perl
use lib '../lib';
use Pod::Usage::CGI;
pod2usage(message => 'a message', css => "http://localhost/some.css");

=head1 NAME

test_pod_usage.cgi - minimal usage of POD::Usage::CGI

=head1 DESCRIPTION

This is a test script

=cut
