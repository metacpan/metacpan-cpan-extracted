#!/usr/bin/perl 
open(IN,"<./Automate.pm") or die "Please run the script in the directory containg Automate.pm\n";
my $code='';
my $getcode=0;
while(<IN>){
	/sub\ setup/ && ($getcode=1);
	/END\ of \localinstall/ && ($getcode=0);
	$getcode && ($code.=$_);
}
close IN;
eval($code);
&setup();


