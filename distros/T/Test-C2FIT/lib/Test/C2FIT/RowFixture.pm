# $Id: RowFixture.pm,v 1.6 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::RowFixture;

use base qw(Test::C2FIT::ColumnFixture);

use strict;
use Test::C2FIT::TypeAdapter;
use Error qw( :try );

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new(
        results => [],
        missing => [],
        surplus => [],
        @_
    );
}

sub doRows {
    my $self = shift;
    my ($rows) = @_;
    try {
        $self->bind( $rows->parts() );
        $self->{'results'} = $self->query();
        $self->match( $self->rowsToArray( $rows->more() ),
            $self->{'results'}, 0 );
        my $last = $rows->last();
        $last->more( $self->buildRows( $self->{'surplus'} ) );
        $self->markRows( $last->more(), "surplus" );
        $self->markList( $self->{'missing'}, "missing" );
      }
      otherwise {
        my $e = shift;
        $self->exception( $rows->leaf(), $e );
      };
}

sub match {
    my $self = shift;
    my ( $expected, $computed, $col ) = @_;

    my $ncols = @{ $self->{'columnBindings'} };
    if ( $col >= $ncols ) {
        $self->checkLists( $expected, $computed );
    }
    elsif ( not defined( $self->{'columnBindings'}->[$col] ) ) {
        $self->match( $expected, $computed, $col + 1 );
    }
    else {
        my $eMap = $self->eSort( $expected,   $col );
        my $cMap = $self->cSort( $computed,   $col );
        my $keys = $self->union( keys %$eMap, keys %$cMap );
        foreach my $key (@$keys) {
            my $eList = $$eMap{$key};
            my $cList = $$cMap{$key};
            if ( !$eList ) {
                push @{ $self->{'surplus'} }, @$cList;
            }
            elsif ( !$cList ) {
                push @{ $self->{'missing'} }, @$eList;
            }
            elsif ( 1 == @$eList && 1 == @$cList ) {
                $self->checkLists( $eList, $cList );
            }
            else {
                $self->match( $eList, $cList, $col + 1 );
            }
        }
    }
}

sub rowsToArray {
    my $self    = shift;
    my ($rows)  = @_;
    my @results = ();
    while ($rows) {
        push @results, $rows;
        $rows = $rows->more();
    }
    return \@results;
}

sub eSort {
    my $self = shift;
    my ( $list, $col ) = @_;

    my $adapter = $self->{'columnBindings'}->[$col];
    my %result  = ();

    foreach my $row (@$list) {
        my $cell = $row->parts()->at($col);
        eval {
            my $key = $adapter->parse( $cell->text() );
            push @{ $result{$key} }, $row;
        };
        if ($@) {
            $self->exception( $cell, $@ );
            while ( $cell = $cell->more() ) {
                $self->ignore($cell);
            }
        }
    }

    return \%result;
}

sub cSort {
    my $self = shift;
    my ( $list, $col ) = @_;

    my $adapter = $self->{'columnBindings'}->[$col];
    my %result  = ();
    foreach my $row (@$list) {
        eval {
            $adapter->target($row);
            my $key = $adapter->get();
            push @{ $result{$key} }, $row;
        };
        if ($@) {
            push @{ $self->{'surplus'} }, $row;
        }
    }
    return \%result;
}

sub union {
    my $self   = shift;
    my %merged = ();
    $merged{$_}++ foreach @_;
    return [ keys %merged ];
}

sub checkLists {
    my $self = shift;
    my ( $eList, $cList ) = @_;

    if ( 0 == @$eList ) {
        push @{ $self->{'surplus'} }, @$cList;
        return;
    }
    if ( 0 == @$cList ) {
        push @{ $self->{'missing'} }, @$eList;
        return;
    }
    my $row  = shift @$eList;
    my $cell = $row->parts();
    my $obj  = shift @$cList;
    foreach my $adapter ( @{ $self->{'columnBindings'} } ) {
        last if not defined($cell);
        if ($adapter) {
            $adapter->target($obj);
        }
        $self->check( $cell, $adapter );
        $cell = $cell->more();
    }
    $self->checkLists( $eList, $cList );
}

