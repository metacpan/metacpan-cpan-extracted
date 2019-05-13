package Perl6::Build::Helper;
use strict;
use warnings;

use HTTP::Tinyish;
use Perl6::Build;

sub HTTP {
    my ($class, %argv) = @_;
    for my $try (map "HTTP::Tinyish::$_", qw(Curl Wget HTTPTiny LWP)) {
        HTTP::Tinyish->configure_backend($try) or next;
        $try->supports("https") or next;
        my $agent = sprintf 'perl6-build %s', Perl6::Build->VERSION;
        return $try->new(agent => $agent, verify_SSL => 1, %argv);
    }
    die "No http clients are available";
}

sub LATEST_VERSION {
    my $class = shift;
    my $url = 'https://cpanmetadb.plackperl.org/v1.0/package/Perl6::Build';
    my $res = $class->HTTP(timeout => 10)->get($url);
    if (!$res->{success}) {
        my $msg = $res->{status} == 599 ? "\n$res->{content}" : "";
        chomp $msg;
        die "$res->{status} $res->{reason}, $url$msg\n";
    }
    my ($version) = $res->{content} =~ /^version:\s+(\S+)/ms;
    $version;
}

1;
