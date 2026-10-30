#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T27::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::T; sub a { 1 }
    package $pkg;
    plugin 'MCP' => { session => 0, page_size => 2 };
    mcp tool => \$_ => 'T#a' for qw(e d c b a);
}, pkg => $pkg);

my (@pages, $cursor);
for (1 .. 5) {
    my (undef, $r) = list_tools($t, $cursor);
    push @pages, [map { $_->{name} } @{ $r->{result}{tools} }];
    $cursor = $r->{result}{nextCursor};
    last unless defined $cursor;
}
is_deeply(\@pages, [[qw(a b)], [qw(c d)], ['e']],
    'page_size 2 over five tools: three pages, in name order');
ok(!defined $cursor, 'the last page has no nextCursor');

my (undef, $first) = list_tools($t);
my $c1 = $first->{result}{nextCursor};
my (undef, $again) = list_tools($t);
is($again->{result}{nextCursor}, $c1, 'the same page gives the same cursor');

my $b64 = sub { (my $s = MIME::Base64::encode_base64($_[0], '')) =~ tr{+/}{-_};
                $s =~ s/=+$//; $s };
for my $case (
    [ 'garbage',              'not a cursor!' ],
    [ 'empty',                '' ],
    [ 'a number',             2 ],
    [ 'past the end',         $b64->('c5') ],
    [ 'zero',                 $b64->('c0') ],
    [ 'not ours',             $b64->('x2') ],
    [ 'a leading zero',       $b64->('c02') ],
    [ 'padded',               $b64->('c2') . '==' ],
) {
    my ($name, $c) = @$case;
    my (undef, $r) = list_tools($t, $c);
    is($r->{error}{code}, -32602, "a cursor that is $name: -32602");
    is($r->{error}{message}, 'invalid cursor', "a cursor that is $name: says so");
}
my (undef, $ok) = list_tools($t, $b64->('c2'));
is_deeply([map { $_->{name} } @{ $ok->{result}{tools} }], [qw(c d)],
    'a cursor is the index, so a well-formed one works');

done_testing;
