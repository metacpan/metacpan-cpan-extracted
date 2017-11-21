my @bleep;

print (var_name(0, \@bleep) eq '@bleep' ? "ok 6\n" : "not ok 6\n");
eval {
  print (var_name(0, \@bleep) eq '@bleep' ? "ok 7\n" : "not ok 7\n");
};
eval q{
  print (var_name(0, \@bleep) eq '@bleep' ? "ok 8\n" : "not ok 8\n");
};

1;
