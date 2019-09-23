#!/usr/bin/env perl

use strict;
use warnings;

use Net::Curl::Easy qw(:constants);

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::Curl::Promiser::Select;

my @urls = (
    'http://perl.com',
    'http://metacpan.org',
);

use constant _SIZE_LIMIT => 100;

#----------------------------------------------------------------------

my $promiser = Net::Curl::Promiser::Select->new();

for my $url (@urls) {
    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );
    $handle->setopt( CURLOPT_FOLLOWLOCATION() => 1 );

    my $buf = q<>;

    $handle->setopt( CURLOPT_WRITEFUNCTION() => sub {
        my ($easy, $data) = @_;

        if (($url =~ m<perl>) && length($buf) + length($data) > _SIZE_LIMIT()) {
            $promiser->fail_handle($easy, 'Too big!');
            return Net::Curl::Easy::CURL_WRITEFUNC_PAUSE();
        }
        else {
            $buf .= $data;
            return length $data;
        }
    } );

    $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    );
}

#----------------------------------------------------------------------

use Data::FDSet;

$_ = Data::FDSet->new() for my ($rout, $wout, $eout);

while ($promiser->handles()) {
    if ( my $timeout = $promiser->get_timeout() ) {
        ($$rout, $$wout, $$eout) = $promiser->get_vecs();

        my $got = select $$rout, $$wout, $$eout, $timeout;

        die "select(): $!" if $got < 0;

        if ($$eout =~ tr<\0><>c) {
            for my $fd ( $promiser->get_fds() ) {
                warn "problem (?) on FD $fd!" if $eout->has($fd);
            }
        }
    }

    $promiser->process($$rout, $$wout);
}
