use utf8;
use Test::Most;
use Template::EmbeddedPerl::Utils 'escape_javascript';

{
    my $input = q{He said, "Hello World!"};
    my $expected = q{He said, \"Hello World!\"};
    is(escape_javascript($input), $expected, 'Test Case 1');
}

{
    my $input = q{It's a beautiful day!};
    my $expected = q{It\'s a beautiful day!};
    is(escape_javascript($input), $expected, 'Test Case 2');
}

{
    my $input = q{Total cost is `$100` dollars.};
    my $expected = q{Total cost is \`\$100\` dollars.};
    is(escape_javascript($input), $expected, 'Test Case 4');
}

{
    my $input = "Text\x{2028}More Text\x{2029}End";
    my $expected = q{Text\u2028More Text\u2029End};
    is(escape_javascript($input), $expected, 'Test Case 6');
}


{
    my $input = q{if (a < b) { return a > c; }};
    my $expected = q{if (a < b) { return a > c; }};
    is(escape_javascript($input), $expected, 'Test Case 8');
}

{
    my $input = "Emoji: \x{1F600}";  # Grinning Face Emoji
    my $expected = q{Emoji: \ud83d\ude00};
    is(escape_javascript($input), $expected, 'Test Case 10');
}

done_testing();