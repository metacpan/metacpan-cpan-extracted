# perl
#
# Test of PQL::Cache
#
# Sun Dec 21 14:05:18 2014

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 41;
use Test::Exception;

use PQL::Cache;

# ==============================================================================

my $cache = PQL::Cache->new();

is (ref($cache), "PQL::Cache", "PQL::Cache->new");

# ==============================================================================

is ($cache->set_table_definition
        ('person',
         {
                 keys    => ['ID'],
                 columns => [prename => surname => birth => gender => 'perl_level']
         }),
        person => "set_table_definition(person)");

is ($cache->set_table_definition
        ('location',
         {
                 keys    => ['ID'],
                 columns => [country => state => city => street => 'number']
         }),
        location => "set_table_definition(location)");

my $person_id = 1;

# --- Persons -------------------------------------------------------------

is ($cache->insert(person => {
        ID       => $person_id++,
        prename  => 'Ralf',
        surname  => 'Peine',
        gender   => 'male',
        birth    => '1965-12-29',
        location => 1,             # cannot be searched!
        perl_level => 'CPAN',
}),
        1, "insert 1st person");

is ($cache->insert(person => {
        ID      => $person_id++,
        prename => 'Larry',
        surname => 'Wall',
        gender  => 'male',
        birth   => '1954-09-27',
        perl_level => 'founder',
}),
        2, "insert 2nd person");


is ($cache->insert(person => {
        ID      => $person_id++,
        prename => 'Damian',
        surname => 'Conway',
        gender  => 'male',
        birth   => '1964-10-05',
        perl_level => 'founder Perl6',
}),
        3, "insert 3rd person");


is ($cache->insert(person => {
        ID      => $person_id++,
        prename => 'Audrey',
        surname => 'Tang',
        gender  => 'female',
        birth   => '1981-04-18',
        perl_level => 'guru',
}),
        4, "insert 4th person");

# --- locations -------------------------------------------------------------

my $location_id = 1;

is ($cache->insert(location => {
        ID      => $location_id++,
        country => 'Germany',
        state   => 'NRW',
        city    => 'Bochum',
        street  => 'Rechener Str.',
        number  => 9 
}),
        1, "insert 1st location");


my $result;

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         # no where
 );

is (scalar (@$result), 4, "select all values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ ID => 2]   # AND as default, IS for scalar value in 2. arg
 );

is (scalar (@$result), 1, "[ID => 2] => 1 value");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ prename => 'Ralf'] # AND as default, IS for scalar value in 2. arg
 );

is (scalar (@$result), 1, "[prename => 'Ralf'] => 1 value");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ perl_level => 'beginner']
 );

is (scalar (@$result), 0, "IS   => [perl_level => 'beginner'] => 0 values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ perl_level => { like => 'founder.*' }
                   ]
 );

# --- Test --- validation ---------------------------------------------------------
is (scalar (@$result), 2, "perl_level => { like => 'founder.*' }");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ perl_level => { like => 'founder$' }
	 ]
 );

is (scalar (@$result), 1, 'perl_level => { like => "founder$" }');

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ prename => [ qw (Larry Damian Audrey)]
                        ]
 );

is (scalar (@$result), 3, "prename => [ qw (Larry Damian Audrey)] => 3 values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ gender  => 'male',
                    surname => { like => '.a.'}
                        ]
 );

is (scalar (@$result), 2, "IS + LIKE: => 2 values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => [qw (prename surname)],
         from  => 'person',
         where => [ gender => 'male',
                   ]
 );

# --- Test --- validation ---------------------------------------------------------
is (scalar (@$result), 3, "what => [qw (prename surname)] => 3 values");

my $pin = $result->[0];
is (scalar (keys (%$pin)), 2, "what: count columns = 2");
is ($pin->{prename}, 'Ralf',  'what: validate     [0]->{prename}');
is ($pin->{surname}, 'Peine', 'what: validate     [0]->{surname}');
ok (! exists $pin->{ID},      'what: not existing [0]->{ID}');

