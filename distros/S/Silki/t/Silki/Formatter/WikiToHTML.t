use strict;
use warnings;
use utf8;

use Test::Differences;
use Test::More;

use Test::Requires {
    'HTML::Tidy' => '1.54',
};

use lib 't/lib';
use Silki::Test::RealSchema;

use Silki::Formatter::WikiToHTML;
use Silki::Schema::Page;
use Silki::Schema::Role;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $wiki1 = Silki::Schema::Wiki->new( short_name => 'first-wiki' );
$wiki1->set_permissions('private');

my $wiki2 = Silki::Schema::Wiki->new( short_name => 'second-wiki' );
$wiki2->set_permissions('public');

my $sys_user = Silki::Schema::User->SystemUser();

for my $num ( 1 .. 6 ) {
    Silki::Schema::Page->insert_with_content(
        title   => 'Page ' . $num,
        user_id => $sys_user->user_id(),
        wiki_id => ( $num < 4 ? $wiki1->wiki_id() : $wiki2->wiki_id() ),
        content => 'Whatever',
    );
}

my $user = Silki::Schema::User->insert(
    email_address => 'user@example.com',
    display_name  => 'Example User',
    password      => 'xyz',
    time_zone     => 'America/New_York',
    user          => $sys_user,
);

$wiki1->add_user(
    user => $user,
    role => Silki::Schema::Role->Member(),
);

{
    my $page = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki1->wiki_id(),
    );

    my $formatter = Silki::Formatter::WikiToHTML->new(
        user => $user,
        page => $page,
        wiki => $wiki1,
    );

    my $html = $formatter->wiki_to_html(<<'EOF');
Link to ((Page 1))

Link to ((Page 2))

Link to ((Page Which Does Not Exist))

Link to ((Second Wiki/Page 4))

Link to ((Second Wiki/Page 5))

Link to ((Second Wiki/Page Which Does Not Exist))

Link to ((Page 3))

Link to ((Page 2))

Link to ((Bad Wiki/Page Which Does Not Exist))
EOF

    my $expect_html = <<'EOF';
<p>
Link to <a href="/wiki/first-wiki/page/Page_1" class="existing-page" title="Read Page 1">Page 1</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/page/Page_2" class="existing-page" title="Read Page 2">Page 2</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/new_page_form?title=Page+Which+Does+Not+Exist"
           class="new-page" title="This page has not yet been created">Page Which Does Not Exist</a>
</p>

<p>
Link to <a href="/wiki/second-wiki/page/Page_4" class="existing-page" title="Read Page 4">Page 4 (Second Wiki)</a>
</p>

<p>
Link to <a href="/wiki/second-wiki/page/Page_5" class="existing-page" title="Read Page 5">Page 5 (Second Wiki)</a>
</p>

<p>
Link to <a href="/wiki/second-wiki/new_page_form?title=Page+Which+Does+Not+Exist"
           class="new-page" title="This page has not yet been created">Page Which Does Not Exist (Second Wiki)</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/page/Page_3" class="existing-page" title="Read Page 3">Page 3</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/page/Page_2" class="existing-page" title="Read Page 2">Page 2</a>
</p>

<p>
Link to (link to a non-existent wiki in a page link - Bad Wiki/Page Which Does Not Exist)</p>
</p>
EOF

    test_html(
        $html, $expect_html,
        'html output for a variety of page links'
    );
}

{
    my $page1 = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki1->wiki_id(),
    );

    Silki::Schema::File->insert(
        file_id   => 1,
        filename  => 'foo1.jpg',
        mime_type => 'image/jpeg',
        file_size => 3,
        contents  => 'foo',
        user_id   => $sys_user->user_id(),
        page_id   => $page1->page_id(),
    );

    my $page2 = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki2->wiki_id(),
    );

    Silki::Schema::File->insert(
        file_id   => 2,
        filename  => 'foo2.jpg',
        mime_type => 'image/jpeg',
        file_size => 3,
        contents  => 'foo',
        user_id   => $sys_user->user_id(),
        page_id   => $page2->page_id(),
    );

    Silki::Schema::File->insert(
        file_id   => 3,
        filename  => 'foo3.doc',
        mime_type => 'application/msword',
        file_size => 3,
        contents  => 'foo',
        user_id   => $sys_user->user_id(),
        page_id   => $page1->page_id(),
    );

    my $formatter = Silki::Formatter::WikiToHTML->new(
        user => $user,
        page => $page1,
        wiki => $wiki1,
    );

    my $html = $formatter->wiki_to_html(<<'EOF');
Link to {{file:foo1.jpg}}

Link to {{file:Front Page/foo1.jpg}}

Link to {{file:bad-file1.jpg}}

Link to {{file:Second Wiki/Front Page/foo2.jpg}}

Link to {{file:Second Wiki/Front Page/bad-file2.jpg}}

Link to {{file:Bad Wiki/Front Page/bad-file3.jpg}}

Link to {{file:foo1.jpg}}

Link to {{file:foo3.doc}}

{{image:foo1.jpg}}

{{image:bad-file1.jpg}}

{{image:Second Wiki/Front Page/foo2.jpg}}

{{image:Second Wiki/Front Page/bad-file2.jpg}}

{{image:Bad Wiki/Front Page/bad-file3.jpg}}
EOF

    my $expect_html = <<'EOF';
<p>
Link to <a href="/wiki/first-wiki/file/1" title="View this file">foo1.jpg</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/file/1" title="View this file">foo1.jpg</a>
</p>

<p>
Link to (link to a non-existent file - bad-file1.jpg)
</p>

<p>
Link to <a href="/wiki/second-wiki/file/2" title="View this file">foo2.jpg (Second Wiki)</a>
</p>

