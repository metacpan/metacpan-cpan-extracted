#!perl -wT
use strict;
use PPI::Document;
use Test::Exception;
use Test::More tests => 7;
use_ok('Perl::Metric::Basic');

my $m = Perl::Metric::Basic->new;
isa_ok($m, 'Perl::Metric::Basic');

throws_ok { $m->measure() } qr/No PPI::Document passed/;

throws_ok { $m->measure($m) } qr/No PPI::Document passed/;

my ($document, $metric);

$document = PPI::Document->new("t/lib/Acme.pm");
isa_ok($document, 'PPI::Document');

lives_ok { $metric = $m->measure($document) };

is_deeply(
  $metric,
  {
    'Acme' => {
      'new' => {
        'blank_lines'      => 1,
        'comments'         => 1,
        'lines'            => 7,
        'lines_of_code'    => 6,
        'numbers'          => 0,
        'numbers_unique'   => 0,
        'operators'        => 3,
        'operators_unique' => 2,
        'symbols'          => 5,
        'symbols_unique'   => 2,
        'words'            => 7,
        'words_unique'     => 6
      },
      'no_comments' => {
        'blank_lines'      => 0,
        'comments'         => 0,
        'lines'            => 3,
        'lines_of_code'    => 3,
        'numbers'          => 1,
        'numbers_unique'   => 1,
        'operators'        => 1,
        'operators_unique' => 1,
        'symbols'          => 1,
        'symbols_unique'   => 1,
        'words'            => 5,
        'words_unique'     => 5
      },
    }
  },
);

#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
#die Dumper $metric;

