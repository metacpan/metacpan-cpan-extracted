use Pg::Loader::Query;
use Test::More qw( no_plan );
use DBD::Mock;

* vacuum = \& Pg::Loader::Query::vacuum_analyze;

my $dh = DBI->connect( 'dbi:Mock:a'); 

ok $dh;

my $session = new DBD::Mock::Session 
		{ statement => qr/VACUUM ANALYZE public.exam/io, 
                  results=>[ ['rows'], [] ],
		},
		{ statement => qr/vacuum analyze public.ex/io, 
                  results=> undef,
		};
	
$dh->{mock_session} = $session;

ok   vacuum( $dh, 'public.exam' , 0  );
ok ! vacuum( $dh, 'public.ex'   , 0  );


open STDERR, '>>/dev/null';
