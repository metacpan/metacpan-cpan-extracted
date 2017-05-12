use Pg::Loader::Query;
use Test::More qw( no_plan );
use DBD::Mock;
use Test::Exception;


*enable_indexes = \& Pg::Loader::Query::enable_indexes;

my $dh   = DBI->connect('dbi:Mock:a');
$dh->{AutoCommit} = 1;

ok $dh;

my $defs = [ { name=>'n_pkey', pk=>1, def=>'alter table e add primary key(c)',
             }, 
             { name=>'bb'    , pk=>0, def=>'create index bb on exam(fn,ln)',
             }, 
];
my $session = new DBD::Mock::Session
                { statement => 'ALTER TABLE exam add PRIMARY KEY (c)',
	          results=> [],
                },
                { statement => 'create index bb on exam(fn,ln)', 
	          results=> [],
                },
;

ok $dh->{AutoCommit} ;
$dh->{mock_session} = $session;

lives_ok { enable_indexes($dh, 'public.exam', $defs)};

ok $dh->{AutoCommit} ;

