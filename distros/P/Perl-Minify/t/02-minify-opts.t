#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify);

# Fixture: code with comments, POD, whitespace, and a my var
my $code = <<'END_PERL';
# this is a comment
=pod
POD documentation
=cut

use strict;
use warnings;

my $variable = 42;
print   "Hello, $variable!\n";
END_PERL

# Default options
my $default = minify($code);
ok(defined($default), 'minify returns defined result with defaults');
ok($default !~ /# this is a comment/,  'default: comments stripped');
ok($default !~ /POD documentation/,    'default: POD stripped');

# strip_comments => 0
my $with_comments = minify($code, { strip_comments => 0 });
ok(defined($with_comments), 'minify returns defined with strip_comments=0');
ok($with_comments =~ /# this is a comment/, 'strip_comments=0: comments preserved');
ok($with_comments !~ /POD documentation/,   'strip_comments=0: POD still stripped');

# strip_pod => 0
my $with_pod = minify($code, { strip_pod => 0 });
ok(defined($with_pod), 'minify returns defined with strip_pod=0');
ok($with_pod !~ /# this is a comment/, 'strip_pod=0: comments still stripped');
ok($with_pod =~ /POD documentation/,   'strip_pod=0: POD preserved');

# strip_whitespace => 0
my $no_ws = minify($code, { strip_whitespace => 0 });
ok(defined($no_ws), 'minify returns defined with strip_whitespace=0');
ok($no_ws =~ /my \$variable = 42/, 'strip_whitespace=0: code preserved');

# shorten_vars => 1
my $short = minify($code, { shorten_vars => 1 });
ok(defined($short), 'minify returns defined with shorten_vars=1');
ok($short =~ /\$c\b/, 'shorten_vars=1: $variable shortened to $c');

# wrap => 40
my $wrapped = minify($code, { wrap => 40 });
ok(defined($wrapped), 'minify returns defined with wrap=40');
for my $line (split "\n", $wrapped) {
    ok(length($line) <= 40, "wrap=40: line length ${\length($line)} <= 40")
        or diag "Line exceeds limit: [$line]";
}

# Unknown options ignored silently
my $unknown = minify($code, { bogus_option => 42 });
ok(defined($unknown), 'minify ignores unknown options');
is($unknown, $default, 'unknown option produces same result as defaults');


# Keyword before block: space deleted (else{, sub name{, grep{)
my $kw = minify('my $x = 1; if ($x) { $x++; } else { } sub do_thing { return $x; } my @r = grep { $_ } ($x);', { strip_whitespace => 1 });
ok(defined($kw), 'keyword-before-block minify returns defined') or diag "got: " . ($kw // 'undef');
unlike($kw, qr/else \{/, 'space before else{} removed') or diag "got: $kw";
unlike($kw, qr/do_thing \{/, 'space before sub-name{} removed') or diag "got: $kw";
unlike($kw, qr/grep \{/, 'space before grep{} removed') or diag "got: $kw";
# hash-index shorthand still protected: $h{ key } keeps inner space
my $hi = minify('my %h; my $v = $h{ key };', { strip_whitespace => 1 });
ok(defined($hi), 'hash index returns defined');
like($hi, qr/\{key\}/, 'bareword hash key spacing tightened safely') or diag "got: $hi";
done_testing;
