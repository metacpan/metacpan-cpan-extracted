{
	package Local::Test::Syntax;
	BEGIN {
		sub IMPORT {
			no strict 'refs';
			my $caller = caller;
			*{"$caller\::uc"} = sub ($) { lc $_[0] };
			*{"$caller\::maybe"} = sub {
				return @_ if defined $_[0] && defined $_[1];
				shift; shift; return @_;
			};
		}
	}
	use Syntax::Collector -collect => q/
		use strict 0;
		use warnings 0 FATAL => 'all';
		use Scalar::Util 0 qw(blessed);
	/;
}

{
	package Local::Test;
	
	use strict;
	no warnings;
	use Test::More tests => 6;
	use Test::Requires 'Scalar::Util';
	use Test::Fatal;
	
	use Local::Test::Syntax;
	
	sub go
	{
		is(
			uc('Hello World'),
			'hello world',
			'sub IMPORT',
		);
		
		like(
			exception { print(my $x = undef) },
			qr{uninitialized},
			'use warnings',
		);
		
		ok(
			!exception { maybe(1,2) },
			'sub maybe',
		);
		
		ok(
			!exception { ok blessed( bless +{} ) },
			'sub blessed',
		);
		
		is_deeply(
			[ sort Local::Test::Syntax->modules ],
			[ sort qw/strict warnings Scalar::Util/ ],
			'sub modules',
		);
	}
}

Local::Test->go;
