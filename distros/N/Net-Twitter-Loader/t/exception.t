use strict;
use warnings;
use Test::More;
use Test::MockObject;
use lib "t";
use testlib::Util qw(mock_timeline);
use Try::Tiny;
use Net::Twitter::Loader;

note('--- if backend throws an exception, it should be thrown to the user code');
my $diemock = Test::MockObject->new;
my $call_count = 0;
my @log = ();
$diemock->mock('user_timeline', sub {
    my ($self, $params) = @_;
    $call_count++;
    if($call_count == 1) {
        return mock_timeline($self, $params);
    }else {
        die "Some network error.";
    }
});
my $diein = Net::Twitter::Loader->new(
    backend => $diemock,
    page_next_delay => 0,
    logger => sub { push @log, \@_ },
);
my $exception;
my $result = try {
    $diein->user_timeline({screen_name => 'hoge', since_id => 10, count => 5});
}catch {
    $exception = shift;
    undef;
};

ok(!defined($result), "exception thrown") or diag("result is $result");
like $exception, qr/Some network error/, "exception ok";
cmp_ok(scalar(grep {$_->[0] =~ /err/} @log), ">=", 1, "at least 1 error reported.");

done_testing;
