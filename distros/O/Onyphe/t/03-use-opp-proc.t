use Test;
BEGIN { plan(tests => 27) }

ok(mytest->('OPP::Proc::Uniq'), 1, $@);
ok(mytest->('OPP::Proc::Dedup'), 1, $@);
ok(mytest->('OPP::Proc::Exec'), 1, $@);
ok(mytest->('OPP::Proc::Whois'), 1, $@);
ok(mytest->('OPP::Proc::Fields'), 1, $@);
ok(mytest->('OPP::Proc::Addcount'), 1, $@);
ok(mytest->('OPP::Proc::Count'), 1, $@);
ok(mytest->('OPP::Proc::Noop'), 1, $@);
ok(mytest->('OPP::Proc::Search'), 1, $@);
ok(mytest->('OPP::Proc::Merge'), 1, $@);
ok(mytest->('OPP::Proc::Where'), 1, $@);
ok(mytest->('OPP::Proc::Top'), 1, $@);
ok(mytest->('OPP::Proc::Fieldcount'), 1, $@);
ok(mytest->('OPP::Proc::Filter'), 1, $@);
ok(mytest->('OPP::Proc::Expand'), 1, $@);
ok(mytest->('OPP::Proc::Flatten'), 1, $@);
ok(mytest->('OPP::Proc::Output'), 1, $@);
ok(mytest->('OPP::Proc::Pivots'), 1, $@);
ok(mytest->('OPP::Proc::Discovery'), 1, $@);
ok(mytest->('OPP::Proc::Splitsubnet'), 1, $@);
ok(mytest->('OPP::Proc::Regex'), 1, $@);
ok(mytest->('OPP::Proc::Lookup'), 1, $@);
ok(mytest->('OPP::Proc::Blocklist'), 1, $@);
ok(mytest->('OPP::Proc::Allowlist'), 1, $@);
ok(mytest->('OPP::Proc::Addfield'), 1, $@);
ok(mytest->('OPP::Proc::Exists'), 1, $@);
ok(mytest->('OPP::Proc::Rename'), 1, $@);

sub mytest {
   my ($proc) = @_;
   return sub {
      return 1 unless -f $ENV{HOME}.'/.onyphe.ini';
      eval("use $proc");
      return $@ ? 0 : 1;
   };
}
