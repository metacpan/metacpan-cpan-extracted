use strict;
use warnings;
use Test::More;
use FindBin;
use Pod::HTMLEmbed;

my $finder = Pod::HTMLEmbed->new(
    search_dir => ["$FindBin::Bin/pod"],
);

my $pod = $finder->find("MyTestDoc3");
isa_ok $pod, 'Pod::HTMLEmbed::Entry';

(my $ul1 = $pod->section('UL1')) =~ s/(^\s*|\s*$)//gs;
is $ul1, '<ul><li>foo</li><li>bar</li></ul>', 'clean ul1 ok';

(my $ul2 = $pod->section('UL2')) =~ s/(^\s*|\s*$)//gs;
is $ul2, '<ul><li>foo</li><li>bar</li></ul>', 'clean ul2 ok';

(my $ul3 = $pod->section('UL3')) =~ s/(^\s*|\s*$)//gs;
is $ul3, '<ul><li><p>foo</p><p>bar</p></li><li><p>bar</p><p>buzz</p></li></ul>', 'clean ul3 ok';

(my $ul4 = $pod->section('UL4')) =~ s/(^\s*|\s*$)//gs;
is $ul4, '<ul><li>foo</li><li><p>bar</p><pre><code>buzz
</code></pre></li></ul>', 'clean ul4 ok';

(my $ol1 = $pod->section('OL1')) =~ s/(^\s*|\s*$)//gs;
is $ol1, '<ol><li>foo</li><li>bar</li></ol>', 'clean ol1 ok';

(my $ol2 = $pod->section('OL2')) =~ s/(^\s*|\s*$)//gs;
is $ol2, '<ol><li>foo</li><li><p>bar</p><p>buzz</p></li></ol>', 'clean ol2 ok';

done_testing;
