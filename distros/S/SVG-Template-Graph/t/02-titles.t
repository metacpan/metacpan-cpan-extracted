# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Graph-SVG.t'

#########################
use Test::More tests => 9;
use SVG::Template::Graph;
#########################

my $data = [];
my $tt;
my $svg;
my $out;
my $file = 't/template1.svg';
my $outfile = "/tmp/".rand(1000000).".svg";
ok(-r $file,'test template file exists'); 
ok($tt = SVG::Template::Graph->new($file),'load SVG::Template::Graph object');
	
ok($tt->setGraphTitle(['Hello svg graphing world','I am a subtitle']),'set graph title');


ok($tt->setXAxisTitle(1,['I am X-axis One','Subtitle - % of total length']),'set graph title');
ok($tt->setXAxisTitle(2,'I am X-axis Two'),'set graph title');

ok($tt->setYAxisTitle(1,'I am Y-axis Two'),'set second graph title');
ok($tt->setYAxisTitle(2,['I am Y-axis One','Subtitle - % of total length']),'set graph title');

ok($out = $tt->burn(),'serialise');
ok($out =~ /Hello\ssvg\sgraphing\sworld/gs,'check that graph title showed up in output');
open OUT,"> $outfile";
print OUT $out;
close OUT;
unlink $outfile;
