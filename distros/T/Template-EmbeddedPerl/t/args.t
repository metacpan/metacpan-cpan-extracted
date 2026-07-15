use Test::Most;
use Template::EmbeddedPerl;
use Template::EmbeddedPerl::Arguments;

my $engine = Template::EmbeddedPerl->new(smart_lines => 1);

my $compiled = $engine->from_string(<<'EPL');
% args $name, $greeting = 'Hello'
<%= $greeting %>, <%= $name %>!
EPL

is(
    $compiled->render(name => 'Jane'),
    "Hello, Jane!\n",
    'expression default is used',
);
is(
    $compiled->render(name => 'Jane', greeting => 'Hi'),
    "Hi, Jane!\n",
    'default is overridden',
);

my $ordered_default = $engine->from_string(<<'EPL');
% args $name, $label = "Hello, $name"
<%= $label %> (<%= scalar @_ %>)
EPL

is(
    $ordered_default->render(name => 'Jane'),
    "Hello, Jane (2)\n",
    'expression defaults see earlier arguments and the original argument list',
);

my $nested_defaults = $engine->from_string(<<'EPL');
% args $items = [1, 2], $labels = { first => 'A', second => 'B' }, $joined = join('-', 'x', 'y')
<%= join(':', @$items, $labels->{first}, $labels->{second}, $joined) %>
EPL

is(
    $nested_defaults->render,
    "1:2:A:B:x-y\n",
    'nested commas in array, hash, and call defaults do not split declarations',
);

my $legacy_engine = Template::EmbeddedPerl->new;
is(
    $legacy_engine->from_string("% args \$name\n<%= \$name %>\n")->render(name => 'Jane'),
    "Jane\n",
    'args directive does not require smart lines',
);

my ($rewritten, $has_args) = Template::EmbeddedPerl::Arguments->rewrite(
    "% args \$name\n<%= \$name %>\n",
);
ok($has_args, 'rewrite reports an args directive');
is(
    $rewritten =~ tr/\n//,
    2,
    'rewrite preserves the template newline count',
);

my ($unchanged, $has_no_args) = Template::EmbeddedPerl::Arguments->rewrite("plain text\n");
is($unchanged, "plain text\n", 'rewrite leaves templates without args unchanged');
ok(!$has_no_args, 'rewrite reports when no args directive exists');

my $factory_calls = 0;
my $lazy_engine = Template::EmbeddedPerl->new(
    smart_lines => 1,
    helpers => {
        record_factory_call => sub { $factory_calls++ },
    },
);
my $lazy = $lazy_engine->from_string(<<'EPL');
% args $items, $title = sub {
%   record_factory_call();
%   my $count = @$items;
%   return $count == 1 ? 'One item' : "$count items";
% }
<%= defined $title ? $title : '' %>
EPL

is($lazy->render(items => [1, 2]), "2 items\n", 'lazy factory can use an earlier argument');
is($factory_calls, 1, 'lazy factory runs once when the argument is absent');
is($lazy->render(items => [], title => undef), "\n", 'explicit undef does not use default');
is($factory_calls, 1, 'lazy factory does not run for explicit undef');
is($lazy->render(items => [1], title => 'Custom'), "Custom\n", 'provided value overrides lazy factory');
is($factory_calls, 1, 'lazy factory does not run for a provided value');

throws_ok { $compiled->render } qr/Missing required template argument 'name'/;
throws_ok {
    $compiled->render(name => 'Jane', zebra => 1, alpha => 2);
} qr/Unknown template argument 'alpha'/;
throws_ok {
    $compiled->render(name => 'Jane', name => 'John');
} qr/Duplicate template argument 'name'/;
throws_ok {
    $compiled->render(name => 'Jane', 'odd');
} qr/Odd template argument list/;

my $source_validation = $engine->from_string(
    "% args \$name\n<%= \$name %>\n",
    source => 'views/argument-validation.epl',
);

throws_ok {
    $source_validation->render(name => 'Jane', 'odd');
} qr/Odd template argument list at views\/argument-validation\.epl line 1/;

throws_ok {
    $source_validation->render(name => 'Jane', name => 'John');
} qr/Duplicate template argument 'name' at views\/argument-validation\.epl line 1/;

my $following_directive_error = $engine->from_string(
    <<'EPL', source => 'views/argument-following-directive.epl',
% args $name
% die "following directive"
EPL
);

