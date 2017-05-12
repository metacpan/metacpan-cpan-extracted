package MogileFS::REST::DumbLogger;
use strict;

sub new {
    return bless {}, shift();
}

for my $lvl (qw/debug info warn error fatal/) {
    no strict 'refs';
    *{$lvl} = sub {
        my $logger = shift;
        print STDERR join (" ", uc($lvl), @_), "\n";
    };
}

1;
