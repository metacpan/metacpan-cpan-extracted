# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::HtmlToTextFixture;
use base 'Test::C2FIT::ColumnFixture';

use Test::C2FIT::Parse;

use strict;

sub Text {
    my $self = shift;

    my $html = $self->{'HTML'};
    $html =~ s/\\u00a0/\x{00a0}/g;
    return $self->escapeAscii( Test::C2FIT::Parse->htmlToText($html) );
}

sub escapeAscii {
    my $self = shift;
    my $text = shift;
    my $NBSP = "\x{00a0}";
    $text =~ s/\n/\\n/g;
    $text =~ s/\r/\\r/g;
    $text =~ s/$NBSP/\\u00a0/g;
    return $text;
}

1;

__END__

package fat;

import fit.*;

public class HtmlToTextFixture extends ColumnFixture {
        public String HTML;

        public String Text() {
                HTML = HTML.replaceAll("\\\\u00a0", "\u00a0");
                return escapeAscii(Parse.htmlToText(HTML));
        }

        private String escapeAscii(String text) {
                text = text.replaceAll("\\x0a", "\\\\n");
                text = text.replaceAll("\\x0d", "\\\\r");
                text = text.replaceAll("\\xa0", "\\\\u00a0");
                return text;
        }
}
