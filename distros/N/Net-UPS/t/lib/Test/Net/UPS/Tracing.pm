package Test::Net::UPS::Tracing;
use strict;
use warnings;
use Net::UPS;
use Time::HiRes 'gettimeofday';
use File::Temp 'tempfile';

our @ISA=('Net::UPS');

sub post {
    my ($self,$url,$content) = @_;

    my ($sec,$usec) = gettimeofday;

    my ($fh,$filename) = tempfile("net-ups-$sec-$usec-XXXX");

    print $fh "POST $url\n\n$content\n";

    my $response = $self->SUPER::post($url,$content);

    print $fh $response;

    return $response;
}

1;
