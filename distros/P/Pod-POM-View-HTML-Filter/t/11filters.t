use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter foo

bar foo bar
baz

=end
---
<html><body bgcolor="#ffffff">
bar bar bar
baz
</body></html>
===
=begin filter foo

    foo bar baz

=end filter foo
---
<html><body bgcolor="#ffffff">
<pre>    bar bar baz</pre>
</body></html>
===
this line is considered code by Pod::POM

=for filter=foo
bar foo bar

para
---
<html><body bgcolor="#ffffff">
bar bar bar
<p>para</p>
</body></html>
===
=pod

para

=for filter=foo
bar bar foo
foo bar bar

para
---
<html><body bgcolor="#ffffff">
<p>para</p>
bar bar bar
bar bar bar
<p>para</p>
</body></html>
===
=begin filter options a b c

The options are:

=end
---
<html><body bgcolor="#ffffff">
[The options are:]<a b c>
</body></html>
===
=begin filter verb

    verbatim block

verbatim textblock

=end
---
<html><body bgcolor="#ffffff">
<pre>    verbatim block

verbatim textblock</pre>
</body></html>
TESTS

plan tests => scalar @tests + 2;

# add a new language
Pod::POM::View::HTML::Filter->add(
    foo     => { code => sub { my $s = shift; $s =~ s/foo/bar/g; $s } },
    options => { code => sub { "[$_[0]]<$_[1]>" } },
    verb    => { code => sub { $_[0] }, verbatim => 1 },
);

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

# check what happens if $pom->present is called twice in a row
my $pom = $parser->parse_text( << 'EOT' ) || diag $parser->error;
=begin filter foo

    foo bar baz

=end filter foo
EOT
my $expected = << 'EOT';
<html><body bgcolor="#ffffff">
<pre>    bar bar baz</pre>
</body></html>
EOT

is( "$pom", $expected, "Correct output the first time" );
is( "$pom", $expected, "Correct output the second time around" );

