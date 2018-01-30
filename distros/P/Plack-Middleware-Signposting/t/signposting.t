use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = "Plack::Middleware::Signposting";
    use_ok $pkg;
}
require_ok $pkg;

lives_ok { $pkg->new() } "object construction";

my $sp = $pkg->new();

can_ok $sp, 'to_link_format';

is
    $sp->to_link_format(['https://doi.org/10.1234/987','describedby']),
    '<https://doi.org/10.1234/987>; rel="describedby"',
    "correct link format";

is
    $sp->to_link_format(['https://doi.org/10.1234/987','describedby','http://schema.org/ScholarlyArticle']),
    '<https://doi.org/10.1234/987>; rel="describedby"; type="http://schema.org/ScholarlyArticle"',
    "correct link format with type";

done_testing;
