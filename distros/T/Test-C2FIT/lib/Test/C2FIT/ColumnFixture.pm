# $Id: ColumnFixture.pm,v 1.8 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::ColumnFixture;

use base 'Test::C2FIT::Fixture';
use strict;
use Test::C2FIT::TypeAdapter;
use Error qw( :try );

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new( columnBindings => [], hasExecuted => 0, @_ );
}

sub doRows {
    my $self = shift;
    my ($rows) = @_;
    $self->bind( $rows->parts() );
    $self->SUPER::doRows( $rows->more() );
}

sub doRow {
    my $self = shift;
    my ($row) = @_;

    $self->{'hasExecuted'} = 0;
    try {
        $self->reset();
        $self->SUPER::doRow($row);
        $self->execute unless $self->{'hasExecuted'};
      }
      otherwise {
        my $e = shift;
        $self->exception( $row->leaf(), $e );
      };
}

sub doCell {
    my $self = shift;
    my ( $cell, $column ) = @_;

    my $adapter = $self->{'columnBindings'}->[$column];
    eval {
        my $string = $cell->text();
        if ( $string eq "" ) {
            $self->check( $cell, $adapter );
        }
        elsif ( not defined($adapter) ) {
            $self->ignore($cell);
        }
        elsif ( $adapter->field() ) {
            $adapter->set( $adapter->parse($string) );
        }
        elsif ( $adapter->method() ) {
            $self->check( $cell, $adapter );
        }
    };
    if ($@) {
        $self->exception( $cell, $@ );
    }
}

sub check {
    my $self = shift;
    my ( $cell, $adapter ) = @_;

    if ( $self->{'hasExecuted'} ) {
        $self->SUPER::check( $cell, $adapter );
    }
    elsif ( !$self->{'hasExecuted'} ) {
        $self->{'hasExecuted'} = 1;
        try {
            $self->execute();
            $self->SUPER::check( $cell, $adapter );
          }
          otherwise {
            my $e = shift;
            $self->exception( $cell, $e );
          };
    }
}

sub reset {
    my ($self) = @_;

    # about to process first cell of row
}

sub execute {
    my ($self) = @_;

    # about to process first method call of row
}

sub bind {
    my ( $self, $heads ) = @_;
    my $column = 0;

    $self->{'columnBindings'} = [];
    while ($heads) {
        my $name = $heads->text();
        try {
            if ( $name eq "" ) {
                $self->{'columnBindings'}->[$column] = undef;
            }
            elsif ( $name =~ /^(.*)\(\)$/ ) {
                $self->{'columnBindings'}->[$column] =
                  $self->bindMethod( $self->camel($1) );
            }
            else {
                $self->{'columnBindings'}->[$column] =
                  $self->bindField( $self->camel($name) );
            }
          }
          otherwise {
            my $e = shift;
            $self->exception( $heads, $e );
          };
        $heads = $heads->more();
        ++$column;
    }
}

sub bindMethod {
    my $self = shift;
    my ($name) = @_;
    return Test::C2FIT::TypeAdapter->onMethod( $self, $name );
}

sub bindField {
    my $self = shift;
    my ($name) = @_;
    return Test::C2FIT::TypeAdapter->onField( $self, $name );
}

sub getTargetClass {
    my $self = shift;
    ref($self);
}

1;

=pod

=head1 NAME

Test::C2FIT::ColumnFixture - A ColumnFixture maps columns in the test data to fields or methods of its subclasses.

=head1 SYNOPSIS

Normally, you subclass ColumnFixture.

	package MyColumnFixture;
	use base 'Test::C2FIT::ColumnFixture;'

	sub getX {
	 my $self = shift;
	 return $self->{X};
	}

=head1 DESCRIPTION

Column headings with braces (e.g. getX()) will get bound to methods, i.e. the data entered in your document 
will be checked against the result of the respective method. A Column heading consisting of more words
will be concatened to a camel-case name ("get name ()" will be mapped to "getName()")

Column headings without braces will be bound to instance variables (=fields).
In perl these need not to be predeclared. E.g. when column heading is "surname", then the ColumnFixture
puts the text of the respective cell to a variable which can be used by C<$self-E<gt>{surname}>.
A Column heading consisting of more words will be concatened to a camel-case name 
("given name" will be mapped to "givenName")

When your data is not stored as string, then you'll propably need an TypeAdapter. See more in L<Fixture>.

=head1 METHODS

=over 4

=item B<reset()>

Will be called before a row gets processed

=item B<execute()>

Will be called either after a row has been processed or before the first usage of a method-column in the
row, depending upon which case occurs first.

=back

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

__END__

package fit;

// Copyright (c) 2002 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

public class ColumnFixture extends Fixture {

    protected TypeAdapter columnBindings[];
    protected boolean hasExecuted = false;

    // Traversal ////////////////////////////////

    public void doRows(Parse rows) {
        bind(rows.parts);
        super.doRows(rows.more);
    }

    public void doRow(Parse row) {
        hasExecuted = false;
        try {
            reset();
            super.doRow(row);
            if (!hasExecuted) {
                execute();
            }
        } catch (Exception e) {
            exception (row.leaf(), e);
        }
    }

    public void doCell(Parse cell, int column) {
        TypeAdapter a = columnBindings[column];
        try {
            String text = cell.text();
            if (text.equals("")) {
                check(cell, a);
            } else if (a == null) {
                ignore(cell);
            } else if (a.field != null) {
                a.set(a.parse(text));
            } else if (a.method != null) {
                check(cell, a);
            }
        } catch(Exception e) {
            exception(cell, e);
        }
    }

    public void check(Parse cell, TypeAdapter a) {
        if (!hasExecuted) {
            try {
                execute();
            } catch (Exception e) {
                exception (cell, e);
            }
            hasExecuted = true;
        }
        super.check(cell, a);
    }

    public void reset() throws Exception {
        // about to process first cell of row
    }

    public void execute() throws Exception {
        // about to process first method call of row
    }

    // Utility //////////////////////////////////

    protected void bind (Parse heads) {
        columnBindings = new TypeAdapter[heads.size()];
        for (int i=0; heads!=null; i++, heads=heads.more) {
            String name = heads.text();
            String suffix = "()";
            try {
                if (name.equals("")) {
                    columnBindings[i] = null;
                } else if (name.endsWith(suffix)) {
                    columnBindings[i] = bindMethod(name.substring(0,name.length()-suffix.length()));
                } else {
                    columnBindings[i] = bindField(name);
                }
            }
            catch (Exception e) {
                exception (heads, e);
            }
        }

    }

    protected TypeAdapter bindMethod (String name) throws Exception {
        return TypeAdapter.on(this, getTargetClass().getMethod(camel(name), new Class[]{}));
    }

    protected TypeAdapter bindField (String name) throws Exception {
        return TypeAdapter.on(this, getTargetClass().getField(camel(name)));
    }

    protected Class getTargetClass() {
        return getClass();
    }
}
