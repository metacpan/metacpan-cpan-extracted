# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::FixtureNameFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Error qw( :try );
use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

sub FixtureName {
    my $self       = shift;
    my $tableParse = $self->GenerateTableParse( $self->{'Table'} );
    my $result     = $self->fixtureName($tableParse)->text();
    return "(missing)" if ( $result eq "" );
    return $result;
}

sub GenerateTableParse {
    my $self  = shift;
    my $table = shift;
    my @rows  = split( /\n/, $table );
    return Test::C2FIT::Parse->from( "table", undef,
        $self->GenerateRowParses( \@rows, 0 ), undef );
}

sub GenerateRowParses {
    my $self = shift;
    my ( $rows, $rowIndex ) = @_;
    return if ( $rowIndex >= scalar @$rows );
    my @cells = split( /\]\s*\[/, $rows->[$rowIndex] );
    if ( scalar @cells > 0 ) {
        $cells[0] =~ s/^\[//g;
        my $lastCell = ( scalar @cells ) - 1;
        $cells[$lastCell] =~ s/\]$//g;

    }

    return Test::C2FIT::Parse->from(
        "tr", undef,
        $self->GenerateCellParses( \@cells, 0 ),
        $self->GenerateRowParses( $rows, $rowIndex + 1 )
    );
}

sub GenerateCellParses {
    my $self = shift;
    my ( $cells, $cellIndex ) = @_;
    return if ( $cellIndex >= scalar @$cells );
    return Test::C2FIT::Parse->from( "td", $cells->[$cellIndex], undef,
        $self->GenerateCellParses( $cells, $cellIndex + 1 ) );

}

1;

__END__

package fat;

import java.text.ParseException;
import fit.*;

public class FixtureNameFixture extends ColumnFixture {
	public String Table;
	
	public String FixtureName() throws Exception {
		Parse tableParse = GenerateTableParse(Table);
		
		String result = fixtureName(tableParse).text();
		if (result.equals("")) return "(missing)";
		return result;
	}
	
	private Parse GenerateTableParse(String table) throws ParseException {
		String[] rows = table.split("\n");
		return new Parse("table", null, GenerateRowParses(rows, 0), null);
	}

	private Parse GenerateRowParses(String[] rows, int rowIndex) {
		if (rowIndex >= rows.length) return null;
		
		String[] cells = rows[rowIndex].split("\\]\\s*\\[");
		if (cells.length != 0) {
			cells[0] = cells[0].substring(1); // strip beginning '['
			int lastCell = cells.length - 1;
			cells[lastCell] = cells[lastCell].replaceAll("\\]$", "");  // strip ending ']' 
		}
		
		return new Parse("tr", null, GenerateCellParses(cells, 0), GenerateRowParses(rows, rowIndex+1));
	}		

	private Parse GenerateCellParses(String[] cells, int cellIndex) {
		if (cellIndex >= cells.length) return null;
		
		return new Parse("td", cells[cellIndex], null, GenerateCellParses(cells, cellIndex + 1));
	}
}
