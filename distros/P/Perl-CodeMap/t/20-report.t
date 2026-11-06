use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib "$FindBin::RealBin/../lib";
use Perl::CodeMap;
my $temp=tempdir(CLEANUP=>1);
my $data={format=>1,name=>'</script><script>alert(1)</script>',module=>'synthetic',parser=>'lite',
 scanned_files=>1,pkgs=>[{path=>'Test::Safe',dir=>'Test',doc=>'safe',imports=>[],files=>[
 {name=>'Safe.pm',path=>'Test/Safe.pm',lines=>2,funcs=>[{n=>'go',l=>1,s=>2,k=>'sub',e=>JSON::PP::true,d=>'example'}]}]}],
 sources=>{'Test/Safe.pm'=>"sub go { print '</script>'; }\n"},source=>'',rev=>'',warnings=>[]};
my $map=Perl::CodeMap->new(root=>"$FindBin::RealBin/../examples/sample",parser=>'lite');
my $out="$temp/code-map.html";my $json="$temp/code-map.json";
ok($map->write_report($data,output=>$out,json=>$json),'report generated');
ok(-s $out && -s $json,'both files written');
open my $fh,'<:raw',$out or die $!;my $html=do{local $/;<$fh>};close $fh;
like($html,qr/&lt;\/script&gt;/,'HTML title escaped');
unlike($html,qr/<script>alert\(1\)<\/script>/,'malicious script tag not injected');
like($html,qr/\\u003c\/script\\u003e/,'embedded JSON escapes script delimiters');
like($html,qr/Prism/i,'bundled highlighter present');
like($html,qr/id="source-modal"/,'source browser present');
like($html,qr/class="graphbox"/,'dependency graph present');
open my $jh,'<:raw',$json or die $!;my $copy=JSON::PP->new->utf8(1)->decode(do{local $/;<$jh>});close $jh;
is($copy->{name},$data->{name},'JSON retains original data without HTML escaping');
like($copy->{sources}{'Test/Safe.pm'},qr/sub go/,'JSON contains source as requested');
done_testing;
