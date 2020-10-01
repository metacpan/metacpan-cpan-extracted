use strict;
use warnings;

BEGIN {
    use vars qw(@tests);
    @tests = (
      [
        [
          {
            'RELATION' => 0,
            'CASE' => 1,
            'MISSING' => 2,
            'ATTRSET' => '1.2.840.10003.3.1',
            'SORT_ATTR' => [
              {
                'ATTR_TYPE' => 1,
                'ATTR_VALUE' => 4
              }
            ]
          },
          {
            'RELATION' => 1,
            'ATTRSET' => '1.2.840.10003.3.1',
            'MISSING' => 2,
            'CASE' => 1,
            'SORT_ATTR' => [
              {
                'ATTR_TYPE' => 1,
                'ATTR_VALUE' => 12
              }
            ]
          }
         ],
         'title/sort.missingLow/sort.ascending/sort.ignoreCase hrid/sort.descending'
        ],
    );
}

use Test::More tests => 2*scalar(@tests) + 2;

BEGIN { use_ok('Net::Z3950::FOLIO') };

# Avoid warnings from failed variable substitution
$ENV{OKAPI_URL} = $ENV{OKAPI_TENANT} = $ENV{OKAPI_USER} = $ENV{OKAPI_PASSWORD} = 'x';

my $service = new Net::Z3950::FOLIO('etc/config.json');
ok(defined $service, 'made FOLIO service object');

foreach my $test (@tests) {
    my($input, $output) = @$test;

    my $result = $service->_sortspecs2cql($input);
    ok(defined $result, "translated sort-spec");
    is($result, $output, "generated correct sortspec: $output");
}
