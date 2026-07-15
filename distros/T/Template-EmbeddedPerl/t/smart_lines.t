use Test::Most;
use Template::EmbeddedPerl;

my $legacy = Template::EmbeddedPerl->new;
my $smart = Template::EmbeddedPerl->new(smart_lines => 1);

my $template = "% my \$show = 1\n% if (\$show) {\n  <p>Shown</p>\n% }\n";
is(
    $legacy->from_string($template)->render,
    "\n\n  <p>Shown</p>\n\n",
    'legacy mode preserves directive newlines',
);
is(
    $smart->from_string($template)->render,
    "  <p>Shown</p>\n",
    'smart mode consumes directive lines',
);
is(
    $smart->from_string("%= uc 'ok'\n")->render,
    'OK',
    'smart expression consumes its newline',
);
is(
    $smart->from_string("%= uc 'ok'")->render,
    'OK',
    'smart expression works without final newline',
);
is(
    $smart->from_string("\\% literal\n")->render,
    "% literal\n",
    'escaped percent remains literal',
);
is(
    $smart->from_string("  100% complete\n")->render,
    "  100% complete\n",
    'non-leading percent remains text',
);
is(
    $smart->from_string("% my \$x = 1\r\n<p><%= \$x %></p>\r\n")->render,
    "<p>1</p>\n",
    'CRLF input normalizes and trims',
);

is(
    $smart->from_string("% my \$value = 'ok'\n\nValue: <%= \$value %>\n")->render,
    "\nValue: ok\n",
    'smart lines preserve blank template lines',
);

{
    my $nested = <<'TEMPLATE';
% for my $outer (1 .. 2) {
%   for my $inner (1 .. 2) {
<%= $outer %>:<%= $inner %>
%   }
% }
TEMPLATE

    is(
        $smart->from_string($nested)->render,
        "1:1\n1:2\n2:1\n2:2\n",
        'smart lines render nested blocks',
    );
}

{
    my $multiline = <<'TEMPLATE';
<%
  my @values = (
    'alpha',
    'beta',
  );
%>
<%= join(':', @values) %>
TEMPLATE

    is(
        $smart->from_string($multiline)->render,
        "\nalpha:beta\n",
        'smart lines preserve multiline Perl blocks',
    );
}

my $custom = Template::EmbeddedPerl->new(
    open_tag => '[[',
    close_tag => ']]',
    expr_marker => '?',
    line_start => '++',
    smart_lines => 1,
);
is(
    $custom->from_string("++ my \$value = 'line'\n++? uc \$value\n")->render,
    'LINE',
    'smart lines support regex metacharacters in custom markers',
);

done_testing;
