use strict;
use warnings;

use Test::Most;
use Template::EmbeddedPerl;

sub compile_failure {
    my ($engine, $template, $source) = @_;
    my $error;
    eval { $engine->from_string($template, source => $source); 1 }
        or $error = $@;
    return $error;
}

sub runtime_failure {
    my ($engine, $template, $source) = @_;
    my $compiled = $engine->from_string($template, source => $source);
    my $error;
    eval { $compiled->render; 1 } or $error = $@;
    return $error;
}

sub warning_message {
    my ($engine, $template, $source) = @_;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $engine->from_string($template, source => $source)->render;
    }
    return join '', @warnings;
}

sub reports_location {
    my ($message, $source, $line, $description) = @_;
    like(
        $message,
        qr/\bat \Q$source\E line $line(?:\.|\n)/,
        $description,
    );
}

reports_location(
    compile_failure(
        Template::EmbeddedPerl->new,
        "head\n<%= \$missing %>\n",
        'pages/compile.epl',
    ),
    'pages/compile.epl',
    2,
    'a compile error reports its template source and line',
);

reports_location(
    warning_message(
        Template::EmbeddedPerl->new,
        "head\n<% warn 'warning' %>\n",
        'pages/warning with spaces.epl',
    ),
    'pages/warning with spaces.epl',
    2,
    'a native warning reports its template source and line',
);

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new(
            preamble => "my \$first = 1;\nmy \$second = 2;",
        ),
        "head\n<% die 'preamble failure' %>\n",
        'pages/preamble.epl',
    ),
    'pages/preamble.epl',
    2,
    'multiline preamble code does not shift template diagnostics',
);

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new(
            prepend => "my \$first = 1;\nmy \$second = 2;",
        ),
        "head\n<% die 'prepend failure' %>\n",
        'pages/prepend.epl',
    ),
    'pages/prepend.epl',
    2,
    'multiline prepend code does not shift template diagnostics',
);

my $cached = Template::EmbeddedPerl->new(use_cache => 1);
my $cached_template = "<% warn 'cached warning' %>\n";
for my $source ('pages/cache-first.epl', 'pages/cache-second.epl') {
    reports_location(
        warning_message($cached, $cached_template, $source),
        $source,
        1,
        "a cached coderef reports $source",
    );
}

my $cached_first = $cached->from_string(
    $cached_template,
    source => 'pages/cache-first.epl',
);
my $cached_first_again = $cached->from_string(
    $cached_template,
    source => 'pages/cache-first.epl',
);
my $cached_second = $cached->from_string(
    $cached_template,
    source => 'pages/cache-second.epl',
);
is(
    $cached_first->{code},
    $cached_first_again->{code},
    'identical content and source reuse the cached coderef',
);
isnt(
    $cached_first->{code},
    $cached_second->{code},
    'identical content under different sources uses distinct coderefs',
);

my $unsafe_source = "pages/\tbad\"\nname.epl";
reports_location(
    warning_message(
        Template::EmbeddedPerl->new,
        "<% warn 'safe source' %>\n",
        $unsafe_source,
    ),
    "pages/?bad' name.epl",
    1,
    'unsafe line-directive characters are normalized deterministically',
);

my $unsafe_args_error = compile_failure(
    Template::EmbeddedPerl->new,
    "% args \@items\n",
    $unsafe_source,
);
is(
    $unsafe_args_error,
    "args directive accepts only scalar arguments at pages/?bad' name.epl line 1\n",
    'an args rewrite error reports its sanitized source and line',
);
unlike(
    $unsafe_args_error,
    qr/\Q$unsafe_source\E/,
    'an args rewrite error does not leak the raw unsafe source',
);

is(
    warning_message(
        Template::EmbeddedPerl->new,
        '<% warn "manual\\n" %>',
        'pages/manual-warning.epl',
    ),
    "manual\n",
    'a warning ending in a newline retains native no-location behavior',
);

my %diagnostic_runner = (
    compile => \&compile_failure,
    runtime => \&runtime_failure,
    warning => \&warning_message,
);

for my $case (
    {
        name => 'one continued comment',
        kind => 'runtime',
        template => "# one\\\n<% die 'one comment' %>\n",
        line => 2,
    },
    {
        name => 'two continued comments before a compile error',
        kind => 'compile',
        template => "# one\\\n# two\\\n<%= \$missing %>\n",
        line => 3,
    },
    {
        name => 'three continued comments before a runtime error',
        kind => 'runtime',
        template => "# one\\\n# two\\\n# three\\\n<% die 'three comments' %>\n",
        line => 4,
    },
    {
        name => 'continued comments before a warning',
        kind => 'warning',
        template => "# one\\\n# two\\\n<% warn 'comment warning' %>\n",
        line => 3,
    },
    {
        name => 'continued comments in the middle',
        kind => 'runtime',
        template => "head\n# one\\\n# two\\\ntail\n<% die 'middle comments' %>\n",
        line => 5,
    },
) {
    my $source = "comments-$case->{kind}.epl";
    reports_location(
        $diagnostic_runner{$case->{kind}}->(
            Template::EmbeddedPerl->new,
            $case->{template},
            $source,
        ),
        $source,
        $case->{line},
        $case->{name},
    );
}