sub markRows {
    my $self = shift;
    my ( $rows, $message ) = @_;

    my $annotation = Test::C2FIT::Fixture->label($message);
    while ($rows) {
        $self->wrong( $rows->parts() );
        $rows->parts()->addToBody($annotation);
        $rows = $rows->more();
    }
}

sub markList {
    my $self = shift;
    my ( $rows, $message ) = @_;
    my $annotation = Test::C2FIT::Fixture->label($message);
    foreach my $row (@$rows) {
        $self->wrong( $row->parts() );
        $row->parts()->addToBody($annotation);
    }
}

sub buildRows {
    my $self = shift;
    my ($rowsref) = @_;

    my $root = Test::C2FIT::Parse->from( "", undef, undef, undef );
    my $next = $root;
    foreach my $row (@$rowsref) {
        $next = $next->more(
            Test::C2FIT::Parse->from(
                "tr", undef, $self->buildCells($row), undef
            )
        );
    }
    return $root->more();
}

sub buildCells {
    my $self  = shift;
    my ($row) = @_;
    my $ncols = @{ $self->{'columnBindings'} };

    if ( !$row ) {
        my $nil = Test::C2FIT::Parse->from( "td", "nul", undef, undef );
        $nil->addToTag(" colspan=$ncols");
        return $nil;
    }
    my $root = Test::C2FIT::Parse->from( "", undef, undef, undef );
    my $next = $root;
    foreach my $adapter ( @{ $self->{'columnBindings'} } ) {
        $next =
          $next->more(
            Test::C2FIT::Parse->from( "td", "&nbsp;", undef, undef ) );
        if ( !$adapter ) {
            $self->ignore($next);
        }
        else {
            eval {
                $adapter->target($row);
                $self->info( $next, $adapter->toString( $adapter->get() ) );
            };
            if ($@) {
                $self->exception( $next, $@ );
            }
        }
    }
    return $root->more();
}

1;

=pod

=head1 NAME

Test::C2FIT::RowFixture - A RowFixture compares rows in the test data to objects 
in the system under test. Methods are invoked on the objects and returned values 
compared to those in the table. An algorithm matches rows with objects based on 
one or more keys. Objects may be missing or in surplus and are so noted.

=head1 SYNOPSIS

Normally, you subclass RowFixture.

	package MyColumnFixture;
	use base 'Test::C2FIT::ColumnFixture;'

	sub query {
	 my $self = shift;
	 return [ <your data> ];
	}

=head1 DESCRIPTION

query() should return an arrayref consisting of either blessed objects (fields and methods are used) or
unbessed hashrefs (only fields are used).


When your data is not stored as string, then you'll propably need an TypeAdapter. See more in L<Fixture>.

=head1 METHODS

=over 4

=item B<query()>

query() should return an arrayref consisting of either blessed objects (fields and methods are used) or
unbessed hashrefs (only fields are used).

=back

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

__END__

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

package fit;

import java.util.*;

abstract public class RowFixture extends ColumnFixture {

    public Object results[];
    public List missing = new LinkedList();
    public List surplus = new LinkedList();


    public void doRows(Parse rows) {
        try {
            bind(rows.parts);
            results = query();
            match(list(rows.more), list(results), 0);
            Parse last = rows.last();
            last.more = buildRows(surplus.toArray());
            mark(last.more, "surplus");
            mark(missing.iterator(), "missing");
        } catch (Exception e) {
            exception (rows.leaf(), e);
        }
    }

    abstract public Object[] query() throws Exception;  // get rows to be compared
    abstract public Class getTargetClass();             // get expected type of row

    protected void match(List expected, List computed, int col) {
        if (col >= columnBindings.length) {
            check (expected, computed);
        } else if (columnBindings[col] == null) {
            match (expected, computed, col+1);
        } else {
            Map eMap = eSort(expected, col);
            Map cMap = cSort(computed, col);
            Set keys = union(eMap.keySet(),cMap.keySet());
            for (Iterator i=keys.iterator(); i.hasNext(); ) {
                Object key = i.next();
                List eList = (List)eMap.get(key);
                List cList = (List)cMap.get(key);
                if (eList == null) {
                    surplus.addAll(cList);
                } else if (cList == null) {
                    missing.addAll(eList);
                } else if (eList.size()==1 && cList.size()==1) {
                    check(eList, cList);
                } else {
                    match(eList, cList, col+1);
                }
            }
        }
    }

