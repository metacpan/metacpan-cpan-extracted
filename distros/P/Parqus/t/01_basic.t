#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use Test::Warnings;

BEGIN { use_ok('Parqus'); }

sub _parse_error {
    my ($res, $expected, $msg) = @_;

    # make prove report correct line
    local  $Test::Builder::Level = $Test::Builder::Level + 1;

    $msg //= 'found parse error';
    ok( exists $res->{errors}, 'result has errors.');
    is( $res->{errors}[0], $expected, $msg );
    return $res;
}
sub _parse_ok {
    my ($parser, $query, $msg) = @_;

    # make prove report correct line
    local  $Test::Builder::Level = $Test::Builder::Level + 1;

    $msg //= 'no parse error';
    my $res = $parser->process($query);
    ok( !exists $res->{errors}, $msg );
    return $res;
}

### Parser 1
{
    my $parser = Parqus->new();
    ok( $parser, 'new without keywords option.' );
    _parse_ok( $parser, 'foo' );
}

### Parser 2
{
    my $parser = Parqus->new( keywords => [qw/ title name /] );
    ok( $parser, 'new with keywords option.' );

    my $res = _parse_ok( $parser, '' );
    is_deeply( $res, {}, 'parse empty string.' );

    $res = _parse_ok( $parser, 'foo' );

    $res = _parse_ok($parser, ' foo ');
    is_deeply( $res, { words => ['foo'] }, 'parse single word with leading and trailing whitespace.' );

    $res = _parse_ok($parser, 'title: foo');
    is_deeply( $res, { keywords => { title => ['foo'] } }, 'parse single keyword.' );

    $res = $parser->process('nokeyword: foo');
    _parse_error($res, 'Parse Error: Invalid search query.');

    $res = _parse_ok($parser, '"nokeyword: foo"');
    is_deeply( $res, { words => ['nokeyword: foo'] }, 'parse quoted invalid keyword.' );

    $res = _parse_ok($parser, '"foo bar"');
    is_deeply( $res, { words => ['foo bar'] }, 'parse quoted words.' );

    $res = _parse_ok($parser, q/"I'am root&%$"/);
    is_deeply( $res, { words => [q/I'am root&%$/] }, 'parse quoted words with special chars.' );

    $res = _parse_ok($parser, 'name:"foo bar"');
    is_deeply( $res, { keywords => { name => ['foo bar'] } }, 'parse keyword with quoted value.' );

    $res = _parse_ok($parser, 'name:"foo bar" name:baz meh "mii"');
    my $expected = {
        words => [ 'meh' , 'mii' ],
        keywords => {
            name => ['foo bar', 'baz'],
        },
    };
    is_deeply( $res, $expected, 'mix words and keywords.' );

    $res = $parser->process('&');
    _parse_error($res, 'Parse Error: Invalid search query.');

    $res = $parser->process('fo=o');
    _parse_error( $res, 'Parse Error: Invalid search query.' );
}

### Parser 3
{
    my $parser = Parqus->new( value_regex => qr/[\w=-]+/ );
    ok( $parser, 'new with custom value_regex.' );

    my $res = _parse_ok($parser, 'fo=o');
    is_deeply( $res, { words => ['fo=o'] }, 'parse unquoted word with special character.' );
}

### Parser 4
{
    my $parser = Parqus->new(
        keywords => [qw/ title name /],
        string_delimiters => ['"!']
    );
    ok( $parser, 'new with string_delimiters and keywords option.' );

    $res = _parse_ok($parser, q/!foo bar!/);
    is_deeply( $res, { words => ['foo bar'] }, 'found quoted words.' );

    $res = _parse_ok($parser, 'name:"foo bar" name:!baz! !meh! "mii"');
    my $expected = {
        words => [ 'meh' , 'mii' ],
        keywords => {
            name => ['foo bar', 'baz'],
        },
    };
    is_deeply( $res, $expected, 'mix words and keywords.' );
}

done_testing();