throws_ok {
    $following_directive_error->render(name => 'Jane');
} qr/following directive at views\/argument-following-directive\.epl line 2/;

my $multiline = $engine->from_string(<<'EPL');
# argument declaration follows a template comment

% args
%   $name,
%   $punctuation = (
%       1 ? '!' : '?'
%   )
<%= $name %><%= $punctuation %>
EPL

is(
    $multiline->render(name => 'Jane'),
    "\n\nJane!\n",
    'comments and blank lines may precede a multiline declaration',
);

my $custom_comment_engine = Template::EmbeddedPerl->new(
    smart_lines => 1,
    comment_mark => '//',
);
my $custom_comment;
lives_ok {
    $custom_comment = $custom_comment_engine->from_string(<<'EPL');
// custom template comment

% args $name
<%= $name %>
EPL
} 'configured template comments allow args to compile';

is(
    $custom_comment && $custom_comment->render(name => 'Jane'),
    "\n\nJane\n",
    'configured template comments may precede args',
);

throws_ok {
    $custom_comment_engine->from_string(
        "# visible text\n% args \$name\n",
        source => 'views/custom-comment-late-args.epl',
    );
} qr/args must be the first executable directive at views\/custom-comment-late-args\.epl line 2/;

throws_ok {
    $engine->from_string(
        "text\n% args \$name\n",
        source => 'views/late-args.epl',
    );
} qr/args must be the first executable directive at views\/late-args\.epl line 2/;

throws_ok {
    $engine->from_string("% my \$before = 1\n% args \$name\n");
} qr/args must be the first executable directive/;

throws_ok {
    $engine->from_string(
        "% args \$name\n% args \$other\n",
        source => 'views/duplicate-args.epl',
    );
} qr/args directive may only appear once at views\/duplicate-args\.epl line 2/;

for my $name (qw(__named_args __context _O self)) {
    throws_ok {
        $engine->from_string(
            "% args \$$name\n",
            source => "views/reserved-$name.epl",
        );
    } qr/Template argument '\Q$name\E' uses a reserved compiler identifier at views\/reserved-\Q$name\E\.epl line 1/;
}

for my $declaration (
    q{% args $name = 1; die "discarded"},
    q{% args $name = 1; $other = 2},
    q{% args $name = 1;},
) {
    throws_ok {
        $engine->from_string(
            "$declaration\n<%= \$name %>\n",
            source => 'views/extra-args-statement.epl',
        );
    } qr/invalid args directive at views\/extra-args-statement\.epl line 1/;
}

for my $case (
    [q{% args @items}, qr/scalar argument/],
    [q{% args $name =}, qr/default expression/],
    [q{% args $name,}, qr/incomplete args directive/],
    [q{% args $name, $name}, qr/Duplicate args declaration 'name'/],
) {
    throws_ok { $engine->from_string("$case->[0]\n") } $case->[1];
}

my $source_error = $engine->from_string(<<'EPL', source => 'views/arguments.epl');
# heading
% args $name
<%= $name %>
EPL

throws_ok {
    $source_error->render;
} qr/Missing required template argument 'name' at views\/arguments\.epl line 2/;

my $unknown_source = $engine->from_string(<<'EPL', source => 'views/unknown-argument.epl');
% args $name, $greeting = 'Hello'
<%= $greeting %>, <%= $name %>!
EPL

throws_ok {
    $unknown_source->render(name => 'Jane', extra => 1);
} qr/Unknown template argument 'extra' at views\/unknown-argument\.epl line 1/;

my $bad_default = $engine->from_string(<<'EPL', source => 'views/bad-default.epl');
% args $name = (
%   missing_function()
% )
<%= $name %>
EPL

throws_ok {
    $bad_default->render;
} qr/at views\/bad-default\.epl line 2/;

my $custom_syntax = Template::EmbeddedPerl->new(
    open_tag => '[[',
    close_tag => ']]',
    expr_marker => '?',
    line_start => '++',
    smart_lines => 1,
);
is(
    $custom_syntax->from_string(
        "++ args \$name = 'world'\n[[? uc \$name ]]",
    )->render,
    'WORLD',
    'args uses configured line and block markers',
);
is(
    $custom_syntax->from_string("% args \$name\n")->render,
    "% args \$name\n",
    'the default args marker remains literal when line_start is customized',
);

done_testing;
