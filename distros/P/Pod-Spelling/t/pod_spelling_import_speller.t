use strict;
use warnings;

use Test::More;
use lib 'lib';

BEGIN {
	eval { require Lingua::Ispell };
	if ($@){
		eval { 
			require Text::Aspell;
			my $o = Text::Aspell->new;
			$o->check('house');
			die $o->errstr if $o->errstr;
		};
	}
	if ($@){
		plan skip_all => 'requires Lingua::Ispell or Text::Aspell' ; 
	}
}


BEGIN {
	use_ok('Pod::Spelling');
}


foreach my $pm (qw(
	Lingua::Ispell
	Text::Aspell
)){
	
	eval $pm;

	my ($mod) = $pm =~ /(\w+)$/;
	my $class = 'Pod::Spelling::'.$mod;
	
	eval "require $class";
	
	SKIP: {
		skip 'Cannot require '.$class, 7 if $@;

		my $o = eval {
			Pod::Spelling->new(  import_speller => $class  );
		};
		
		SKIP: {
			skip $o, 3 if not ref $o;
			isa_ok( $o, 'Pod::Spelling');

			is(
				$o->{spell_check_callback},
				$class.'::_spell_check_callback',
				'callback package for '.$class
			);

			TODO: {
				require Data::Dumper;
				local $TODO = 'pending' if $o->{aspell};
				is(
					$o->check_file( 't/good.pod' ),
					0,
					'One expected error'
				) or warn Data::Dumper::Dumper $o;
			}
		}
	}
}

done_testing( );




