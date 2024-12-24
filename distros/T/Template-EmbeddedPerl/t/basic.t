use Test::Most;
use Template::EmbeddedPerl;

ok my $template = Template::EmbeddedPerl->new(), 'Create Template::EmbeddedPerl object';

# Test 1: Basic rendering from string
{
    my $compiled = $template->from_string('Hello, <%= shift %>!');
    my $output   = $compiled->render('John');
    is($output, 'Hello, John!', 'Basic rendering from string');
}

# Test 2: Rendering with variables
{
    my $template_str = <<'END_TEMPLATE';
Hello, <%= $_[0]->{name} %>!
Your age is <%= $_[0]->{age} %>.
END_TEMPLATE
    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render( { name => 'John', age => 30 } );
    is( $output, "Hello, John!\nYour age is 30.\n", 'Rendering with variables' );
}

# Test 3: Testing trim helper function
{
    my $template_str = <<'END_TEMPLATE';
<% my $text = "   Some text   "; %>\
Trimmed text: '<%= trim($text) %>'
END_TEMPLATE
    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render();
    is( $output, "Trimmed text: 'Some text'\n", 'Testing trim helper function' );
}

# Test 4: Testing auto_escape
{
    ok my $template = Template::EmbeddedPerl->new(auto_escape => 1), 'Create Template::EmbeddedPerl object with auto_escape';
    my $template_str = 'Content: <%= $_[0]->{html_content} %>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( { html_content => '<p>Hello</p>' } );
    is( $output, 'Content: &lt;p&gt;Hello&lt;/p&gt;', 'Testing auto_escape' );

    # Testing raw helper with auto_escape
    $template_str = 'Content: <%= raw $_[0]->{html_content} %>';
    $compiled     = $template->from_string($template_str);
    $output       = $compiled->render( { html_content => '<p>Hello</p>' } );
    is( $output, 'Content: <p>Hello</p>', 'Testing raw helper with auto_escape' );
}

# Test 5: Testing control structures
{
    my $template_str = <<'END_TEMPLATE';
<% my $args = shift; %>\
<% if ($args->{condition}) { %>\
Condition is true.
<% } else { %>\
Condition is false.
<% } %>\

<% foreach my $item (@{$args->{items}}) { %>\
Item: <%= $item %>
<% } %>\
END_TEMPLATE
    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render( { condition => 1, items => [ 1, 2, 3 ] } );
    is( $output, "Condition is true.\n\nItem: 1\nItem: 2\nItem: 3\n", 'Testing control structures' );
}

# Test 6: Testing block capture with helper function
{
    my $template = Template::EmbeddedPerl->new(
        helpers => {
            wrap => sub {
                my ( $self, $code ) = @_;
                return '<<' . $code->() . '>>';
            },
        }
    );
    my $template_str = <<'END_TEMPLATE';
<%= wrap(sub { %>\
Hello, World!\
<% }) %>\
END_TEMPLATE
    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render();
    is( $output, '<<Hello, World!>>', 'Testing block capture with helper function' );
}

# Test 7: Error handling
{
    my $template_str = <<'END_TEMPLATE';
<% if ($condition) { %>
Condition is true.
<% } else %>
Condition is false.
<% } %>
END_TEMPLATE
    my $compiled;
    my $error = 'Global symbol "$condition" requires explicit package name (did you forget to declare "my $condition"?) at unknown line 1

1: <% if ($condition) { %>
2: Condition is true.

syntax error at unknown line 3

2: Condition is true.
3: <% } else %>
4: Condition is false.


';

    eval { $compiled = $template->from_string($template_str); };
    ok( $@, 'Expected syntax error' );
    ## Leave this out for now, error messaging is too variale between versions of perl
    ##is( $@, $error, 'Error message contains expected lines' );
}

# Test 8: Escaping tags
{
    my $template_str = 'The open tag is \<%.';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render();
    is( $output, 'The open tag is <%.', 'Testing escaping of open tag' );
}

# Test 9: Commenting and escaped comments
{
    my $template_str = <<'END_TEMPLATE';
# This is a comment1\
# This is a comment2\
Test1
# This is a comment2
# This is a comment2
# This is a comment2
Test2
# This is a comment3
END_TEMPLATE

    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render();
    is( $output, "Test1\n\n\n\nTest2\n\n", 'Testing comments, 1' );
}

# Test 10: Commenting and escaped comments, part 2

{
    my $template_str = <<'END_TEMPLATE';
# This is a comment1
# This is a comment2
Test1
# This is a comment2
\# This is a comment2
# This is a comment2
Test2
# This is a comment3\
END_TEMPLATE

    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render();
    is( $output, "\n\nTest1\n\n# This is a comment2\n\nTest2\n", 'Testing comments, 2' );
}

# Test 11: Commenting and escaped comments, part 3

{
    my $template_str = <<'END_TEMPLATE';
Test1
# This is a comment
\# Not a comment
END_TEMPLATE

    my $compiled = $template->from_string($template_str);
    my $output   = $compiled->render();
    is( $output, "Test1\n\n# Not a comment\n", 'Testing comments, 3' );
}

# Test 12: Multiline comments with errors

{
    my $template_str = <<'END_TEMPLATE';
# This is a comment
# This is a comment\
# This is a comment
# This is a comment
<% my $aaa = 1; %>\
<% my $bbb = 1; %>\
<% if ($undefined_var) { %>
Condition is true.
<% } %>
END_TEMPLATE

    my $compiled;
    my $error = 'Global symbol "$condition" requires explicit package name (did you forget to declare "my $condition"?) at unknown line 1

1: <% if ($condition) { %>
2: Condition is true.
';

    eval { $compiled = $template->from_string($template_str); };
    ok( $@, 'Expected syntax error' );
    ## Leave this out for now, error messaging is too variale between versions of perl
    ##is( $@, $error, 'Error message contains expected lines' );
}

done_testing();