TODO:
{
    local $TODO = "or is currently not implemented";
# --- Test --- run ---------------------------------------------------------
        $result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ or => [ 'surname' => 'Wall',
                            'surname' => 'Conway',
                    ]],
        );
    
    is (scalar (@$result), 2, "or: select 2 values");
}

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth      => { like => '^196' },
                    perl_level => { like => 'founder'},
	 ]
 );

is (scalar (@$result), 1, "AND [LIKE + LIKE]: select 1 values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ obj => sub { $_->{birth} le '1960' }]
 );

is (scalar (@$result), 1, 'obj => sub { $_->{birth} <= "1960" }: select 1 values');

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth => {le => 1960} ]
 );

is (scalar (@$result), 1, 'birth => { le => 1960 } }: select 1 values');

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth => sub { $_ ge '1960' }]
 );

is (scalar (@$result), 3, 'birth => sub { $_ >= "1960" }: select 3 values');

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ data => sub { $_->{birth} ge '1960' }]
 );

is (scalar (@$result), 3, 'data => sub { $_->{birth} >= "1960" }: select 3 values by internal data hash');

TODO:
{
    local $TODO = "obj->method() is currently not possible: data are hashes";

# --- Test --- run ---------------------------------------------------------
    lives_and {
	$result = [];
	$result = $cache->select
	    (what  => 'all',
	     from  => 'person',
	     where => [ obj => sub { $_->get_birth() ge '1960' }]
	    );
    } 'obj => sub { $_->get_birth() >= "1960" } does not die';
    
    is (scalar (@$result), 3, 'obj => sub { $_->get_birth() >= "1960" }: select 3 values by object method');
}

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth => { ge => '1960' },
		    birth => { le => '1960' },
	 ]
 );

is (scalar (@$result), 0, "birth < and > '1960': select 0 values");

# --- Test --- run ---------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [obj => sub { $_->{birth} ge '1960' },
                   obj => sub { $_->{birth} le '1960' }]
 );

is (scalar (@$result), 0, "obj => sub { birth < and > '1960' }: select 0 values");

# ==== CRUD Test ============================================================

my $new_person = {
        ID       => $person_id++,
        prename  => 'Forrest',
        surname  => 'Gump',
        gender   => 'male',
        birth    => '1946-01-13',
        location => 4711,             # cannot be searched!
        perl_level => 'minimal',
};

# --- create ---------------------------------------------------------------

lives_ok {
        $cache->insert(person => $new_person);
} "CRUD: create";

# --- read -----------------------------------------------------------------
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [prename => 'Forrest']
 );

is (scalar @$result, 1, "CRUD: read: count == 1");

my $read_person = $result->[0];

is (''.$read_person, ''.$new_person, "CRUD: read: new and read are same hash object");

# --- update index ----------------------------------------------------------------

$read_person->{prename} = 'FORREST L.';

$cache->update_index('person'); #$read_person, );

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [prename => 'FORREST L.']
 );				# 

is (scalar @$result, 1, "CRUD: update index: count selected == 1");

my $update_person = $result->[0];

is ($update_person->{prename}, 'FORREST L.', "CRUD: update index: check prename changed");

# --- delete ----------------------------------------------------------------

# --- try read again ---------------------

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ID => $person_id - 1]
 );

is (scalar @$result, 1, "CRUD: delete: count read to delete by key == 1");

# --- count all before ---------------------

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
 );

my $count_before_delete = scalar @$result;

# ---- do delete --------------------

my $deleted_rows = $cache->delete
        (what  => 'all',
         from  => 'person',
         where => [prename => 'FORREST L.']
 );

is ($deleted_rows, 1, "CRUD: delete: count deleted rows == 1");

# --- try read again ---------------------

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [prename => 'FORREST L.']
 );

is (scalar @$result, 0, "CRUD: delete: count read deleted by column prename == 0");

# --- try read again ---------------------

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ID => $person_id - 1]
 );

is (scalar @$result, 0, "CRUD: delete: count read deleted by key ID == 0");

# --- count all afterwards ---------------------

$result = undef;
$result = $cache->select
        (what  => 'all',
         from  => 'person',
 );

is (scalar @$result, $count_before_delete - 1, "CRUD: delete: count all after delete == before - 1");

# ==== CRUD end ==========================================================================


