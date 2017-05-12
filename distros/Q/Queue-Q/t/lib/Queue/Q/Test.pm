package # hide from PAUSE
    Queue::Q::Test;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_redis_connect_info
    skip_no_redis
);

use Redis;
use File::Spec;
use Test::More;

my $NoConn;
my $Host;
my $Port;
sub get_redis_connect_info {
    return() if $NoConn;
    return($Host, $Port) if $Host;

    my $fh;
    if (-d 't') {
        open $fh, "<", "redis_connect_data"
            or $NoConn = 1, return();
    }
    else {
        open $fh, "<", File::Spec->catfile(File::Spec->updir, "redis_connect_data")
            or $NoConn = 1, return();
    }

    my $host = <$fh>;
    close $fh;
    $host =~ s/^\s+//;
    chomp $host;
    $host =~ s/\s+$//;
    $NoConn = 1, return() if not defined $host;
    my ($h, $p) = split /:/, $host;

    eval { my $conn = Redis->new(server => $host); 1 }
    or $NoConn = 1, return();

    $Host = $h;
    $Port = $p;

    return($Host, $Port);
}

sub skip_no_redis {
    Test::More::plan(skip_all => "No Redis server available for testing. "
                     . "Create 'redis_connect_data' file with host:port to test");
}

1;