for my $case (
    {
        name => 'custom comment marker',
        engine => Template::EmbeddedPerl->new(comment_mark => '*'),
        template => "* one\\\n* two\\\n<% die 'custom comments' %>\n",
        source => 'custom-comments.epl',
        line => 3,
    },
    {
        name => 'CRLF continued comments',
        engine => Template::EmbeddedPerl->new,
        template => "# one\\\r\n# two\\\r\n<% die 'crlf comments' %>\r\n",
        source => 'crlf-comments.epl',
        line => 3,
    },
) {
    reports_location(
        runtime_failure($case->{engine}, $case->{template}, $case->{source}),
        $case->{source},
        $case->{line},
        $case->{name},
    );
}

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new,
        "# ordinary\n  # indented\nvisible\n<% die 'ordinary comments' %>\n",
        'ordinary-comments.epl',
    ),
    'ordinary-comments.epl',
    4,
    'ordinary comments retain their existing correct mapping',
);

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new,
        "\\# visible comment marker\ntext\n<% die 'escaped comment' %>\n",
        'escaped-comment.epl',
    ),
    'escaped-comment.epl',
    3,
    'an escaped comment marker retains its existing correct mapping',
);

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new,
        "first\\\nsecond\\\n<% die 'escaped output lines' %>\n",
        'escaped-output-lines.epl',
    ),
    'escaped-output-lines.epl',
    3,
    'ordinary escaped output newlines retain their existing correct mapping',
);

is(
    Template::EmbeddedPerl->from_string(
        "# one\\\n# two\\\nbody\n",
        source => 'comment-output.epl',
    )->render,
    "body\n",
    'continued comment repair does not restore removed output newlines',
);
is(
    Template::EmbeddedPerl->from_string(
        "first\\\nsecond\\\n",
        source => 'escaped-output.epl',
    )->render,
    "first\\\nsecond",
    'ordinary plain-text backslash-newline output remains unchanged',
);

for my $case (
    {
        name => 'consecutive smart code lines',
        kind => 'runtime',
        template => "% my \$first = 1\n% my \$second = 2\n% die 'smart runtime'\n",
        line => 3,
    },
    {
        name => 'smart expression compile error',
        kind => 'compile',
        template => "% my \$first = 1\n%= \$missing\n",
        line => 2,
    },
    {
        name => 'consecutive smart warning',
        kind => 'warning',
        template => "% my \$first = 1\n% my \$second = 2\n% warn 'smart warning'\n",
        line => 3,
    },
    {
        name => 'smart line after an ordinary comment',
        kind => 'runtime',
        template => "% my \$first = 1\n# hidden\n% die 'smart comment'\n",
        line => 3,
    },
    {
        name => 'smart line after continued comments',
        kind => 'runtime',
        template => "% my \$first = 1\n# one\\\n# two\\\n% die 'smart continued comments'\n",
        line => 4,
    },
) {
    my $source = "smart-$case->{kind}.epl";
    reports_location(
        $diagnostic_runner{$case->{kind}}->(
            Template::EmbeddedPerl->new(smart_lines => 1),
            $case->{template},
            $source,
        ),
        $source,
        $case->{line},
        $case->{name},
    );
}

my $custom_smart = Template::EmbeddedPerl->new(
    open_tag => '[[',
    close_tag => ']]',
    expr_marker => '?',
    line_start => '++',
    smart_lines => 1,
);
reports_location(
    warning_message(
        $custom_smart,
        "++ my \$first = 1\n++ my \$second = 2\n++ warn 'custom smart warning'\n",
        'custom-smart.epl',
    ),
    'custom-smart.epl',
    3,
    'custom smart markers preserve physical lines',
);

reports_location(
    runtime_failure(
        Template::EmbeddedPerl->new(smart_lines => 1),
        "% my \$first = 1\r\n% my \$second = 2\r\n% die 'smart crlf'\r\n",
        'smart-crlf.epl',
    ),
    'smart-crlf.epl',
    3,
    'smart CRLF input reports its normalized physical line',
);

