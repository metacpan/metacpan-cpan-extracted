#!/usr/bin/perl

my $easing=qx{which schedule-easing.pl 2>/dev/null};
$easing ||=qx{/bin/ls -1 script/schedule-easing.pl 2>/dev/null};
$easing ||=qx{/bin/ls -1 ../script/schedule-easing.pl 2>/dev/null};
chomp($easing);
(-e $easing) || die 'Cannot find schedule-easing.pl';

open(my $fh,'<','sample1.log');
while(<$fh>) { chomp;
	if(/^\[(\d+)\]/) {
		my $cmd="echo \"$_\"|PERL5LIB=../lib $easing --schedule=sample1.dumper --time=$1";
		my $res=qx/$cmd/; chomp($res);
		if($res){print "$res\n"}
	}
}
close($fh);
