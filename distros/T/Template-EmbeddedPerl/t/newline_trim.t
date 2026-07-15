use Test::Most;
use Template::EmbeddedPerl;

my $template = Template::EmbeddedPerl->new;

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%
  my $x = 1;
%>
<div>content</div>
TEMPLATE

    is(
        $compiled->render,
        "\n<div>content</div>\n",
        'standard close tag preserves following newline',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%
  my $x = 1;
-%>
<div>content</div>
TEMPLATE

    is(
        $compiled->render,
        "<div>content</div>\n",
        'trim close tag removes following newline after code block',
    );
}

{
    my $compiled = $template->from_string(
        '<% my $x = 1; -%>' . "   \n" . "<div>content</div>\n",
    );

    is(
        $compiled->render,
        "<div>content</div>\n",
        'trim close tag removes whitespace through following newline',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%
  my @items = qw(a b c);
-%>
<ul>
<% for my $item (@items) { -%>
  <li><%= $item %></li>
<% } -%>
</ul>
TEMPLATE

    is(
        $compiled->render,
        "<ul>\n  <li>a</li>\n  <li>b</li>\n  <li>c</li>\n</ul>\n",
        'mixed trim tags avoid extra blank lines in loops',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<% my $name = "test"; -%>
<%= $name %>
TEMPLATE

    is(
        $compiled->render,
        "test\n",
        'code trim close tag does not suppress expression output',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
Hello <%= "World" -%>
!
TEMPLATE

    is(
        $compiled->render,
        "Hello World!\n",
        'expression trim close tag removes following newline',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%= " test " -%>
!
TEMPLATE

    is(
        $compiled->render,
        " test !\n",
        'expression trim close tag does not trim expression value',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%= " test " =%>
!
TEMPLATE

    is(
        $compiled->render,
        "test\n!\n",
        'existing expression value trim still preserves following newline',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<% my $x = 1; %>\
<div>content</div>
TEMPLATE

    is(
        $compiled->render,
        "<div>content</div>\n",
        'existing backslash newline suppression still works',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<% my $x = 1; -%><% my $y = 2; %>
<%= $x + $y %>
TEMPLATE

    is(
        $compiled->render,
        "\n3\n",
        'trim close tag does not carry across an adjacent template tag',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<% my $x = 1; -%>   <% my $y = 2; %><%= $x + $y %>
TEMPLATE

    is(
        $compiled->render,
        "3\n",
        'trim close tag removes whitespace-only segment before adjacent tag',
    );
}

{
    my $compiled = $template->from_string(<<'TEMPLATE');
<%
  my $todo = shift;
  my $id = $todo->{id};
  my $title = $todo->{title};
-%>
<li id="todo-<%= $id %>" class="todo-item">
  <span><%= $title %></span>
  <button hx-delete="/todos/<%= $id %>">Delete</button>
</li>
TEMPLATE

    my $output = $compiled->render({ id => 42, title => 'Buy milk' });

    like($output, qr/^<li/, 'htmx partial starts with element');
    is(
        $output,
        qq{<li id="todo-42" class="todo-item">\n  <span>Buy milk</span>\n  <button hx-delete="/todos/42">Delete</button>\n</li>\n},
        'htmx partial renders without leading whitespace',
    );
}

{
    my $error;
    eval {
        $template->from_string(
            "<% my \$value = 1; -%>\n<%= \$missing %>\n",
            source => 'trimmed-lines.epl',
        );
        1;
    } or $error = $@;

    like(
        $error,
        qr/at trimmed-lines\.epl line 2/,
        'trimmed output newline still counts toward source diagnostics',
    );
}

done_testing();
