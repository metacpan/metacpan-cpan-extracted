# $Id: Summary.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::Summary;

use base 'Test::C2FIT::Fixture';
use strict;

use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;

my $countsKey = "counts";

sub doTable {
    my $self = shift;
    my ($table) = @_;
    $Test::C2FIT::Fixture::summary{$countsKey} = $self->counts()->toString();
    my @keys = sort keys %Test::C2FIT::Fixture::summary;
    $table->parts()->more( $self->rows(@keys) );
}

sub rows {
    my $self = shift;
    my (@keys) = @_;

    return undef if 0 == @keys;
    my $key = shift @keys;

    my $result = $self->Tr(
        $self->Td(
            $key, $self->Td( $Test::C2FIT::Fixture::summary{$key}, undef )
        ),
        $self->rows(@keys)
    );
    $self->mark($result) if $key eq $countsKey;
    return $result;
}

sub Tr {
    my ( $self, $parts, $more ) = @_;
    return Test::C2FIT::Parse->from( "tr", undef, $parts, $more );
}

sub Td {
    my ( $self, $body, $more ) = @_;
    return Test::C2FIT::Parse->from( "td", $self->info($body), undef, $more );
}

sub mark {
    my $self = shift;
    my ($cell) = @_;

    my $official = $self->counts();
    $self->counts( Test::C2FIT::Counts->new() );
    if ( $official->{'wrong'} + $official->{'exceptions'} > 0 ) {
        $self->wrong($cell);
    }
    else {
        $self->right($cell);
    }
    $self->counts($official);
}

1;

__END__

package fit;

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

import java.util.*;

public class Summary extends Fixture {
    public static String countsKey = "counts";

    public void doTable(Parse table) {
        summary.put(countsKey, counts());
        SortedSet keys = new TreeSet(summary.keySet());
        table.parts.more = rows(keys.iterator());
    }

    protected Parse rows(Iterator keys) {
        if (keys.hasNext()) {
            Object key = keys.next();
            Parse result =
                tr(
                    td(key.toString(),
                    td(summary.get(key).toString(),
                    null)),
                rows(keys));
            if (key.equals(countsKey)) {
                mark (result);
            }
            return result;
        } else {
            return null;
        }
    }

    protected Parse tr(Parse parts, Parse more) {
        return new Parse ("tr", null, parts, more);
    }

    protected Parse td(String body, Parse more) {
        return new Parse ("td", info(body), null, more);
    }

    protected void mark(Parse row) {
        // mark summary good/bad without counting beyond here
        Counts official = counts;
        counts = new Counts();
        Parse cell = row.parts.more;
        if (official.wrong + official.exceptions > 0) {
            wrong(cell);
        } else {
            right(cell);
        }
        counts = official;
    }

}

