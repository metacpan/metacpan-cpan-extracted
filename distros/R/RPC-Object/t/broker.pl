use strict;
use warnings;
BEGIN {
    unshift @INC, './t';
}
use RPC::Object::Broker;

my @preload = @ARGV;

my $b = RPC::Object::Broker->new(preload => \@preload);

$b->start();
