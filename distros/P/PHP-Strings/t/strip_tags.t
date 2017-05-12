#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 10;
use Test::Differences;
use File::Slurp;
use lib 't';
use TestPHP;

BEGIN { use_ok 'PHP::Strings', ':strip_tags' };

chdir 't' if -d 't';

sub test_with_php
{
    my ( $html, $expected, $allowed, $comment ) = @_;
    $html = read_file( "html/$html.html" );
    $expected = read_file( "html/$expected.html" );

    my $text = strip_tags( $html, ( defined $allowed ? $allowed : () ) );
    eq_or_diff( $text, $expected, $comment );

    # Then, let's see what PHP has to say.
    SKIP:
    {
        skip "No PHP", 1 unless find_php;
        my $php = read_php( sprintf <<'EOF',
<?
$html = <<<EOH
%s
EOH;
print strip_tags( $html%s );
?>
EOF
            $html,
            ( defined $allowed ? ", '$allowed'" : '' ),
        );
        eq_or_diff( $php, $expected, "$comment - with PHP" );
    }

    #diag "\n[$php]\n[$with_script]\n[$text]\n";
}

# Good inputs
{
    test_with_php(
        '01html', '01stripped',
        undef,
        "HTML::Scrubber example"
    );
    test_with_php(
        '01html', '02stripped',
        '<script><style>',
        "HTML::Scrubber example, with some stripping"
    );

}

# Bad inputs
{
    eval { strip_tags( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { strip_tags( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { strip_tags( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for allowed" );
    eval { strip_tags( "Foo", "frob" ) };
    like( $@, qr/^Parameter #2.*regex check/, "Bad content for allowed" );
    eval { strip_tags( "Foo", "<br>", "", 0 ) };
    like( $@, qr/^4 parameters.* 1 - 2 were expected/, "Too many arguments" );
}
