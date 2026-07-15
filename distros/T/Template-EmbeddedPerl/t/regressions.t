use Test::Most;
use File::Spec;
use Template::EmbeddedPerl;

{
    my $template = Template::EmbeddedPerl->new(use_cache => 1);
    my $template_str = 'Hello, <%= shift %>!';

    my $first = $template->from_string($template_str);
    isa_ok($first, 'Template::EmbeddedPerl::Compiled');
    is($first->render('Jane'), 'Hello, Jane!', 'first cached template render works');

    my $second = $template->from_string($template_str);
    isa_ok($second, 'Template::EmbeddedPerl::Compiled');
    is($second->render('John'), 'Hello, John!', 'cache hit returns a compiled template object');
}

{
    my $first = Template::EmbeddedPerl->new(
        helpers => {
            regression_helper => sub { 'first' },
        },
    );
    my $second = Template::EmbeddedPerl->new(
        helpers => {
            regression_helper => sub { 'second' },
        },
    );

    my $first_compiled = $first->from_string('<%= regression_helper %>');
    my $second_compiled = $second->from_string('<%= regression_helper %>');

    is($first_compiled->render, 'first', 'first template uses its helper');
    is($second_compiled->render, 'second', 'second template uses its helper');
    is($first_compiled->render, 'first', 'first compiled template keeps its helper after second render');
}

{
    my ($inner, $outer);
    my $first = Template::EmbeddedPerl->new(
        helpers => {
            nested_helper => sub { $inner->render },
            context_name => sub { 'outer' },
        },
    );
    my $second = Template::EmbeddedPerl->new(
        helpers => {
            context_name => sub { 'inner' },
        },
    );

    $inner = $second->from_string('<%= context_name %>');
    $outer = $first->from_string('<%= context_name %>-<%= nested_helper %>-<%= context_name %>');

    is($outer->render, 'outer-inner-outer', 'nested renders restore the outer helper context');
}

{
    my $template = Template::EmbeddedPerl->new(
        helpers => {
            failing_helper => sub { die "helper failed\n" },
            working_helper => sub { 'recovered' },
        },
    );

    my $error;
    eval { $template->from_string('<%= failing_helper %>')->render; 1 } or $error = $@;
    like($error, qr/helper failed/, 'newline-terminated helper exception is preserved');
    is(
        $template->from_string('<%= working_helper %>')->render,
        'recovered',
        'helper context is cleaned up after a render failure',
    );
}

{
    my ($inner, $outer);
    my $inner_error;
    my $first = Template::EmbeddedPerl->new(
        helpers => {
            nested_failure => sub {
                eval { $inner->render; 1 } or $inner_error = $@;
                return Template::EmbeddedPerl->_current_render_context('nested_failure')
                    ->engine->get_helpers('context_name')->();
            },
            context_name => sub { 'outer-after-failure' },
        },
    );
    my $second = Template::EmbeddedPerl->new(
        helpers => {
            context_name => sub { die "inner context failed\n" },
        },
    );

    $inner = $second->from_string('<%= context_name %>', source => 'inner-failure.epl');
    $outer = $first->from_string('<%= nested_failure %>', source => 'outer-recovery.epl');

    is(
        $outer->render,
        'outer-after-failure',
        'a failed nested top-level render restores the outer ACTIVE_RENDERER',
    );
    like($inner_error, qr/inner context failed/, 'the nested render still reports its failure');
}

{
    my $compiled = Template::EmbeddedPerl->from_string(
        '<% die "runtime failed" %>',
        source => 'views/runtime-error.epl',
    );
    my $error;
    eval { $compiled->render; 1 } or $error = $@;
    like($error, qr/runtime failed at views\/runtime-error\.epl line 1/, 'runtime error includes source');
}

{
    my $template = Template::EmbeddedPerl->new(
        open_tag => '[[',
        close_tag => ']]',
        expr_marker => '+',
        comment_mark => '*',
    );

    is(
        $template->from_string("* hidden\n[[+ uc 'custom' ]]\n")->render,
        "\nCUSTOM\n",
        'regex metacharacters are supported in configurable tags and comments',
    );
    is(
        $template->from_string(q{The escaped tag is \[[})->render,
        'The escaped tag is [[',
        'custom open tags can be escaped',
    );
}

{
    my $template = Template::EmbeddedPerl->new(
        open_tag => '[[',
        close_tag => ']]',
        expr_marker => '?',
        line_start => '++',
    );

    is(
        $template->from_string("++ my \$value = 'line'\n++? uc \$value\n")->render,
        "\nLINE\n",
        'regex metacharacters are supported in line syntax',
    );
}

{
    my $error;
    eval {
        Template::EmbeddedPerl->new(helpers => { 'invalid-name' => sub { } });
        1;
    } or $error = $@;
    like($error, qr/Invalid template helper name/, 'helper names are validated before string eval');

    undef $error;
    eval {
        Template::EmbeddedPerl->new(sandbox_ns => 'Invalid::123Namespace');
        1;
    } or $error = $@;
    like($error, qr/Invalid sandbox namespace/, 'compilation namespaces are validated before string eval');
}

{
    is(
        Template::EmbeddedPerl->from_string('<% if (1) { =%>yes<% } %>')->render,
        'yes',
        'expression trim close marker does not alter code blocks',
    );
}

{
    package Local::TemplateData;
    $INC{'Local/TemplateData.pm'} = __FILE__;
}

{
    my $source = 'Hello, <%= shift %>!';
    {
        no warnings 'once';
        open Local::TemplateData::DATA, '<', \$source or die "Failed to open scalar DATA handle: $!";
    }

    my $template = Template::EmbeddedPerl->new;
    is($template->from_data('Local::TemplateData')->render('first'), 'Hello, first!', 'first DATA render');
    is($template->from_data('Local::TemplateData')->render('second'), 'Hello, second!', 'DATA handle is restored');
}

{
    package Local::TemplateWithoutData;
    $INC{'Local/TemplateWithoutData.pm'} = __FILE__;
}

{
    my $error;
    eval { Template::EmbeddedPerl->from_data('Local::TemplateWithoutData'); 1 } or $error = $@;
    like($error, qr/No __DATA__ section found/, 'missing DATA section throws an exception');
}

{
    my $dir = File::Spec->catdir(qw(t templates));
    my $template = Template::EmbeddedPerl->new(directories => [$dir]);

    my $object_error;
    eval { $template->from_file('missing'); 1 } or $object_error = $@;
    like(
        $object_error,
        qr/\QTemplate 'missing' not found; searched: $dir\/missing.epl\E/,
        'object from_file reports missing template with directories',
    );
    unlike($object_error, qr/strict refs/, 'object from_file does not die with strict refs error');

    my $class_error;
    eval {
        Template::EmbeddedPerl->from_file(
            'missing',
            directories => [ [qw(t templates)] ],
        );
        1;
    } or $class_error = $@;
    like(
        $class_error,
        qr/\QTemplate 'missing' not found; searched: $dir\/missing.epl\E/,
        'class from_file reports missing template with directories',
    );
    unlike($class_error, qr/strict refs|ARRAY\(/, 'class from_file reports normalized directories');
}

done_testing();
