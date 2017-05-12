# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::TextToHtmlFixture;
use base 'Test::C2FIT::ColumnFixture';

use Test::C2FIT::Fixture;

use strict;

sub HTML {
    my $self = shift;
    $self->{'Text'} = $self->unescapeAscii( $self->{'Text'} );
    return Test::C2FIT::Fixture->escape( $self->{'Text'} );
}

sub unescapeAscii {
    my $self = shift;
    my $text = shift;
    $text =~ s/\\n/\n/g;
    $text =~ s/\\r/\r/g;
    return $text;
}

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

public class TextToHtmlFixture extends ColumnFixture {
	public String Text;

	public String HTML() {
		Text = unescapeAscii(Text);
		return Fixture.escape(Text);
	}

	private String unescapeAscii(String text) {
		text = text.replaceAll("\\\\n", "\n");
		text = text.replaceAll("\\\\r", "\r");
		return text;
	}
	
	private String GenerateOutput(Parse parse) {
		StringWriter result = new StringWriter();
		parse.print(new PrintWriter(result));
		return result.toString();
	}
}
