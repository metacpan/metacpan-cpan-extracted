use strict;
use warnings;
use Test::Most;
use Template::EmbeddedPerl;

# Bug: Comparison operators < and > in multi-line code blocks cause parse errors
# Error: "Unterminated <> operator"

my $ep = Template::EmbeddedPerl->new();

# Test 1: Less-than operator in multi-line block
{
    my $template = <<'TEMPLATE';
<%
    my $count = 3;
    my $max = 6;
    my $show = $count < $max;
%>
<div>Show: <%= $show ? 'yes' : 'no' %></div>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/Show: yes/, 'less-than operator works in multi-line block';
}

# Test 2: Greater-than operator in multi-line block
{
    my $template = <<'TEMPLATE';
<%
    my $count = 3;
    my $max = 6;
    my $show = $max > $count;
%>
<div>Show: <%= $show ? 'yes' : 'no' %></div>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/Show: yes/, 'greater-than operator works in multi-line block';
}

# Test 3: Less-than-or-equal operator
{
    my $template = <<'TEMPLATE';
<%
    my $a = 5;
    my $b = 5;
    my $result = $a <= $b;
%>
<%= $result ? 'equal or less' : 'greater' %>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/equal or less/, 'less-than-or-equal operator works';
}

# Test 4: Greater-than-or-equal operator
{
    my $template = <<'TEMPLATE';
<%
    my $a = 5;
    my $b = 5;
    my $result = $a >= $b;
%>
<%= $result ? 'equal or greater' : 'less' %>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/equal or greater/, 'greater-than-or-equal operator works';
}

# Test 5: Spaceship operator <=>
{
    my $template = <<'TEMPLATE';
<%
    my @nums = (3, 1, 2);
    my @sorted = sort { $a <=> $b } @nums;
%>
<%= join(',', @sorted) %>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/1,2,3/, 'spaceship operator works in multi-line block';
}

# Test 6: Multiple comparison operators in same block
{
    my $template = <<'TEMPLATE';
<%
    my $x = 5;
    my $low = 1;
    my $high = 10;
    my $in_range = $x > $low && $x < $high;
%>
<%= $in_range ? 'in range' : 'out of range' %>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/in range/, 'multiple comparison operators in same block';
}

# Test 7: Comparison in if statement
{
    my $template = <<'TEMPLATE';
<%
    my $count = 3;
    my $max = 6;
%>
<% if ($count < $max) { %>
<div>Under limit</div>
<% } %>
TEMPLATE

    my $compiled = $ep->from_string($template);
    my $output = $compiled->render({});
    like $output, qr/Under limit/, 'comparison in if statement works';
}

done_testing;
