#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use Test::Warnings;

BEGIN { use_ok('Parqus'); }

{
    my $parser = Parqus->new();
    ok( $parser, 'got a Parqus instance without passing keywords.' );
    my $res = $parser->process('foo');
    ok(!exists $res->{errors}, 'no error');
}

my $parser = Parqus->new( keywords => [qw/ title name /] );
ok( $parser, 'got a Parqus instance with passing keywords.' );

{
    my $res = $parser->process('');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, {}, 'parse empty string.' );
}
{
    my $res = $parser->process('foo');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => ['foo'] }, 'parse single word.' );
}
{
    my $res = $parser->process('fo=o');
    ok(exists $res->{errors}, 'invalid keyword.');
    is( $res->{errors}[0], 'Parse Error: Invalid search query.', 'found parse error.' );
}
{
    my $parser = Parqus->new( value_regex => qr/[\w=-]+/ );
    ok( $parser, 'got a Parqus instance with custom value_regex.' );
    my $res = $parser->process('fo=o');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => ['fo=o'] }, 'parse unquoted word with special character.' );
}
{
    my $res = $parser->process(' foo ');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => ['foo'] }, 'parse single word with leading and trailing whitespace.' );
}
{
    my $res = $parser->process('title: foo');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { keywords => { title => ['foo'] } }, 'parse single keyword.' );
}
{
    my $res = $parser->process('nokeyword: foo');
    ok(exists $res->{errors}, 'invalid keyword.');
    is( $res->{errors}[0], 'Parse Error: Invalid search query.', 'found parse error.' );
}
{
    my $res = $parser->process('"nokeyword: foo"');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => ['nokeyword: foo'] }, 'parse quoted invalid keyword.' );
}
{
    my $res = $parser->process('"foo bar"');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => ['foo bar'] }, 'parse quoted words.' );
}
{
    my $res = $parser->process(q/"I'am root&%$"/);
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { words => [q/I'am root&%$/] }, 'parse quoted words with special chars.' );
}
{
    my $res = $parser->process('name:"foo bar"');
    ok(!exists $res->{errors}, 'no error');
    is_deeply( $res, { keywords => { name => ['foo bar'] } }, 'parse keyword with quoted value.' );
}
{
    my $res = $parser->process('name:"foo bar" name:baz meh "mii"');
    ok(!exists $res->{errors}, 'no error');
    my $expected = {
        words => [ 'meh' , 'mii' ],
        keywords => {
            name => ['foo bar', 'baz'],
        },
    };
    is_deeply( $res, $expected, 'mix words and keywords.' );
}
{
    my $res = $parser->process('&');
    ok( exists $res->{errors}, 'unquoted special chars causes error.');
    is( $res->{errors}[0], 'Parse Error: Invalid search query.', 'found parse error.' );
}

done_testing();
