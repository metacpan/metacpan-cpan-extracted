package t::Util;

use 5.012000;
use strict;
use warnings;
use AWS::XRay 0.05;
use Exporter 'import';
use Test::More;
use IO::Scalar;
use JSON::XS;

our @EXPORT_OK = qw/ reset segments /;

my $sock;
my $buf;
no warnings 'redefine';

*AWS::XRay::sock = sub {
    $sock //= AWS::XRay::Buffer->new(
        IO::Scalar->new(\$buf),
        AWS::XRay->auto_flush,
    );
};

sub reset {
    undef $buf;
}

sub segments {
    return unless $buf;
    $buf =~ s/{"format":"json","version":1}//g;
    my @seg = split /\n/, $buf;
    shift @seg; # despose first ""
    return map { decode_json($_) } @seg;
}

1;