for my $guard (
    {
        name => 'multiline Perl block',
        engine => Template::EmbeddedPerl->new,
        template => "head\n<%\nmy \$value = 1;\ndie 'multiline';\n%>\n",
        source => 'multiline.epl',
        line => 4,
    },
    {
        name => 'trim-close tag',
        engine => Template::EmbeddedPerl->new,
        template => "<% my \$value = 1; -%>\n<% die 'trimmed' %>\n",
        source => 'trimmed.epl',
        line => 2,
    },
    {
        name => 'interpolation',
        engine => Template::EmbeddedPerl->new(interpolation => 1),
        template => "<% my \$value = 'ok' %>\n\$value\n<% die 'interpolation' %>\n",
        source => 'interpolation.epl',
        line => 3,
    },
    {
        name => 'named args rewrite',
        engine => Template::EmbeddedPerl->new(smart_lines => 1),
        template => "# heading\n% args \$name = 'Ada'\n<% die 'args' %>\n",
        source => 'args-lines.epl',
        line => 3,
    },
) {
    reports_location(
        runtime_failure($guard->{engine}, $guard->{template}, $guard->{source}),
        $guard->{source},
        $guard->{line},
        "$guard->{name} retains its existing correct mapping",
    );
}

my $smart_output = Template::EmbeddedPerl->new(smart_lines => 1);
is(
    $smart_output->from_string(
        "% my \$show = 1\n% if (\$show) {\n  <p>Shown</p>\n% }\n",
        source => 'smart-output.epl',
    )->render,
    "  <p>Shown</p>\n",
    'smart-line source sentinels do not restore directive output newlines',
);
is(
    $smart_output->from_string("%= uc 'ok'\n", source => 'smart-expression.epl')->render,
    'OK',
    'smart expression output still consumes its trailing newline',
);

my $non_latin_source = "pages/\N{U+65E5}\N{U+672C}\N{U+8A9E}.epl";
my $non_latin_cached = Template::EmbeddedPerl->new(use_cache => 1);
my $non_latin_first = $non_latin_cached->from_string(
    "rendered\n",
    source => $non_latin_source,
);
my $non_latin_again = $non_latin_cached->from_string(
    "rendered\n",
    source => $non_latin_source,
);
is($non_latin_first->render, "rendered\n", 'a cached non-Latin source compiles and renders');
is(
    $non_latin_first->{code},
    $non_latin_again->{code},
    'a cached non-Latin source reuses its compiled coderef',
);

my $deceptive_location_error = runtime_failure(
    Template::EmbeddedPerl->new,
    '<% die "failed at pages/a.epl line 99" %>',
    'pages/a.epl',
);
like(
    $deceptive_location_error,
    qr/failed at pages\/a\.epl line 99 at pages\/a\.epl line 1/,
    'a message location-like substring is retained before the real physical location',
);
like(
    $deceptive_location_error,
    qr/1: <\% die "failed at pages\/a\.epl line 99" \%>/,
    'the real physical location receives normal template context decoration',
);

my $line_in_source_error = runtime_failure(
    Template::EmbeddedPerl->new,
    q{<% die 'filename location' %>},
    'pages/name line 17.epl',
);
reports_location(
    $line_in_source_error,
    'pages/name line 17.epl',
    1,
    'a source filename containing line digits reports its exact physical location',
);
like(
    $line_in_source_error,
    qr/1: <\% die 'filename location' \%>/,
    'a source filename containing line digits receives normal template context decoration',
);

my $helper_location_error = runtime_failure(
    Template::EmbeddedPerl->new(
        helpers => {
            native_location_failure => sub { die 'native helper failure' },
        },
    ),
    '<% native_location_failure %>',
    'pages/helper-location.epl',
);
like(
    $helper_location_error,
    qr/\Anative helper failure at \Q@{[ __FILE__ ]}\E line \d+\.\n/,
    'a helper native location remains verbatim',
);
unlike(
    $helper_location_error,
    qr/at pages\/helper-location\.epl line/,
    'a helper native location is not rewritten to the template source',
);

my $eof_location_error = Template::EmbeddedPerl::Utils::generate_error_message(
    "syntax error at pages/eof.epl line 1, at EOF\n",
    ['broken'],
    'pages/eof.epl',
);
reports_location(
    $eof_location_error,
    'pages/eof.epl',
    1,
    'a native compile location ending in at EOF is decorated',
);
like(
    $eof_location_error,
    qr/1: broken/,
    'an at EOF diagnostic receives normal template context decoration',
);

my $multiple_diagnostics = Template::EmbeddedPerl::Utils::generate_error_message(
    "Global symbol \"\$missing\" requires explicit package name at pages/multiple.epl line 1.\n"
        . "Execution of pages/multiple.epl aborted due to compilation errors.\n",
    ['<%= $missing %>'],
    'pages/multiple.epl',
);
reports_location(
    $multiple_diagnostics,
    'pages/multiple.epl',
    1,
    'a compile diagnostic location is decorated when followed by compiler detail',
);
like(
    $multiple_diagnostics,
    qr/Execution of pages\/multiple\.epl aborted due to compilation errors\./,
    'a non-location compiler detail line is preserved verbatim',
);

my $non_native_location = "message at pages/eof.epl line 1\n";
is(
    Template::EmbeddedPerl::Utils::generate_error_message(
        $non_native_location,
        ['broken'],
        'pages/eof.epl',
    ),
    $non_native_location,
    'a location-like message without a native suffix remains verbatim',
);

done_testing;
