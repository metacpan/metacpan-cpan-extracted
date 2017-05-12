#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Panda::XS;
use Devel::Peek;
use Data::Dumper 'Dumper';
use POSIX ":sys_wait_h";

say "START";

my $v = 10;
$v++;
my $a = \$v;

Panda::XS::Test::ttt($a);
exit();

timethis(-1, sub { Panda::XS::Test::ttt($a) });
timethis(-1, sub { Panda::XS::Test::yyy($a) });

__END__

my @a = (1..10000);

use threads ('yield',
             'stack_size' => 64*4096,
             'exit' => 'threads_only',
             'stringify');
             
{
    package AAA;
    sub new { return bless {}, 'AAA' }
    #sub CLONE { say "CLONE NAH @_"; }
}

my $aa = new AAA;
my $aa2 = new AAA;

sub thr_do {
    #say "HELLO FROM THREAD";
}

#timethis(-1, sub {
#    my $thr = threads->create(\&thr_do);
#    $thr->join();
#});

timethis(-1, sub {
    fork() or exit();
});

say "END";
