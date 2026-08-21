#!/usr/bin/env perl

use v5.38;
use Test::More;

use PAGI::FastAPI::Cookies qw(parse_cookies cookie);

subtest 'parse_cookies() parses a simple multi-cookie header' => sub {
    my $c = parse_cookies('session_id=abc123; theme=dark');
    is($c->{session_id}, 'abc123', 'first cookie parsed');
    is($c->{theme}, 'dark', 'second cookie parsed');
};

subtest 'parse_cookies() percent-decodes values' => sub {
    my $c = parse_cookies('greeting=hello%20world');
    is($c->{greeting}, 'hello world', 'percent-encoded space decoded');
};

subtest 'parse_cookies() skips malformed pairs without dying' => sub {
    my $c = parse_cookies('good=1; malformed_no_equals; also_good=2');
    is($c->{good}, '1', 'pair before the malformed one still parsed');
    is($c->{also_good}, '2', 'pair after the malformed one still parsed');
    is(exists $c->{malformed_no_equals}, '', 'the malformed entry itself is not present');
};

subtest 'parse_cookies() treats an explicitly empty value as empty string, not missing' => sub {
    my $c = parse_cookies('empty=; other=1');
    ok(exists $c->{empty}, 'key exists');
    is($c->{empty}, '', 'value is empty string');
};

subtest 'parse_cookies() handles undef/empty header safely' => sub {
    my $c1 = parse_cookies(undef);
    is(ref $c1, 'HASH', 'undef input returns a HashRef, not undef');
    is(scalar keys %$c1, 0, 'and it is empty');

    my $c2 = parse_cookies('');
    is(ref $c2, 'HASH', 'empty-string input returns a HashRef, not undef');
    is(scalar keys %$c2, 0, 'and it is empty');
};

subtest 'parse_cookies() trims leading whitespace from cookie names' => sub {
    my $c = parse_cookies('a=1;  b=2;   c=3');
    is($c->{a}, '1', 'first cookie');
    is($c->{b}, '2', 'second cookie, extra leading space trimmed');
    is($c->{c}, '3', 'third cookie, extra leading space trimmed');
};

subtest 'cookie($c, $name) reads a single value via a fake context' => sub {
    package MockContext {
        sub new    ($class, $cookie_header) { return bless { cookie => $cookie_header }, $class }
        sub header ($self, $name) { return $name eq 'Cookie' ? $self->{cookie} : undef }
    }

    my $c = MockContext->new('session_id=xyz; theme=light');
    is(cookie($c, 'session_id'), 'xyz', 'reads the requested cookie');
    is(cookie($c, 'theme'), 'light', 'reads a different cookie from the same header');
    is(cookie($c, 'nonexistent'), undef, 'returns undef for a cookie that is not present');
};

subtest 'cookie($c, $name) handles a context with no Cookie header at all' => sub {
    package MockContextNoCookie {
        sub new    ($class) { return bless {}, $class }
        sub header ($self, $name) { return undef }
    }

    my $c = MockContextNoCookie->new;
    is(cookie($c, 'anything'), undef, 'undef, not a die, when there is no Cookie header');
};

done_testing;
