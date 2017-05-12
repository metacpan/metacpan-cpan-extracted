use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

plan skip_all => "Don't know perl"
  unless Pod::POM::View::HTML::Filter->know( 'perl' );

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

plan tests => 2;

# a test for Perl::Tidy in conjuction with Get::Long::Configure
# the bug was corrected in perltidy-20060614
use Getopt::Long;
Getopt::Long::Configure("bundling");

my $str;
my $parser = Pod::POM->new();
my $pom = $parser->parse_text("=begin filter perl\n\n    \$A++\n\n=end filter")
  || diag $parser->error;
eval { $str = "$pom" };

is( $str, <<'EOH', "Correct output" );
<html><body bgcolor="#ffffff">
<pre>    <span class="i">$A</span>++</pre>
</body></html>
EOH

is($@, '', "No error when Getopt::Long::Configure called");

