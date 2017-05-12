# -*- mode: cperl; -*-

use strict;
use warnings;

use Plack::Builder;
use Plack::Util;

use MemoryEater;

my $app = sub {
    my $env = shift;

    my $eater = MemoryEater->new;
    $eater->eat(int(rand(32))); # alloc memory 0..32MB

    return [200,
            ['Content-Type' => 'text/plain'],
            ["hello\n"],
           ];
};


builder {
    enable    "Runtime";
    ## every request
    enable    "MemoryUsage",
    ## with 1/3 probability
    # enable_if { int(rand(3)) == 0 } "MemoryUsage",
    ## only exists X-Memory-Usage request header
    # enable_if { exists $_[0]->{HTTP_X_MEMORY_USAGE} } "MemoryUsage",
        callback => sub {
            my ($env, $res, $before, $after, $diff) = @_;
            my $worst_count = 5;
            for my $pkg (sort { $diff->{$b} <=> $diff->{$a} } keys %$diff) {
                warn sprintf("%-32s %8d = %8d - %8d [KB]\n",
                             $pkg,
                             $diff->{$pkg}/1024,
                             $after->{$pkg}/1024,
                             $before->{$pkg}/1024,
                            );
                last if --$worst_count <= 0;
            }
        };
    $app;
};

__END__

plackup -I../lib -I. -p 9999 -s Starlet --max-workers=1 t.psgi
