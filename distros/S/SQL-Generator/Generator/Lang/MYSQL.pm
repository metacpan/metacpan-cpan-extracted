# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

our $VERSION = '0.01';

require 5.005_62;

use strict;

use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

package SQL::Generator::Lang::MYSQL;

Class::Maker::class
{
	isa => [qw( Object::ObjectList )],

	attribute =>
	{
		getset => [qw(name version)],
	},
};

sub _preinit
{
	my $this = shift;

			# append/overwrite constructor argument

		$this->name( 'MYSQL' );

		$this->version( '3.22.30' );
}

sub _postinit
{
	my $this = shift;

	my $type = 'SQL::Generator::Command';

	$this->push( $type->new(

		id => 'SELECT',

		template => [ qw/ROWS FROM WHERE GROUP ORDER LIMIT WITH AS/ ],

		required => [ qw/ROWS FROM/ ],

		arguments =>
		{
			ROWS => { argtypes => { ALL => 1 }, hash_assigner => ' AS ', replace => 1 },

			AS => { argtypes => { ALL => 1 },  param_printf => '( %s )' },
		}
	));

	$this->push( $type->new(

		id => 'INSERT',

		template => [ qw/INTO COLS VALUES SET WHERE/ ],

		arguments =>
		{
			COLS => { argtypes => { ARRAY => 1 }, token => '', param_printf => '( %s )' } ,

			VALUES => { argtypes => { ARRAY => 1 },  param_printf => '( %s )' },

			SET => { argtypes => { HASH => 1 }, hash_assigner => '=' },
		}
	));

	$this->push( $type->new(

		id => 'REPLACE',

		template => [ qw/INTO COLS VALUES SET/ ],

		required => [ qw/INTO COLS/ ],

		arguments =>
		{
			COLS => { argtypes => { ARRAY => 1 }, token => '', param_printf => '( %s )' } ,

			VALUES => { argtypes => { ARRAY => 1 }, param_printf => '( %s )' },

			SET => { argtypes => { HASH => 1 }, hash_assigner => '=' },
		}
	));

	$this->push( $type->new(

		id => 'DELETE',

		template => [ qw/FROM WHERE LIMIT/ ],

		required => [ qw/FROM/ ],

		arguments => {}
	));

	$this->push( $type->new(

		id => 'UPDATE',

		template => [ qw/TABLE ROWS SET WHERE LIMIT/ ],

		required => [ qw/TABLE ROWS SET/ ],

		arguments =>
		{
			ROWS => {  argtypes => { ARRAY => 1 }, token => '' } ,
		}
	));

	# a "new SQL::Generator::Command" would do it too, but we want the generator
	# also know the COLS( COLUMNS => ,PRIMARYKEY =>, ... )

	$this->push( my $cols = $type->new(

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
	));

	$this->push( $type->new(

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
	));

	$this->push( $type->new(

		id => 'ALTER',

		template => [ qw/TABLE/ ],

		required => [ qw/TABLE/ ],

		arguments => {}
	));

	$this->push( $type->new(

		id => 'DROP',

		template => [ qw/TABLE DATABASE/ ],

		arguments => {}
	));

	$this->push( $type->new(

		id => 'USE',

		template => [ qw/DATABASE/ ],

		required => [ qw/DATABASE/ ],

		arguments =>
		{
			DATABASE => { replace => 1 } ,
		}
	));

	$this->push( $type->new(

		id => 'SHOW',

		template => [ qw/TABLES DATABASES/ ],

		arguments => {}
	));

	$this->push( $type->new(

		id => 'DESCRIBE',

		template => [ qw/TABLE/ ],

		required => [ qw/TABLE/ ],

		arguments =>
		{
			TABLE => { replace => 1 },
		}
	));

	#printf "LOADED... %s from module.\n", $this->count;
}

1;
__END__

=head1 NAME

SQL::Generator::Lang::MYSQL - Perl extension for SQL::Generator

=head1 SYNOPSIS

use SQL::Generator;

=head1 DESCRIPTION

=head2 Constructor

=head2 Methods

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, mueanlan@cpan.org

=head1 COPYRIGHT

    Copyright (c) 1998-2002 Murat Uenalan. Germany. All rights reserved.

    You may distribute under the terms of either the GNU General Public
    License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

perl(1)

=cut
