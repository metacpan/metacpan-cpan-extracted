use Test::More tests => 6;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $view = $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

# no foo built-in
my @foo_filters = grep { /^foo$/ } $view->filters;
is( @foo_filters, 0, "No foo filter");
ok( ! $view->know( 'foo' ), "Don't know foo" );

# test some foo filter anyway
my $parser = Pod::POM->new;

# test verbatim text
my $pom = $parser->parse_text( <<'EOT' ) || diag $parser->error;
=head1 Foo

The foo filter at work:

=begin filter foo

    $A++;

=end filter
EOT
is( "$pom", << 'EOH', "Default is simply naught (<pre>)");
<html><body bgcolor="#ffffff">
<h1>Foo</h1>

<p>The foo filter at work:</p>
<pre>    $A++;</pre>
</body></html>
EOH

# test normal text
$pom = $parser->parse_text( <<'EOT' ) || diag $parser->error;
=head1 Foo

The foo filter at work:

=begin filter foo

$A++;

=end filter
EOT
is( "$pom", << 'EOH', "Default is simply naught (<pre>)");
<html><body bgcolor="#ffffff">
<h1>Foo</h1>

<p>The foo filter at work:</p>
<pre>$A++;</pre>
</body></html>
EOH

# test $Pod::POM::View::HTML::Filter::default
# add a foo filter
Pod::POM::View::HTML::Filter->add(
    foo  => { code => sub { my $s = shift; $s =~ s/foo/bar/g; $s } },
);

# check that it works
$pom = $parser->parse_text(<<'EOT') or diag $parser->error;
=begin filter foo

bar foo bar
baz

=end
EOT

is( "$pom", <<'EOH', "Correct output" );
<html><body bgcolor="#ffffff">
bar bar bar
baz
</body></html>
EOH

# set it back to default
Pod::POM::View::HTML::Filter->delete('foo');

# check that foo == default
$pom = $parser->parse_text(<<'EOT') or diag $parser->error;
=begin filter foo

bar foo bar
baz

=end
EOT

is( "$pom", <<'EOH', "Correct output" );
<html><body bgcolor="#ffffff">
<pre>bar foo bar
baz</pre>
</body></html>
EOH

