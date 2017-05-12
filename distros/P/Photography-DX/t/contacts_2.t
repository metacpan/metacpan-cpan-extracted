use strict;
use warnings;
use Test::More tests => 6;
use Photography::DX;

is(Photography::DX->new(length => 24, tolerance => 0.5)->contacts_row_2, '111000', 'okay for length 24 tolerance 0.5');
is(Photography::DX->new(length => 36, tolerance => 3.0)->contacts_row_2, '100111', 'okay for length 36 tolerance 3  ');

my $film1 = Photography::DX->new(contacts_row_2 => '111000');
is $film1->length,     24, 'okay length 24 (reverse)';
is $film1->tolerance, 0.5, 'okay tolerance 0.5 (reverse)';

my $film2 = Photography::DX->new(contacts_row_2 => '100111');
is $film2->length,    36, 'okay length 36 (reverse)';
is $film2->tolerance, 3,  'okay tolerance 3 (reverse)';
