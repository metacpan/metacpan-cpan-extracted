#!/usr/bin/perl5.10
# usage:
# perl examples/code_download.pl display=article
# perl examples/code_download.pl display=code article_id=23 code_id=1

use strict;
use warnings;
use Parse::BBCode;

use CGI;

my $bbcode = do { local $/; <DATA> };

my $cgi = CGI->new;
my $display = $cgi->param('display');

my $p = Parse::BBCode->new({
        tags => {
            code => {
                code => sub {
                    my ($parser, $attr, $content, $attribute_fallback, $tag, $info) = @_;
                    my $article_id = $parser->get_params->{article_id};
                    my $code_id = $tag->get_num;
                    my $code = Parse::BBCode::escape_html($$content);
                    my $title = Parse::BBCode::escape_html($attr);
                    return <<"EOM";
<div class="bbcode_code_header">Code($title)
<a href="code_download.pl?display=code;article_id=23;code_id=$code_id">Download</a>:
<div class="bbcode_code_body">
$code
</div>
</div>
EOM
                },
            },
        },
    });
my $tree = $p->parse($bbcode);

if ($display eq 'article') {
    my $rendered = $p->render_tree($tree, { article_id => 23 });
    print $cgi->header;
    print <<"EOM";
<html><head></head>
<body>
$rendered
</body></html>
EOM
}
elsif ($display eq 'code') {
    my $code_id = $cgi->param('code_id');
    my $found;
    # search for code tag number $code_id
    $tree->walk('bfs', sub {
            my ($tag) = @_;
            if ($tag->get_name eq 'code' and $tag->get_num eq $code_id) {
                $found = $tag;
                return 1;
            }
            return 0;
        });
    my $code = $found->raw_content;
    print $cgi->header(
        -type => 'text/plain',
        '-X-Content-Type-Options' => 'nosniff',
        '-Content-Disposition' => "attachment; filename=code_23_$code_id.txt",
    );
    print $code;

}


__DATA__
Codebox one:
[code=html]<html>
blabla
</html>
[/code]

Codebox two:
[code=perl]use Moose;
use Moose;
has 'x' => (is => 'rw', isa => 'Int');
has 'y' => (is => 'rw', isa => 'Int');
[/code]

