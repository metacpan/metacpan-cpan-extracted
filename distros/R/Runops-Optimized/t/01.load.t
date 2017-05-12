use Test::More tests => 7;

BEGIN { use_ok "Runops::Optimized" }

sub basic {
    ok $_ for 1 .. 2;
}

basic();
ok !Runops::Optimized::is_optimized(\&basic),
  "Subroutine not yet optimised";

basic();
ok Runops::Optimized::is_optimized(\&basic),
  "Subroutine has been optimised on second call";
