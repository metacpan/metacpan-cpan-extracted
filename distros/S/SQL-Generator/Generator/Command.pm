# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

1;

__END__

=head1 NAME

SQL::Generator::Command - base class for a pseudo bnf's implementation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 Method C<validate( $href_args )>

validate correct types and all required fields for existance.

=cut

=head1 Method B<totext>

=cut

=head1 EXAMPLE

	my $sqlgen = new SQL::Generator( debug => 0 );

	printf "%s\n\n", $sqlgen->CREATE(

		COLS => [ 'col1 VARCHAR', 'col2 INTEGER', 'col3 BLOB' ],

		TABLE => 'mytable',

		);

	my $sqltext = $sqlgen->INSERT(

		COLS => [ qw/ col1 col2 col3 / ], VALUES => [ qw/ 1 2 3 / ],

		INTO => 'mytable',

		WHERE => 'col1 = 99 AND col3 = 99'

		);

	my %cols = ( 'id' => '0', 'created' => 'NOW()',	'data' => '?' );

	my $sqltext = $sqlgen->INSERT( COLS => [keys %cols], VALUES => [values %cols], INTO => 'article' );

	my $sqltext = $sqlgen->SELECT(

		COLS => [ qw/ col1 col2 col3 / ], FROM => 'mytable',

		WHERE => 'col1 = 12 AND col3 = 1'

		);

=head1 CLASS METHODS

finally following strings are constructed:

	sprintf( "USE %s" );
	sprintf( "SELECT * FROM $table WHERE id = %d", $id );
	sprintf( 'INSERT INTO %s (%s) VALUES (%s)', $args{'table'}, $nam, $val );
	sprintf( "DROP TABLE $table" );
	sprintf( "CREATE TABLE $table ( col ROWTYPE, col ROWTYPE )" );
	sprintf( "UPDATE $table SET %s WHERE id = %d",  join( ', ', @sql_cols ), $this->get('id') );

=head2 VERSION

Module Version 0.04

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, muenalan@cpan.org

=head1 COPYRIGHT

    Copyright (c) 1998-2002 Murat Uenalan. Germany. All rights reserved.

    You may distribute under the terms of either the GNU General Public
    License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

perl(1), DBI, DBD::*

=cut
