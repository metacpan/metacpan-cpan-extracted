# perl
#
# Performance test of PQL::Cache
#
# Ralf Peine, Sat Nov 15 08:52:32 2014

use strict;
use warnings;

$| = 1;

use Data::Dumper;
use Time::HiRes qw(gettimeofday);

use Report::Porf qw(:all);

use PQL::Cache;
use Person;

my $max_persons = shift;

# ==============================================================================

my $cache = PQL::Cache->new();

# ==============================================================================

$cache->set_table_definition
    ('person',
     {
	 keys    => [ID => 'birth'],
	 columns => [prename => surname => gender => 'perl_level']
     });

$cache->set_table_definition
    ('location',
     {
	 keys    => ['ID'],
	 columns => [country => state => city => street => 'number']
     });

my $person_id = 1;

# --- Persons -------------------------------------------------------------

print "Insert $max_persons ...\n";

my $start_time = gettimeofday();

$cache->insert(person => Person->new({
	ID       => $person_id++,
	prename  => 'Ralf',
	surname  => 'Peine',
	gender   => 'male',
	birth    => '1965-12-29',
	location => 1,             # cannot be searched!
	perl_level => 'CPAN',
	       })
    );

my @arr;
foreach $person_id (2..$max_persons) {
    $cache->insert(person => Person->new({
#     push(@arr, Person->new({
	ID       => $person_id++,
	prename  => "Vorname_$person_id",
	surname  => "Nachname_$person_id",
	gender   => $person_id %2 ? 'male': 'female',
	birth    => sprintf ("%4d-01-01", $person_id % 10000),
	location => $person_id,             # cannot be searched!
	perl_level => "level_$person_id",
		   })
	);
    print "persons inserted: $person_id\n" unless $person_id % 100000;
}

my $duration = gettimeofday() - $start_time;

print "ready ... $duration\n";

# --- locations -------------------------------------------------------------

my $location_id = 1;

$cache->insert(location => {
    ID      => $location_id++,
    country => 'Germany',
    state   => 'NRW',
    city    => 'Bochum',
    street  => 'Rechener Str.',
    number  => 9, 
	       }
    );

# --- select -------------------------------------------------------------

my $result;

print "select (prename => { like => 'Vorname_12.4'})\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ prename => { like => 'Vorname_12.4'}]
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (ID => 1234)\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ID => 1234]
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (prename => {like => 'Vorname_1235'}, ID => 1234)\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [prename => {like => 'Vorname_1235'},
		   ID      => 1234
	 ]
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (birth => '1987-01-01')\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => [prename => 'birth'],
	 from  => 'person',
	 where => [ IS => [birth => '1987-01-01']]
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

auto_report($result);

# --- select -------------------------------------------------------------

print "select (prename => 'Vorname_1234')\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ prename => 'Vorname_1234']
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (prename => {like => 'Vorname_1234'})\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [prename => {like => 'Vorname_1234'}]
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- grep -------------------------------------------------------------

print "grep { \$_->{prename} =~ /Vorname_1234/ }\n";

$start_time = gettimeofday();

my $table = $cache->get_table_cache('person');

my @result_arr = grep {
    $_->{prename} =~ /Vorname_1234/
} @$table;

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @result_arr).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (prename => 'Vorname_1234', surname => 'Nachname_1234')\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ prename => 'Vorname_1234',
		    surname => 'Nachname_1234']
 );

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (obj => sub { \$_->{prename} eq 'Vorname_1234' && \$_->{surname} eq 'Nachname_1234' })\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [obj => sub {
	     $_->{prename} eq 'Vorname_1234'
		 && $_->{surname} eq 'Nachname_1234'
		 }]
	);

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- select -------------------------------------------------------------

print "select (obj => sub { \$_->get_prename() eq 'Vorname_1234' && \$_->get_surname() eq 'Nachname_1234' })\n";

$start_time = gettimeofday();

$result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [obj => sub {
	     $_->get_prename() eq 'Vorname_1234'
		 && $_->get_surname() eq 'Nachname_1234'
		 }]
	);

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @$result).", duration = $duration\n";

# --- grep -------------------------------------------------------------

print "grep { \$_->{prename} eq 'Vorname_1234' && \$_->{surname} eq 'Nachname_1234' }\n";

$start_time = gettimeofday();

$table = $cache->get_table_cache('person');

@result_arr = grep {
    $_->{prename} eq 'Vorname_1234'
	&& $_->{surname} eq 'Nachname_1234'
} @$table;

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @result_arr).", duration = $duration\n";

# --- grep -------------------------------------------------------------

print "grep { \$_->{prename} =~ /Vorname_12.4/ && \$_->{surname} =~ /Nachname_123./ }\n";

$start_time = gettimeofday();

$table = $cache->get_table_cache('person');

@result_arr = grep {
    $_->{prename} =~ /Vorname_12.4/ 
	&& $_->{surname} =~ /Nachname_123./
} @$table;

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @result_arr).", duration = $duration\n";

# --- grep -------------------------------------------------------------

print "grep { \$_->get_prename() eq 'Vorname_1234' && \$_->get_surname() eq 'Nachname_1234' }\n";

$start_time = gettimeofday();

$table = $cache->get_table_cache('person');

@result_arr = grep {
    $_->get_prename() eq 'Vorname_1234'
	&& $_->get_surname() eq 'Nachname_1234'
} @$table;

$duration = gettimeofday() - $start_time;

print "ready, count ".(scalar @result_arr).", duration = $duration\n";

