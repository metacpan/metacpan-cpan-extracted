use strict;
use Test::More tests => 4;
use Test::Deep;

BEGIN { use_ok( 'Parallel::SubArray', 'par' ); }

my $sub_arrayref = [
		    sub{ sleep(1); [1]  },
		    sub{ bless {}, 'a'  },
		    sub{ while(1){$_++} },
		    sub{ die 'TEST'     },
                    sub{ par()->([
				  sub{ sleep(1);  [1]  },
				  sub{ sleep(2); {2,3} },
				 ])
		       },
		   ];

my $par_coderef = par(3);

my $result_arrayref = $par_coderef->($sub_arrayref);

cmp_deeply( $result_arrayref,
	    [ [1],
	      bless({}, 'a'),
	      undef,
	      undef,
	      [ [1], {2,3} ],
	    ],
	    'Results, scalar context'
	  );

my $error_arrayref;
( $result_arrayref, $error_arrayref ) = $par_coderef->($sub_arrayref);

cmp_deeply( $result_arrayref,
	    [ [1],
	      bless({}, 'a'),
	      undef,
	      undef,
	      [ [1], {2,3} ],
	    ],
	    'Results, list context'
	  );

cmp_deeply( $error_arrayref,
	    [ undef,
	      undef,
	      'TIMEOUT',
	      "TEST at t/01.par.t line 11.\n",
	      undef,
	    ],
	    'Errors good'
	  );
