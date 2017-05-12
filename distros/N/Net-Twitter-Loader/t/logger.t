use strict;
use warnings;
use Test::More;
use lib "t";
use testlib::Util qw(mock_twitter statuses);
use Net::Twitter::Loader;

my @logs = ();
my $loader = Net::Twitter::Loader->new(
    backend => mock_twitter,
    logger => sub {
        push @logs, \@_;
    },
);

my $statuses = $loader->user_timeline({screen_name => "foo", since_id => 50});
is_deeply $statuses, [statuses(reverse 51 .. 100)], "result OK";

cmp_ok scalar(@logs), ">", 0, "at least 1 message is logged";
is scalar(grep { @$_ == 2 } @logs), scalar(@logs), "all logs have 2 elems";
is scalar(grep { $_->[0] =~ /err|warn|crit|alert/ } @logs), 0, "no bad logs";

done_testing;
