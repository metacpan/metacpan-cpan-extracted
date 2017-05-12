use Test::More tests => 9;

use strict;
use warnings;

use Time::HiRes ();
BEGIN {
    use_ok('Sub::Timekeeper', ':all');
};

timekeeper(my $elapsed, sub {});
ok $elapsed < 0.1, "very fast : $elapsed";

timekeeper($elapsed, sub { Time::HiRes::sleep(0.5) });
ok 0.4 <= $elapsed && $elapsed <= 0.6, "bit slow : $elapsed";

my $r = timekeeper(undef, sub { 111 });
is $r, 111, 'wantscalar';
$r = timekeeper(undef, sub { (11, 22, 33) });
is $r, 33, 'wantscalar and array';
my @r = timekeeper(undef, sub { 111 });
is_deeply \@r, [111], 'wantarray and scalar';
@r = timekeeper(undef, sub { (11, 22, 33) });
is_deeply \@r, [11, 22, 33], 'wantarray';

eval {
    timekeeper($elapsed, sub { Time::HiRes::sleep(0.5); die "aaa" });
};
like $@, qr/^aaa/, 'got exception';
ok 0.4 <= $elapsed && $elapsed <= 0.6, "duration on execption : $elapsed";

done_testing;
