use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter bang | foo

bar foo bar

=end filter
---
<html><body bgcolor="#ffffff">
<pre>ba! bar ba!</pre>
</body></html>
===
=begin filter foo | bang

bar foo bar

=end filter
---
<html><body bgcolor="#ffffff">
<pre>ba! ba! ba!</pre>
</body></html>
TESTS

plan tests => scalar @tests + 2;

# add a new language
Pod::POM::View::HTML::Filter->add(
    foo     => { code => sub { my $s = shift; $s =~ s/foo/bar/g; $s } },
    options => { code => sub { "[$_[0]]<$_[1]>" } },
    bang => {
        code     => sub { my $s = shift; $s =~ y/r/!/; $s },
        verbatim => 1
    },
);

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

# check what happens if $pom->present is called twice in a row
my $pom = $parser->parse_text( << 'EOT' ) || diag $parser->error;
=begin filter foo | bang

    foo bar baz

=end filter foo
EOT
my $expected = << 'EOT';
<html><body bgcolor="#ffffff">
<pre>    ba! ba! baz</pre>
</body></html>
EOT

is( "$pom", $expected, "Correct output the first time" );
is( "$pom", $expected, "Correct output the second time around" );

