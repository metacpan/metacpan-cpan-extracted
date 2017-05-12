use strict;
use warnings;
use HTTP::Tiny;
use Mojo::DOM58;
use Encode 'decode';

# Extract named character references from HTML Living Standard
my $res = HTTP::Tiny->new->get('https://html.spec.whatwg.org');
my $dom = Mojo::DOM58->new(decode 'UTF-8', $res->{content});
my $rows = $dom->find('#named-character-references-table tbody > tr');
for my $row ($rows->each) {
  my $entity     = $row->at('td > code')->text;
  my $codepoints = $row->children('td')->[1]->text;
  print "$entity $codepoints\n";
}

1;
