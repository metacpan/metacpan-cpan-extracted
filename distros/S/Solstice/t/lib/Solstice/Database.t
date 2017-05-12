#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Solstice::Database;

plan(tests => 6);

my $db;

ok($db = new Solstice::Database(),
   "Creating a new Solstice::Database.");

$db->writeQuery("CREATE TEMPORARY TABLE temp_test_table (id int primary key not null auto_increment, value varchar(20))");

is($db->writeQuery("INSERT INTO temp_test_table SET value = ?", 'yeah!'),
   undef, "writeQuery()");

my $last_id;

ok($last_id = $db->getLastInsertID(),
   "getLastInsertID()");

is($db->readQuery("SELECT value FROM temp_test_table WHERE id = ?", $last_id), undef, "readQuery()");

my $results = $db->fetchRow();

cmp_ok($results->{'value'}, 'eq', 'yeah!',
       "readQuery() accuracy");

ok(!$db->fetchRow(), "No more rows to read");

$db->writeQuery("DELETE FROM temp_test_table WHERE id = ?", $last_id);

$db->writeQuery("DROP TABLE temp_test_table");

exit 0;


=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
