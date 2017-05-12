# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::DocumentParseFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Test::C2FIT::Parse;

#sub new {
#    my $pkg = shift;
#    return bless { }, $pkg;
#}

sub Output {
    my $self = shift;
    return $self->GenerateOutput( new Test::C2FIT::Parse( $self->{'HTML'} ) );
}

sub HTML {
    my $self = shift;
    $self->{'HTML'} = shift;
}

sub Structure {
    my $self = shift;

    my $structure =
      $self->dumpTables( new Test::C2FIT::Parse( $self->{'HTML'} ) );
    return $structure;
}

sub GenerateOutput {
    my $self  = shift;
    my $parse = shift;
    return $parse->asString();
}

sub dumpTables {
    my $self      = shift;
    my $table     = shift;
    my $result    = '';
    my $separator = '';
    while ($table) {
        $result .= $separator;
        $result .= $self->dumpRows( $table->parts() );
        $separator = "\n----\n";
        $table     = $table->more();
    }
    return $result;
}

sub dumpRows {
    my $self      = shift;
    my $row       = shift;
    my $result    = '';
    my $separator = '';
    while ($row) {
        $result .= $separator;
        $result .= $self->dumpCells( $row->parts() );
        $separator = "\n";
        $row       = $row->more;
    }
    return $result;
}

sub dumpCells {
    my $self      = shift;
    my $cell      = shift;
    my $result    = '';
    my $separator = '';
    while ($cell) {
        $result .= $separator;
        $result .= "[" . $cell->body() . "]";
        $separator = " ";
        $cell      = $cell->more();
    }
    return $result;
}

1;

__END__

package fat;

import fit.*;
import java.text.*;
import java.io.*;

public class DocumentParseFixture extends ColumnFixture {
	public String HTML;
	public String Note;  // non-functional
	
	public String Output() throws ParseException {
		return GenerateOutput(new Parse(HTML));
	}

	public String Structure() throws ParseException {
		return dumpTables(new Parse(HTML));		
	}
	
	private String GenerateOutput(Parse parse) {
		StringWriter result = new StringWriter();
		parse.print(new PrintWriter(result));
		return result.toString();
	}
		
	private String dumpTables(Parse table) {
		String result = "";
		String separator = "";
		while (table != null) {
			result += separator;
			result += dumpRows(table.parts);
			separator = "\n----\n";
			table = table.more;
		}
		return result;
	}
	
	private String dumpRows(Parse row) {
		String result = "";
		String separator = "";
		while (row != null) {
			result += separator;
			result += dumpCells(row.parts);
			separator = "\n";
			row = row.more;
		}
		return result;
	}
	
	private String dumpCells(Parse cell) {
		String result = "";
		String separator = "";
		while (cell != null) {
			result += separator;
			result += "[" + cell.body + "]";
			separator = " ";
			cell = cell.more;
		}
		return result;
	}
}
