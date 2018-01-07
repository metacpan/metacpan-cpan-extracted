#!perl

=head1 NAME

time-over-https.psgi

=head1 SYNOPSIS

  plackup time-over-https.psgi

=head1 DESCRIPTION

This is a sample "Time over HTTP" implementation that uses
L<Plack::Middleware::TimeOverHTTP>.

=head1 SEE ALSO

The "Time Over HTTPS specification" at
L<http://phk.freebsd.dk/time/20151129.html>.

=cut

use strict;
use warnings;

use HTTP::Status qw/ :constants /;
use Plack::Builder;

my $app = sub {
    return [ HTTP_NOT_FOUND, [], [] ];
};

builder {
    enable "TimeOverHTTP";
    $app;
};
