#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Parse::Stallion::CSV;

my $csv_stallion = new Parse::Stallion::CSV;
my $result;

$file =<<EOL;
"abc sdf, sdf",add,eff
jff,"slk,lwer,sd
sdfkl,sdf,sdf,sdf",ke
lkwer,fsjk,sdf
EOL

$result = $csv_stallion->parse_and_evaluate($file);

print "header in ".join("..",@{$result->{header}})."\n\n";
foreach my $i (0..$#{$result->{records}}) {
  print "records $i in ".join("..",@{$result->{records}->[$i]})."\n\n";
}


print "\nAll done\n";