<p>
Link to (link to a non-existent file - Second Wiki/Front Page/bad-file2.jpg)
</p>

<p>
Link to (link to a non-existent wiki in a file link - Bad Wiki/Front Page/bad-file3.jpg)
</p>

<p>
Link to <a href="/wiki/first-wiki/file/1" title="View this file">foo1.jpg</a>
</p>

<p>
Link to <a href="/wiki/first-wiki/file/3" title="Download this file">foo3.doc</a>
</p>

<p>
<a href="/wiki/first-wiki/file/1" title="View this file"><img src="/wiki/first-wiki/file/1/small" alt="foo1.jpg" /></a>
</p>

<p>
(link to a non-existent file - bad-file1.jpg)
</p>

<p>
<a href="/wiki/second-wiki/file/2" title="View this file"><img src="/wiki/second-wiki/file/2/small" alt="foo2.jpg" /></a>
</p>

<p>
(link to a non-existent file - Second Wiki/Front Page/bad-file2.jpg)
</p>

<p>
(link to a non-existent wiki in a file link - Bad Wiki/Front Page/bad-file3.jpg)
</p>
EOF

    test_html(
        $html, $expect_html,
        'html output for a variety of file and image links'
    );
}

{
    my $page = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki1->wiki_id(),
    );

    my $formatter = Silki::Formatter::WikiToHTML->new(
        user        => $user,
        page        => $page,
        wiki        => $wiki1,
        include_toc => 1,
    );

    my $html = $formatter->wiki_to_html(<<'EOF');
## Header 2A

Some text

### Header 3A

#### Header 4A

##### Header 5

###### Header 6

### Header 3B

#### Header 4B

## Header 2B
EOF

    my $expect_html = <<'EOF';
<div id="table-of-contents">
  <ul>
    <li><a href="#Header_2A_-0">Header 2A</a>
      <ul>
        <li><a href="#Header_3A_-1">Header 3A</a>
          <ul>
            <li><a href="#Header_4A_-2">Header 4A</a></li>
          </ul>
        </li>
        <li><a href="#Header_3B_-3">Header 3B</a>
          <ul>
            <li><a href="#Header_4B_-4">Header 4B</a></li>
          </ul>
        </li>
      </ul>
    </li>
    <li><a href="#Header_2B_-5">Header 2B</a></li>
  </ul>
</div>

<h2><a name="Header_2A_-0"></a>Header 2A</h2>

<p>
Some text
</p>

<h3><a name="Header_3A_-1"></a>Header 3A</h3>

<h4><a name="Header_4A_-2"></a>Header 4A</h4>

<h5>Header 5</h5>

<h6>Header 6</h6>

<h3><a name="Header_3B_-3"></a>Header 3B</h3>

<h4><a name="Header_4B_-4"></a>Header 4B</h4>

<h2><a name="Header_2B_-5"></a>Header 2B</h2>
EOF

    test_html(
        $html, $expect_html,
        'header and TOC generation'
    );
}

{
    my $page = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki1->wiki_id(),
    );

    my $markdown = <<'EOF';
<http://example.com>

[External link](http://example.com)
EOF

    my $formatter = Silki::Formatter::WikiToHTML->new(
        user        => $user,
        page        => $page,
        wiki        => $wiki1,
    );

    my $html = $formatter->wiki_to_html($markdown);

    my $expect_html = <<'EOF';
<p>
<a href="http://example.com">http://example.com</a>
</p>

<p>
<a href="http://example.com">External link</a>
</p>
EOF

    test_html(
        $html, $expect_html,
        'external links in private wiki do not have nofollow'
    );

    $formatter = Silki::Formatter::WikiToHTML->new(
        user        => $user,
        page        => $page,
        wiki        => $wiki2,
    );

    $html = $formatter->wiki_to_html($markdown);

    $expect_html = <<'EOF';
<p>
<a href="http://example.com" rel="nofollow">http://example.com</a>
</p>

<p>
<a href="http://example.com" rel="nofollow">External link</a>
</p>
EOF

    test_html(
        $html, $expect_html,
        'external link in public wiki do have nofollow'
    );
}

{
    my $page = Silki::Schema::Page->new(
        title   => 'Front Page',
        wiki_id => $wiki1->wiki_id(),
    );

    my $markdown = <<'EOF';
<http://example.com>

[External link](http://example.com)
EOF

    my $user2 = Silki::Schema::User->insert(
        email_address => 'user2@example.com',
        display_name  => 'Example User',
        password      => 'xyz',
        time_zone     => 'America/New_York',
        user          => $sys_user,
    );

    my $formatter = Silki::Formatter::WikiToHTML->new(
        user        => $user2,
        page        => $page,
        wiki        => $wiki1,
    );

    my $html = $formatter->wiki_to_html(<<'EOF');
Link to ((Page 1))

Link to {{file:foo1.jpg}}

{{image:foo1.jpg}}
EOF

    my $expect_html = <<'EOF';
<p>
Link to (inaccessible page)
</p>

<p>
Link to (inaccessible file)
</p>

<p>
(inaccessible file)
</p>
EOF

    test_html(
        $html, $expect_html,
        'link formatting for page and file when user does not have read access to them'
    );
}

done_testing();

sub test_html {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $real_expect = <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title>Test</title>
</head>
<body>
$expect
</body>
</html>
EOF

    my $tidy = HTML::Tidy->new(
        {
            doctype           => 'transitional',
            'sort-attributes' => 'alpha',
            output_xhtml      => 1,
        }
    );

    $got    = $tidy->clean($got);
    $expect = $tidy->clean($real_expect);

    s{.+<body>\s*|\s*</body>.+}{}gs for $got, $expect;

    eq_or_diff( $got, $expect, $desc );
}
