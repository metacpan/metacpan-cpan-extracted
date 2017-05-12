use DBD::Mock;
use Pg::Loader::Query;
use Test::More qw( no_plan );
use Test::Exception;

*disable_indexes = \& Pg::Loader::Query::disable_indexes;

my $dh   = DBI->connect('dbi:Mock:a');

my $ans  = [ { name=>'n_pkey', pk=>1, def=>'alter table e add primary key(c)'}, 
             { name=>'bb'    , pk=>0, def=>'create index bb on exam(fn,ln)'  }, 
];
my $session = new DBD::Mock::Session 
	{ statement => qr/SELECT \s*  indexrel/xo, 
	  #bound_params => [ 'exam', 'public' ],
	  results      => [ [qw( name pk def )] ,
	                    [ 'n_pkey', 1, 'alter table e add primary key(c)'],
	                    [ 'bb'    , 0, 'create index bb on exam(fn,ln)'],
                          ],
	},
    { statement => 'ALTER table exam drop constraint n_pkey', 
	  results => [] 
    },
    { statement => 'DROP INDEX bb' ,
	  results => [] 
    },
;

$dh->{mock_session} = $session ;
is_deeply  disable_indexes( $dh, 'public.exam' ), $ans;

