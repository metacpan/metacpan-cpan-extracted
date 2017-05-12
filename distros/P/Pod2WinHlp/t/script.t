#!perl 
use Test;                              
plan test => 2;
# my @out = `$^X -Mblib pod2rtf t/testpod.pod`;
my @out = `$^X pod2rtf t/testpod.pod`;
ok($!,'',"Error from script");

open(RTF,"<t/testpod.rtf");
my @rtf=<RTF>;
close(RTF);
my $rtf=join("\n",@rtf);

$out=join("\n",@out);

ok(($out eq $rtf),1,"Error in translation");

