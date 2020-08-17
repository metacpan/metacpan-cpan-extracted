package NewsExtractor::SiteSpecificExtractor::www_aljazeera_com;
use utf8;
use Moo;

extends 'NewsExtractor::JSONLDExtractor';

with 'NewsExtractor::Role::ContentTextExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(u);
use Importer 'HTTP::Date' => qw(parse_date);

around dateline => sub {
    my ($orig) = shift;
    my $ret = $orig->(@_);
    my @t = parse_date($ret);
    return u(sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s', $t[0], $t[1], $t[2], $t[3], $t[4], $t[5], 'Z'));
};

1;

