package SubtestSelect;
use Filter::Simple;
FILTER {
	if(/\buse +Test::More\b/) { $_.=q|{ no warnings; sub subtest { my ($x,$y)=("$0::$_[0]",$ENV{SUBTESTRE}//'.*'); if($x=~/$y/){return Test::More::subtest(@_)}else{return Test::More::subtest($_[0],sub{ok(1,'skipped')})}}; }| }
};
