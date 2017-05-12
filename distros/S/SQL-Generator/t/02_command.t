BEGIN
{
	$| = 1; print "1..4\n";
}

my $loaded;

use strict;

use Carp;

use SQL::Generator;

print 'ok ', ++$loaded, "\n";

	my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

	my %types =
	(
		row1 => 'VARCHAR(10) NOT NULL AUTO_INCREMENT',

		row2 => 'INTEGER',

		row3 => 'VARCHAR(20)'
	);

	eval
	{
		my $cmd = new SQL::Generator::Command(

			id => 'REPLACE',

			template => [ qw/INTO COLS VALUES SET/ ],

			required => [ qw/INTO COLS/ ],

			arguments =>
			{
				COLS => { argtypes => { ARRAY => 1 }, token => '', param_printf => '( %s )' },

				VALUES => { argtypes => { ARRAY => 1 }, param_printf => '( %s )' },

				SET => { argtypes => { HASH => 1 }, hash_assigner => '=' },
			}
		);
			# provocate type error

		printf "totext: '%s'\n", $cmd->totext( {

				INTO => 'anytable',

				COLS => [ keys %columns ],

				VALUES => [ values %columns ],
		} );
	};

	if($@)
	{
        	croak $@;

        	print 'not ';
	}

print 'ok ', ++$loaded, "\n";

	my $cols = new SQL::Generator::Command(

		id => 'COLS',

		template => [ qw/COLS PRIMARYKEY INDEX KEY UNIQUE/ ],

		required => [ qw/COLS/ ],

		arguments =>
		{
			COLS => { argtypes => { ALL => 1 }, token => '', hash_assigner => ' ', hash_valueprintf => '%s' },

			PRIMARYKEY => { argtypes => { ARRAY => 1, SCALAR => 1 }, token => ', PRIMARY KEY', param_printf => '(%s)' },

			KEY => { argtypes => { ARRAY => 1 }, token => ', KEY', param_printf => '(%s)' },

			INDEX => { argtypes => { ARRAY => 1 }, token => ', INDEX', param_printf => '(%s)' },

			UNIQUE => { argtypes => { ARRAY => 1 }, token => ', UNIQUE', param_printf => '(%s)' },
		}
	);

	print $cols->totext( { COLS => \%types, PRIMARYKEY => 'row1', INDEX => [qw(row2)]  } ), "\n";

	my $parent = new SQL::Generator::Command(

		id => 'CREATE',

		template => [ qw/DATABASE TABLE COLS/ ],

		arguments =>
		{
			COLS => { argtypes => { SCALAR => 1 }, token => '', param_printf => '(%s)' },

			DATABASE => { argtypes => { SCALAR => 1 } },
		},

		subobjects =>
		{
			COLS => $cols,
		},
	);

	print $parent->totext( { TABLE => 'anytable', COLS => \%types } ), "\n";

	print $parent->totext( { TABLE => 'anytable', COLS => \%types, PRIMARYKEY => 'row1', INDEX => [qw(row2)]  } ), "\n";

	print $parent->totext( { TABLE => 'anytable', COLS => \%types } ), "\n";

print 'ok ', ++$loaded, "\n";

	eval
	{
		1;
	};

	if($@)
	{
        	croak $@;

        	print 'not ';
	}

print 'ok ', ++$loaded, "\n";
