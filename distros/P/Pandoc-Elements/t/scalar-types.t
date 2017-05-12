use strict;
use Test::More;
use Pandoc::Elements qw(pandoc_json);
use JSON qw(decode_json);

# deliberately erroneous,
# i.e. pandoc should choke on it unless the appropriate
# TO_JSON methods have done their magic on it!
my $bad_json = <<'JSON';
[{"unMeta":{"MetaBool":{"t":"MetaBool","c":true}}},[{"t":"Header","c":["1",["heading",[],[]],[{"t":"Str","c":"Heading"},{"c":[],"t":"Space"}]]},{"t":"Para","c":[{"c":[[{"citationMode":{"t":"NormalCitation","c":[]},"citationPrefix":[{"c":"citation","t":"Str"}],"citationSuffix":[{"c":[],"t":"Space"},{"c":"p.","t":"Str"},{"c":[],"t":"Space"},{"c":13,"t":"Str"}],"citationId":"author2015","citationNoteNum":"0","citationHash":"0"}],[{"t":"Str","c":"[citation"},{"t":"Space","c":[]},{"c":"@author2015","t":"Str"},{"t":"Space","c":[]},{"c":"p.","t":"Str"},{"c":[],"t":"Space"},{"c":"13]","t":"Str"}]],"t":"Cite"},{"c":",","t":"Str"},{"c":[],"t":"Space"}]},{"t":"OrderedList","c":[["2",{"t":"Decimal","c":[]},{"t":"OneParen","c":[]}],[[{"t":"Plain","c":[{"c":"#1=2","t":"Str"},{"t":"Space","c":[]}]}],[{"c":[{"t":"Str","c":"#2=3"}],"t":"Plain"}]]]},{"t":"Table","c":[[{"t":"Str","c":"Table"},{"t":"Space","c":[]}],[{"t":"AlignLeft","c":[]},{"t":"AlignLeft","c":[]},{"t":"AlignLeft","c":[]}],["0","0","0"],[[{"t":"Plain","c":[{"t":"Str","c":"M."}]}],[{"t":"Plain","c":[{"t":"Str","c":"F."}]}],[{"c":[{"t":"Str","c":"N."}],"t":"Plain"}]],[[[{"c":[{"t":"Str","c":"hic"}],"t":"Plain"}],[{"c":[{"c":"haec","t":"Str"}],"t":"Plain"}],[{"c":[{"c":"hoc","t":"Str"}],"t":"Plain"}]]]]}]]
JSON

my $good_json = <<'JSON';
[{"unMeta":{"MetaBool":{"c":true,"t":"MetaBool"}}},[{"t":"Header","c":[1,["heading",[],[]],[{"c":"Heading","t":"Str"},{"t":"Space","c":[]}]]},{"t":"Para","c":[{"t":"Cite","c":[[{"citationHash":0,"citationSuffix":[{"c":[],"t":"Space"},{"c":"p.","t":"Str"},{"c":[],"t":"Space"},{"c":"13","t":"Str"}],"citationId":"author2015","citationPrefix":[{"t":"Str","c":"citation"}],"citationNoteNum":0,"citationMode":{"c":[],"t":"NormalCitation"}}],[{"t":"Str","c":"[citation"},{"c":[],"t":"Space"},{"c":"@author2015","t":"Str"},{"c":[],"t":"Space"},{"t":"Str","c":"p."},{"c":[],"t":"Space"},{"t":"Str","c":"13]"}]]},{"c":",","t":"Str"},{"t":"Space","c":[]}]},{"t":"OrderedList","c":[[2,{"c":[],"t":"Decimal"},{"t":"OneParen","c":[]}],[[{"t":"Plain","c":[{"t":"Str","c":"#1=2"},{"c":[],"t":"Space"}]}],[{"c":[{"t":"Str","c":"#2=3"}],"t":"Plain"}]]]},{"t":"Table","c":[[{"t":"Str","c":"Table"},{"c":[],"t":"Space"}],[{"c":[],"t":"AlignLeft"},{"c":[],"t":"AlignLeft"},{"t":"AlignLeft","c":[]}],[0,0,0],[[{"c":[{"t":"Str","c":"M."}],"t":"Plain"}],[{"c":[{"c":"F.","t":"Str"}],"t":"Plain"}],[{"t":"Plain","c":[{"c":"N.","t":"Str"}]}]],[[[{"t":"Plain","c":[{"c":"hic","t":"Str"}]}],[{"c":[{"t":"Str","c":"haec"}],"t":"Plain"}],[{"c":[{"c":"hoc","t":"Str"}],"t":"Plain"}]]]]}]]
JSON

my $document = eval { pandoc_json( $bad_json ) };
my $error = $@;
is $error, "", 'no error reading "bad" JSON';
isa_ok $document, 'Pandoc::Document';

is_deeply decode_json($good_json), $document->TO_JSON, 'fixed JSON';

# IPC::Run3::run3( [pandoc => -f => 'json', -t => 'markdown'], \$json, \my $stdout, \my $stderr );
# is $stderr, "", 'no errors feeding JSON to pandoc' or note $stderr;
# note $document->to_json;
# note $stdout;

done_testing;
