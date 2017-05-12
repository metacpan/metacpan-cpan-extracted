# -*- perl -*-

# t/002_objinterface.t - tests using the OO interface

use Test::More tests => 8;

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

is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.keys.sort.join(",") %]} ), "bar,baz,foo", "merge 1/8";
is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.foo %]} ), "1", "merge 2/8";
is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.bar.join(",") %]} ), "a,b,e,c,d", "merge 3/8";
is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.baz.keys.sort.join(",") %]} ), "bob,ted", "merge 4/8";
is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.baz.bob %]} ), "alice", "merge 5/8";
is tt( $testData, q{[% c = HashMerge.merge( a, b ); c.baz.ted %]} ), "margeret", "merge 6/8";

is tt( $testData, q{[% waste = HashMerge.set_behavior('RIGHT_PRECEDENT'); c = HashMerge.merge( a, b ); c.foo %]} ), "2", "merge 7/8";
is tt( $testData, q{[% waste = HashMerge.set_behavior('RIGHT_PRECEDENT'); HashMerge.get_behavior() %]} ), "RIGHT_PRECEDENT", "merge 8/8";

sub tt
{
    my $template = join( '', q/[% USE HashMerge %]/, @_ );
    use Template;
    my $tt = Template->new();
    my $output;
    $tt->process( \$template, {}, \$output ) or
      die "Problem while processing '$template': " . $tt->error();
    return $output;
}

