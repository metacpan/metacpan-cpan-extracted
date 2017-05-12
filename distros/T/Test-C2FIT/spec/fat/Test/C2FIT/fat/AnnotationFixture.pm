# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::AnnotationFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Test::C2FIT::Parse;

sub ResultingHTML {
    my $self = shift;

    $self->{'Row'}    = 0 unless $self->{'Row'};
    $self->{'Column'} = 0 unless $self->{'Column'};

    my $table = new Test::C2FIT::Parse( $self->{'OriginalHTML'} );
    my $row   = $table->at( 0, $self->{'Row'} - 1 );
    my $cell  = $row->at( 0, $self->{'Column'} - 1 );

    $cell->{'body'} = $self->{'OverwriteCellBody'}
      if $self->{'OverwriteCellBody'};
    $cell->addToBody( $self->{'AddToCellBody'} ) if $self->{'AddToCellBody'};
    $cell->{'tag'} = $self->{'OverwriteCellTag'} if $self->{'OverwriteCellTag'};
    $cell->{'end'} = $self->{'OverwriteEndCellTag'}
      if $self->{'OverwriteEndCellTag'};
    $cell->addToTag( $self->stripDelimiters( $self->{'AddToCellTag'} ) )
      if $self->{'AddToCellTag'};

    $row->{'tag'} = $self->{'OverwriteRowTag'} if $self->{'OverwriteRowTag'};
    $row->{'end'} = $self->{'OverwriteEndRowTag'}
      if $self->{'OverwriteEndRowTag'};
    $row->addToTag( $self->stripDelimiters( $self->{'AddToRowTag'} ) )
      if $self->{'AddToRowTag'};

    $table->{'tag'} = $self->{'OverwriteTableTag'}
      if $self->{'OverwriteTableTag'};
    $table->{'end'} = $self->{'OverwriteEndTableTag'}
      if $self->{'OverwriteEndTableTag'};
    $table->addToTag( $self->stripDelimiters( $self->{'AddToTableTag'} ) )
      if $self->{'AddToTableTag'};

    $self->addParse( $cell, $self->{'AddCellFollowing'}, ['td'] )
      if $self->{'AddCellFollowing'};
    $self->removeParse($cell) if $self->{'RemoveFollowingCell'};

    $self->addParse( $row, $self->{'AddRowFollowing'}, [ 'tr', 'td' ] )
      if $self->{'AddRowFollowing'};
    $self->removeParse($row) if $self->{'RemoveFollowingRow'};

    $self->addParse(
        $table,
        $self->{'AddTableFollowing'},
        [ 'table', 'tr', 'td' ]
      )
      if $self->{'AddTableFollowing'};

    return $self->GenerateOutput($table);
}

sub addParse {
    my $self = shift;
    my ( $parse, $newString, $tags ) = @_;
    my $newParse = new Test::C2FIT::Parse( $newString, $tags );
    $newParse->{'more'}    = $parse->more();
    $newParse->{'trailer'} = $parse->trailer();
    $parse->{'more'}       = $newParse;
    $parse->{'trailer'}    = undef;
}

sub removeParse {
    my $self  = shift;
    my $parse = shift;
    $parse->{'trailer'} = $parse->more()->trailer();
    $parse->{'more'}    = $parse->more()->more();
}

sub stripDelimiters {
    my $self = shift;
    my $s    = shift;
    $s =~ s/^\[//g;
    $s =~ s/]$//g;
    return $s;
}

# code smell note: copied from DocumentParseFixture
sub GenerateOutput {
    my $self  = shift;
    my $parse = shift;
    return $parse->asString();
}

1;

__END__

package fat;

import fit.*;
import java.io.*;
import java.text.ParseException;

public class AnnotationFixture extends ColumnFixture {
	public String OriginalHTML;
	public int Row;
	public int Column;
	
	public String OverwriteCellBody;
	public String AddToCellBody;
	
	public String OverwriteCellTag;
	public String OverwriteEndCellTag;
	public String AddToCellTag;
	
	public String OverwriteRowTag;
	public String OverwriteEndRowTag;
	public String AddToRowTag;

	public String OverwriteTableTag;
	public String OverwriteEndTableTag;
	public String AddToTableTag;
	
	public String AddCellFollowing;
	public String RemoveFollowingCell;
	
	public String AddRowFollowing;
	public String RemoveFollowingRow;
	
	public String AddTableFollowing;

	public String ResultingHTML() throws Exception {
		Parse table = new Parse(OriginalHTML);
		Parse row = table.at(0, Row - 1);
		Parse cell = row.at(0, Column - 1);
		
		if (OverwriteCellBody != null) cell.body = OverwriteCellBody;
		if (AddToCellBody != null) cell.addToBody(AddToCellBody);
		
        if (OverwriteCellTag != null) cell.tag = OverwriteCellTag;
        if (OverwriteEndCellTag != null) cell.end = OverwriteEndCellTag;
        if (AddToCellTag != null) cell.addToTag(stripDelimiters(AddToCellTag));
        
        if (OverwriteRowTag != null) row.tag = OverwriteRowTag;
        if (OverwriteEndRowTag != null) row.end = OverwriteEndRowTag;
        if (AddToRowTag != null) row.addToTag(stripDelimiters(AddToRowTag));

		if (OverwriteTableTag != null) table.tag = OverwriteTableTag;
		if (OverwriteEndTableTag != null) table.end = OverwriteEndTableTag;
		if (AddToTableTag != null) table.addToTag(stripDelimiters(AddToTableTag));

		if (AddCellFollowing != null) addParse(cell, AddCellFollowing, new String[] {"td"});
		if (RemoveFollowingCell != null) removeParse(cell);
				
		if (AddRowFollowing != null) addParse(row, AddRowFollowing, new String[] {"tr", "td"});
		if (RemoveFollowingRow != null) removeParse(row);
		
		if (AddTableFollowing != null) addParse(table, AddTableFollowing, new String[] {"table", "tr", "td"});

		return GenerateOutput(table);        
	}

    private void addParse(Parse parse, String newString, String[] tags) throws ParseException {
        Parse newParse = new Parse(newString, tags);
        newParse.more = parse.more;
        newParse.trailer = parse.trailer;
        parse.more = newParse;
        parse.trailer = null;
    }

	private void removeParse(Parse parse) {
		parse.trailer = parse.more.trailer;
		parse.more = parse.more.more;
	}
	
	private String stripDelimiters(String s) {
        return s.replaceAll("^\\[", "").replaceAll("]$", "");
    }
	
	// code smell note: copied from DocumentParseFixture	
	private String GenerateOutput(Parse document) throws ParseException {
		StringWriter result = new StringWriter();
		document.print(new PrintWriter(result));
		return result.toString().trim();
	}
}
