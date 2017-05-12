use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;
use PID::File::Guard;

my $pid_file = PID::File->new;

dies_ok { PID::File::Guard->new( sub { } ) } "new dies ok in void context";

lives_ok { my $guard = PID::File::Guard->new( sub { } ) } "lives ok in scalar context";

lives_ok { my @guard = PID::File::Guard->new( sub { } ) } "lives ok in list context";

done_testing();
