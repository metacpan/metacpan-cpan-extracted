use strict;
use warnings;
use Test::More tests => 3;
use Net::Drizzle;

my $dr = Net::Drizzle->new();
isa_ok $dr, 'Net::Drizzle';
ok $dr;
can_ok $dr, qw/DESTROY escape query_run_all/;

__END__

    {
        no strict;
        use Data::Dumper;
        warn Dumper(\%::Net::Drizzle::);
    }

