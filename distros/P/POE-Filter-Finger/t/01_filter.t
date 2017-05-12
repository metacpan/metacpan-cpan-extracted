use strict;
use warnings;
use Test::More tests => 4;
use_ok('POE::Filter::Finger');
use Test::Deep;

my $filter = POE::Filter::Finger->new();
isa_ok( $filter, 'POE::Filter::Finger' );
isa_ok( $filter, 'POE::Filter' );

my @tests = ( '', 'bingos', 'bingos@example.org@example.com', 'this is garbage' );

my $expected = [
          {
            'listing' => {
                           'verbose' => ''
                         }
          },
          {
            'user' => {
                        'verbose' => '',
                        'username' => 'bingos'
                      }
          },
          {
            'forward' => {
                           'verbose' => '',
                           'hosts' => [
                                        'example.org',
                                        'example.com'
                                      ],
                           'username' => 'bingos'
                         }
          },
          {
            'unknown' => 'this is garbage'
          }
        ];

my $output = $filter->get( \@tests );

cmp_deeply(
  $output,
  $expected,
  'Did we get what we expected',
);
