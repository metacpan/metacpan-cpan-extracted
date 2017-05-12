BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

use SQL::Generator;

	eval
	{
		my $el = new SQL::Generator::Argument
		(
			token => 'FUNCTION', argtypes => { ARRAY => 1 },

			token_printf => '[%s]',	param_printf => '(%s)',

			pre => '<sql-statement>',

			post => '</sql-statement>',
		);

		$el->param( [ qw/eins zwei drei/ ] );

		printf "totext: %s\n", $el->totext();
	};

printf "ok %d\n", ++$loaded;
