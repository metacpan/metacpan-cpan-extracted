sub test {
   my($obj,$test,$runtests) = @_;

   # Make sure we're running in the test directory

   if (-f "t/test.pl") {
      chdir("t");
   }

   # Store the object in a data hash for Template::Toolkit

   my $data = { "obj" => $obj };

   # Expected values

   my $exp = new IO::File;
   $exp->open("$test.exp");
   my @exp = <$exp>;
   chomp(@exp);

   # Input/Output files

   my $in_file = "$test.in";
   my $out_file = "$test.out";

   # Process the template

   my $tmpl = Template->new();
   $tmpl->process($in_file, $data,$out_file);

   $out = new IO::File;
   $out->open($out_file);
   @out = <$out>;
   chomp(@out);

   # Number of tests

   my $numt = $#out;
   $numt    = $#exp  if ($#exp > $numt);
   $numt++;

   print "Test $test...\n";
   print "1..$numt\n";

   # Check each test

   my $done = 0;
   for (my $i = 1; $i <= $numt; $i++) {
      my $exp = (@exp ? shift(@exp) : "");
      my $out = (@out ? shift(@out) : "");
      $done   = 1  if ($exp eq ".END.");

      if ($exp eq $out  ||  $done) {
         print "ok $i\n"  if (! defined $runtests or $runtests==0);
      } else {
         warn "########################\n";
         warn "Expected = >$exp<\n";
         warn "Got      = >$out<\n";
         warn "########################\n";
         print "not ok $i\n";
      }
   }

   unlink($out_file);
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

