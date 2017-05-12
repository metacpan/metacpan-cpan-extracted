use strict;
use warnings;

use Test::More tests => 6;
use lib 't/lib'; # Needed for 'make test' from project dirs
use PDFAPI2Mock;

BEGIN {
    use_ok('PDF::Table');
}

local $SIG{__WARN__} = sub { my $message = shift;  die $message; };

my $pdf    = PDF::API2->new;
my $page   = $pdf->page;
my $object = PDF::Table->new($pdf, $page);

my $data     = [ 'foo', 'bar', 'baz' ];
my $required = [ x => 10,
                 w => 300,
                 start_y => 750,
                 next_y => 700,
                 start_h => 40,
                 next_h => 500 ];

ok($object->table($pdf, $page, [$data], @$required));

eval { $object->table('pdf', $page, [$data], @$required) };
like($@, qr/Error: Invalid pdf object received/);

eval { $object->table($pdf, 'page', [$data], @$required) };
like($@, qr/Error: Invalid page object received/);

eval { $object->table($pdf, $page, 'data', @$required) };
like($@, qr/Error: Invalid data received/);

eval { $object->table($pdf, $page, 'data', 'required') };
like($@, qr/Odd number of elements in hash assignment/);

done_testing();

