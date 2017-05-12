use lib 'blib/lib';
require Test::More;
use Plucene::Plugin::WeightedQueryParser;
use Plucene::Analysis::SimpleAnalyzer;

my $parser = Plucene::Plugin::WeightedQueryParser->new({
                analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
                weights  => {
                        foo => 10,
                        bar => 5
                }
});

@tests= (
    [ "foo:bar", "foo:bar" ],
    [ "test:hello bar", "test:hello (foo:bar^10 bar:bar^5)"],
    [ "hi \"phrase query\"", '(foo:hi^10 bar:hi^5) (foo:"phrase query"^10 bar:"phrase query"^5)' ],
);

Test::More->import(tests => 1 + @tests);
isa_ok($parser, "Plucene::Plugin::WeightedQueryParser");

for (@tests) {
    my ($input, $round_trip) = @$_;
    my $query = $parser->parse($input);
    is($query->to_string(""), $round_trip, "$input parsed OK");
}
