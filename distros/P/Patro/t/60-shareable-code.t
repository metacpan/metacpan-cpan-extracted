use Test::More;
use strict;
use warnings;
use Data::Dumper;
if (!eval "use threads; use threads::shared; 1") {
    ok("SKIP: no threads");
    done_testing;
    exit;
}
require Patro::CODE::Shareable;   # load after threads::shared
Patro::CODE::Shareable->import;

sub sub1 { 42 }

ok(\&threads::shared::share == \&Patro::CODE::Shareable::share,
   'Patro::CODE::Shareable hijacks threads::shared::share()');
ok(\&threads::shared::shared_clone == \&Patro::CODE::Shareable::shared_clone,
   '... and threads::shared::shared_clone()');

my $c1 = Patro::CODE::Shareable->new(\&sub1);
my $z = eval { share($c1) };
ok($z && !$@, "can share shareable code");
ok($c1->() == 42, "can invoke shareable code");

my $sub2 = sub { 19 + $_[0] };
$z = eval { share($sub2) };
ok($z && !$@, "share now works on CODE ref") or diag $@;
ok(ref($sub2) eq 'Patro::CODE::Shareable',
   "share(CODE) makes code shareable");

$z = eval { share( sub { "totally anonymous sub" } ) };
ok($z && !$@, "sharing a totally anonymous sub ok");



my %d : shared;
ok(is_shared(\%d), '%d is shared');

eval { $d{foo} = sub { 17 + $_[0] } };
ok(!$d{foo} && $@, "can't add sub to shared hash");

eval { $d{bar} = Patro::CODE::Shareable->new($sub2) };
ok($d{bar} && !$@, "ok to add shareable CODE to shared hash")
    or diag $@;

# does this code fail on perl 5.14?
ok($d{bar} && eval { $d{bar}->(17) } == 36,
   "ok to execute sub in shared hash") or diag $@;

my $dispatch = {
    foo => sub { $_[0]->{def}++; return 42 },
    bar => $sub2,
    baz => sub { $_[0]->{abc} += $_[1] },
    abc => 12,
    def => 34
};
ok($dispatch->{foo}->($dispatch) == 42, 'unshared dispatch code');
ok($dispatch->{baz}->($dispatch,7) == 19, 'unshared dispatch code');
ok($dispatch->{abc} == 19, 'dispatch code affected unshared obj');

my $shpatch = eval { shared_clone($dispatch) };
ok($shpatch && !$@, 'shared clone on dispatch table ok');

use Data::Dumper;
ok($shpatch->{abc} == 19 && $shpatch->{def} == 35,
   'initial shared dispatch table values ok') or diag Dumper($shpatch);

my $thr1 = threads->create( sub { $shpatch->{foo}->($shpatch) } );
my $thr2 = threads->create( sub { $shpatch->{baz}->($shpatch,-5) } );
my $j1 = $thr1->join;
my $j2 = $thr2->join;
ok($j1 == 42, 'thread 1 completed');
ok($j2 == 14, 'thread 2 completed');
ok($shpatch->{def} == 36, 'shared hash updated by shared code');
ok($shpatch->{abc} == 14, 'shared hash updated by shared code');



done_testing();
