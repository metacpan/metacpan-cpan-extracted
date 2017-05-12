use Test::More;
use FindBin;

use Pod::HTMLEmbed;

my $finder = Pod::HTMLEmbed->new(
    search_dir => ["$FindBin::Bin/pod"],
);

sub run_tests($) {
    my ($pod) = @_;

    is $pod->file, "$FindBin::Bin/pod/MyTestDoc.pod", 'pod file ok';
    is $pod->name, 'MyTestDoc', 'pod name ok';
    is $pod->title, 'test documentation', 'pod title ok';

    is_deeply
        [$pod->sections],
            [qw/NAME SYNOPSIS AUTHOR/, 'SEE ALSO'],
                'sections ok';

    is $pod->section('NAME'), "<p>MyTestDoc - test documentation</p>\n\n",
        'section("NAME") ok';


    my $code_expected = <<__CODE__;
<pre><code>use Pod::HTMLEmbed;
</code></pre>
__CODE__
    like $pod->section('SYNOPSIS'), qr/$code_expected/, 'code block ok';
    like $pod->section('AUTHOR'), qr!<code>typester\@gmail\.com</code>!, 'code inline ok';
}

run_tests $finder->find('MyTestDoc');
run_tests $finder->load("$FindBin::Bin/pod/MyTestDoc.pod");

done_testing;
