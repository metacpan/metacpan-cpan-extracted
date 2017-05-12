package DieModule;

BEGIN {
   # this test is supposed to exit 255. Cleanup $! because on some OS
   # this value is set, and Perl will exit with it's value instead of
   # 255
   $! = 0;
   die "DIED!!!";
}

1;
