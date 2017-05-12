=head1 UNIT TESTS FOR

PGObject::Util::DBChange

=cut

use PGObject::Util::DBChange;
use Test::More tests => 12;

my $testpath = 't/data/sql/';

=head1 TEST PLAN

Data is in t/data/sql

=head2 File Load Tests

=over

=item basic constructor, no properties for test1

=item basic constructor, all properties for test2

=item sha should be same for both, but different from test3

=back

=cut

my @properties = qw(no_transactions);
my $test1 = PGObject::Util::DBChange->new(path => $testpath . 'test1.sql');
ok($test1, 'got test1 object');
is($test1->path, 't/data/sql/test1.sql', 'got correct path for test1');
is($test1->$_, undef, "$_ property for test1 is undefined")
   for @properties;

my $test2 = PGObject::Util::DBChange->new(path => $testpath . 'test2.sql',
            map { $_ => 1 } @properties );


ok($test2, 'got test2 object');
is($test2->path, 't/data/sql/test2.sql', 'got correct path for test2');
is($test2->$_, 1, "$_ property for test2 is 1")
   for @properties;

is($test1->sha, $test2->sha, 'SHA is equal for both test1 and test2');

isnt($test1->sha, PGObject::Util::DBChange->new(path => $testpath . 'test3.sql')->sha, 'SHA changes when content chenges');

=head2 Wrapping Tests

=over

=item test1 should have begin/commit when asking for content

=item test2 should not have begin/commit when asking for content

=back

=cut

like($test1->content_wrapped, qr/BEGIN;/, 'Test1 content has BEGIN');
like($test1->content_wrapped, qr/COMMIT;/, 'Test1 content has COMMIT');

unlike($test2->content_wrapped, qr/BEGIN;/, 'Test2 content has no BEGIN');
unlike($test2->content_wrapped, qr/COMMIT;/, 'Test2 content has no COMMIT');
