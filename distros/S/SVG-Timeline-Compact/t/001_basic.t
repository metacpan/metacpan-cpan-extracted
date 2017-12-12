use Test::More;
use SVG::Timeline::Compact;
use DateTime::Format::Natural;

use strict;
use warnings;
use diagnostics;
sub dt {
	my $time=shift;
	my $start;
	my $p = DateTime::Format::Natural->new;
	if(not defined $time){
		my $hr=int(rand(15));
		my $mm=int(rand(60));
		$start=$p->parse_datetime("$hr:$mm");
	}
	else {
		my $mdur=int(rand(50));
		my $hdur=int(rand(25));
		$start=$time +DateTime::Duration->new(minutes=>$mdur,hours=>$hdur);
	}
		
	return $start;
}

sub randcolor {
	my $a= sprintf("%x",rand(16));
	my $b= sprintf("%x",rand(16));
	my $c= sprintf("%x",rand(16));
	return "#$a$b$c";
}

my $svg=SVG::Timeline::Compact->new(
);
my @events=();
foreach my $int (0..10){
	my $s=dt();
	my $e=dt($s);
	push @events, {start=>$s , end=>$e , name=>"ev $int"  , tooltip=>"$int Event"     , color=>randcolor()  } ;
}
 foreach my $ev (@events){
$svg->add_event(%{$ev});
}
open my $fh,">","test.svg" or die "unable to open test.svg for writing";
print $fh $svg->to_svg;
ok($svg);

done_testing;
