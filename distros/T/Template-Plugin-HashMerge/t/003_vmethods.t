# -*- perl -*-

# t/003_vmethods.t - tests using the virtual methods

use Test::More tests => 7;

my $testData = q/[%
     a = {
             foo => 1,
             bar => [ 'a', 'b', 'e' ],
             baz => {
                        bob => 'alice',
                    },
         };
     b = {
             foo => 2,
             bar => [ 'c', 'd' ],
             baz => {
                        ted => 'margeret',
                    },
         };
%]/;

is tt( $testData, q{[% c = a.merge( b ); c.keys.sort.join(",") %]} ), "bar,baz,foo", "merge 1/7";
is tt( $testData, q{[% c = a.merge( b ); c.foo %]} ), "1", "merge 2/7";
is tt( $testData, q{[% c = a.merge( b ); c.bar.join(",") %]} ), "a,b,e,c,d", "merge 3/7";
is tt( $testData, q{[% c = a.merge( b ); c.baz.keys.sort.join(",") %]} ), "bob,ted", "merge 4/7";
is tt( $testData, q{[% c = a.merge( b ); c.baz.bob %]} ), "alice", "merge 5/7";
is tt( $testData, q{[% c = a.merge( b ); c.baz.ted %]} ), "margeret", "merge 6/7";

is tt( $testData, q{[% waste = HashMerge.set_behavior('RIGHT_PRECEDENT'); c = a.merge( b ); c.foo %]} ), "2", "merge 7/7";

sub tt
{
    my $template = join( '', q/[% USE HashMerge; USE HashMergeVMethods %]/, @_ );
    use Template;
    my $tt = Template->new();
    my $output;
    $tt->process( \$template, {}, \$output ) or
      die "Problem while processing '$template': " . $tt->error();
    return $output;
}
