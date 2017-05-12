use Test::Base;
use Template;
use Template::Plugin::ResolveLink;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $tt = Template->new;
    $tt->process(\$block->input, {}, \my $out)
        or do { fail $tt->error; next };
    is $out, $block->expected;
};

__END__
===
--- input
[% USE ResolveLink -%]
[% FILTER resolve_link base = "http://www.example.com/base/" -%]
<a href="foo.html"><img src="/bar.gif"></a>
<a href="mailto:bar">foo</a>
[% END -%]
--- expected
<a href="http://www.example.com/base/foo.html"><img src="http://www.example.com/bar.gif"></a>
<a href="mailto:bar">foo</a>

