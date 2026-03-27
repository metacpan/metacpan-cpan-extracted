use strict;
use warnings;
use Test::More tests => 12;

BEGIN { use_ok('Sekhmet') };

can_ok('Sekhmet', 'ulid');
can_ok('Sekhmet', 'ulid_binary');
can_ok('Sekhmet', 'ulid_monotonic');
can_ok('Sekhmet', 'ulid_monotonic_binary');
can_ok('Sekhmet', 'ulid_time');
can_ok('Sekhmet', 'ulid_time_ms');
can_ok('Sekhmet', 'ulid_to_uuid');
can_ok('Sekhmet', 'uuid_to_ulid');
can_ok('Sekhmet', 'ulid_compare');
can_ok('Sekhmet', 'ulid_validate');
can_ok('Sekhmet', 'include_dir');

diag( "Testing Sekhmet $Sekhmet::VERSION, Perl $], $^X" );
