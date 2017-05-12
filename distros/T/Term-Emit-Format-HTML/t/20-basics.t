#!perl -w
use strict;
use warnings;
use Term::Emit::Format::HTML "format_html";
use Test::More tests => 20;

my $text = q{};
my $want;
my $got;

$text = q{};
$want = q{};
$got = format_html($text);
is($got, $want, "empty text");

$text = q{ };
$want = q{};
$got = format_html($text);
is($got, $want, "blank text");

$text =  q{abc};
$want = qq{  <p>abc</p>\n};
$got = format_html($text);
is($got, $want, "simple blob");

$text =  q{abc...};
$want = qq{  <h1>abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head");

$text =  q{abc... [OK]};
$want = qq{  <h1 class="ok">abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head w/status");

$text = qq{\n};
$want = qq{};
$got = format_html($text);
is($got, $want, "blank text w/NL");

$text = qq{abc\n};
$want = qq{  <p>abc</p>\n};
$got = format_html($text);
is($got, $want, "simple blob w/NL");

$text = qq{abc...\n};
$want = qq{  <h1>abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head w/NL");

$text = qq{abc... [OK]\n};
$want = qq{  <h1 class="ok">abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head w/status w/NL");

$text = qq{abc... 10%... [OK]\n};
$want = qq{  <h1 class="ok">abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head w/status w/prog w/NL");

$text = qq{
abc... [OK]
};
$want = qq{  <h1 class="ok">abc</h1>\n};
$got = format_html($text);
is($got, $want, "simple head w/preblank w/status w/NL");

$text = qq{
abc...
abc...
};
$want = qq{  <h1>abc</h1>\n  <h1>abc</h1>\n};
$got = format_html($text);
is($got, $want, "repeated head, nothing between, is two heads");

$text = qq{
abc...
abc........ [WARN]
};
$want = qq{  <h1>abc</h1>\n  <h1 class="warn">abc</h1>\n};
$got = format_html($text);
is($got, $want, "split head, nothing between, is two heads");

$text = qq{
abc...
abc...
abc........ [WARN]
};
$want = qq{  <h1>abc</h1>\n  <h1>abc</h1>\n  <h1 class="warn">abc</h1>\n};
$got = format_html($text);
is($got, $want, "three split head, nothing between, is three heads");

$text = qq{
abc...
  def
abc........ [WARN]
};
$want = qq{  <h1 class="warn">abc</h1>\n    <p>def</p>\n};
$got = format_html($text);
is($got, $want, "correlate a split head, para inbetween");

$text = qq{
    abc... [OK]
    def...};
$want = qq{  <h1 class="ok">abc</h1>\n  <h1>def</h1>\n};
$got = format_html($text);
is($got, $want, "All indented, two heads, first status");

$text = qq{
    abc...
    def... [OK]};
$want = qq{  <h1>abc</h1>\n  <h1 class="ok">def</h1>\n};
$got = format_html($text);
is($got, $want, "All indented, two heads, second status");

$text = qq{
    abc at L1...
      def at L2...
        ghi at L3...
          jkl at L4...
            mno at L5........ [OK]
            pqr at L5........ [INFO]
            stu at L5........ [NOTE]
        ghi at L3............ [WARN]
    abc at L1................ [DONE]
};
$want = qq{  <h1 class="done">abc at L1</h1>
    <h2>def at L2</h2>
      <h3 class="warn">ghi at L3</h3>
        <h4>jkl at L4</h4>
          <h5 class="ok">mno at L5</h5>
          <h5 class="info">pqr at L5</h5>
          <h5 class="note">stu at L5</h5>
};
$got = format_html($text);
is($got, $want, "Complex, but no p-text");

$text = qq{
    abc at L1...
        This is a complex test.
      def at L2...
          Here we get deeper.
        ghi at L3...
          jkl at L4...
              Now we test three in a row, same level.
            mno at L5........ [OK]
            pqr at L5........ [INFO]
            stu at L5........ [NOTE]
        ghi at L3............ [WARN]
    abc at L1................ [DONE]
};
$want = qq{  <h1 class="done">abc at L1</h1>
      <p>This is a complex test.</p>
    <h2>def at L2</h2>
        <p>Here we get deeper.</p>
      <h3 class="warn">ghi at L3</h3>
        <h4>jkl at L4</h4>
            <p>Now we test three in a row, same level.</p>
          <h5 class="ok">mno at L5</h5>
          <h5 class="info">pqr at L5</h5>
          <h5 class="note">stu at L5</h5>
};
$got = format_html($text);
is($got, $want, "Complex, with p-text");

$text = qq{
    Quobalating all frizzles...
        We operate on only the first and
        second frizzles in this step.
      Merfubbing primary frizzle.......... [OK]
      Xylokineting secondary frizzle...... [WARN]
    Quobalating all frizzles.............. [DONE]
};
$want = qq{  <h1 class="done">Quobalating all frizzles</h1>
      <p>We operate on only the first and second frizzles in this step.</p>
    <h2 class="ok">Merfubbing primary frizzle</h2>
    <h2 class="warn">Xylokineting secondary frizzle</h2>
};
$got = format_html($text);
is($got, $want, "POD synopsis example");