    protected List list (Parse rows) {
        List result = new LinkedList();
        while (rows != null) {
            result.add(rows);
            rows = rows.more;
        }
        return result;
    }

    protected List list (Object[] rows) {
        List result = new LinkedList();
        for (int i=0; i<rows.length; i++) {
            result.add(rows[i]);
        }
        return result;
    }

    protected Map eSort(List list, int col) {
        TypeAdapter a = columnBindings[col];
        Map result = new HashMap(list.size());
        for (Iterator i=list.iterator(); i.hasNext(); ) {
            Parse row = (Parse) i.next();
            Parse cell = row.parts.at(col);
            try {
                Object key = a.parse(cell.text());
                bin(result, key, row);
            } catch (Exception e) {
                exception(cell, e);
                for (Parse rest=cell.more; rest!=null; rest=rest.more) {
                    ignore(rest);
                }
            }
        }
        return result;
    }

    protected Map cSort(List list, int col) {
        TypeAdapter a = columnBindings[col];
        Map result = new HashMap(list.size());
        for (Iterator i=list.iterator(); i.hasNext(); ) {
            Object row = i.next();
            try {
                a.target = row;
                Object key = a.get();
                bin(result, key, row);
            } catch (Exception e) {
                // surplus anything with bad keys, including null
                surplus.add(row);
            }
        }
        return result;
    }

    protected void bin (Map map, Object key, Object row) {
        if (map.containsKey(key)) {
            ((List)map.get(key)).add(row);
        } else {
            List list = new LinkedList();
            list.add(row);
            map.put(key, list);
        }
    }

    protected Set union (Set a, Set b) {
        Set result = new HashSet();
        result.addAll(a);
        result.addAll(b);
        return result;
    }

    protected void check (List eList, List cList) {
        if (eList.size()==0) {
            surplus.addAll(cList);
            return;
        }
        if (cList.size()==0) {
            missing.addAll(eList);
            return;
        }
        Parse row = (Parse)eList.remove(0);o
        Parse cell = row.parts;
        Object obj = cList.remove(0);
        for (int i=0; i<columnBindings.length && cell!=null; i++) {
            TypeAdapter a = columnBindings[i];
            if (a != null) {
                a.target = obj;
            }
            check(cell, a);
            cell = cell.more;
        }
        check (eList, cList);
    }

    protected void mark(Parse rows, String message) {
        String annotation = label(message);
        while (rows != null) {
            wrong(rows.parts);
            rows.parts.addToBody(annotation);
            rows = rows.more;
        }
    }

    protected void mark(Iterator rows, String message) {
        String annotation = label(message);
        while (rows.hasNext()) {;
            Parse row = (Parse)rows.next();
            wrong(row.parts);
            row.parts.addToBody(annotation);
        }
    }

    protected Parse buildRows(Object[] rows) {
        Parse root = new Parse(null ,null, null, null);
        Parse next = root;
        for (int i=0; i<rows.length; i++) {
            next = next.more = new Parse("tr", null, buildCells(rows[i]), null);
        }
        return root.more;
    }

    protected Parse buildCells(Object row) {
        if (row == null) {
            Parse nil = new Parse("td", "null", null, null);
            nil.addToTag(" colspan="+columnBindings.length);
            return nil;
        }
        Parse root = new Parse(null, null, null, null);
        Parse next = root;
        for (int i=0; i<columnBindings.length; i++) {
            next = next.more = new Parse("td", "&nbsp;", null, null);
            TypeAdapter a = columnBindings[i];
            if (a == null) {
                ignore (next);
            } else {
                try {
                    a.target = row;
                    next.body = gray(escape(a.toString(a.get())));
                } catch (Exception e) {
                    exception(next, e);
                }
            }
        }
        return root.more;
    }
}

