# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::fat::TableParseFixture;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Test::C2FIT::Parse;

sub CellBody {
    my $self = shift;
    return $self->cell()->body();
}

sub CellTag {
    my $self = shift;
    return $self->cell()->tag();
}

sub RowTag {
    my $self = shift;
    return $self->row()->tag();
}

sub TableTag {
    my $self = shift;
    return $self->table()->tag();
}

sub table {
    my $self = shift;
    return new Test::C2FIT::Parse( $self->{'HTML'} );
}

sub row {
    my $self = shift;
    return $self->table()->at( 0, $self->{'Row'} - 1 );
}

sub cell {
    my $self = shift;
    return $self->row()->at( 0, $self->{'Column'} - 1 );
}

1;

__END__

package fat;

import fit.*;

public class TableParseFixture extends ColumnFixture {

        public String HTML;
        public int Row;
        public int Column;

        public String CellBody() throws Exception {
                return cell().body;
        }

        public String CellTag() throws Exception {
                return cell().tag;
        }

        public String RowTag() throws Exception {
                return row().tag;
        }

        public String TableTag() throws Exception {
                return table().tag;
        }

        private Parse table() throws Exception {
                return new Parse(HTML);
        }

        private Parse row() throws Exception {
                return table().at(0, Row - 1);
        }

        private Parse cell() throws Exception {
                return row().at(0, Column - 1);
        }
}

