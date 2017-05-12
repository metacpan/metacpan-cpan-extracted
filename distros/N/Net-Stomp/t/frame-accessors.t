#!perl
use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my $f = Net::Stomp::Frame->new();

for my $h (qw(destination exchange content-type content-length message-id reply-to)) {
    subtest $h => sub {
        my $a = $h;$a=~s{-}{_}g;
        ok(!defined $f->headers->{$h},'header undef');
        ok(!defined $f->$a,'accessor returns undef');
        $f->$a('something');
        is($f->headers->{$h},'something','header set');
        is($f->$a,'something','accessor returns value');
    }
}

done_testing;
