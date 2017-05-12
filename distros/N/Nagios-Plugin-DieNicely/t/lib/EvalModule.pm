package EvalModule;

BEGIN {
   eval { die "This should not be caught"  };
}

1;
