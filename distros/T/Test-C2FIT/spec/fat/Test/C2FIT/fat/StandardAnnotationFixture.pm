# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::StandardAnnotationFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Error qw( :try );
use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{'OriginalHTML'} = 'Text';
    return $self;

}

sub Output {
    my $self = shift;

    my $parse = new Test::C2FIT::Parse( $self->{'OriginalHTML'}, ['td'] );
    my $testbed = new Test::C2FIT::Fixture();
    $testbed->right($parse) if $self->{'Annotation'} eq "right";
    $testbed->wrong( $parse, $self->{'Text'} )
      if $self->{'Annotation'} eq "wrong";
    $testbed->error( $parse, $self->{'Text'} )
      if $self->{'Annotation'} eq "error";
    $testbed->info( $parse, $self->{'Text'} )
      if $self->{'Annotation'} eq "info";
    $testbed->ignore($parse) if $self->{'Annotation'} eq "ignore";

    return $self->GenerateOutput($parse);

}

sub doCell {
    my $self = shift;
    my ( $cell, $column ) = @_;

    try {
        if ( $column == 4 ) {
            $cell->{'body'} = $self->RenderedOutput();
        }
        else {
            $self->SUPER::doCell( $cell, $column );
        }
      }
      otherwise {
        my $e = shift;
        $self->exception( $cell, $e );
      };
}

sub RenderedOutput {
    my $self = shift;
    return '<table border="1"><tr>' . $self->Output() . '</tr></table>';
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

public class StandardAnnotationFixture extends ColumnFixture {
	public String OriginalHTML = "Text";
	public String Annotation;
	public String Text;
	
	public String Output() throws ParseException {
		Parse parse = new Parse(OriginalHTML, new String[] {"td"});
		Fixture testbed = new Fixture();
		
		if (Annotation.equals("right")) testbed.right(parse);
		if (Annotation.equals("wrong")) testbed.wrong(parse, Text);
		if (Annotation.equals("error")) testbed.error(parse, Text);
		if (Annotation.equals("info")) testbed.info(parse, Text); 
		if (Annotation.equals("ignore")) testbed.ignore(parse);
				
		return GenerateOutput(parse); 
	}
	
	public void doCell(Parse cell, int column) {
		try {
			if (column == 4) {
				cell.body = RenderedOutput();
			}
			else {
				super.doCell(cell, column);
			}
		}
		catch (Exception e) {
			exception(cell, e);
		}	
	}
	
	public String RenderedOutput() throws ParseException {
		return "<table border='1'><tr>" + Output() + "</tr></table>";
	}
	
	// code smell note: copied from ParseFixture	
	private String GenerateOutput(Parse parse) {
		StringWriter result = new StringWriter();
		parse.print(new PrintWriter(result));
		return result.toString().trim();
	}
}
