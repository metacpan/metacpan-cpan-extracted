# $Id: Fixture.pm,v 1.18 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::Fixture;

use strict;
use Error qw( :try );

my %summary;

our $yellow = '#ffffcf';
our $green  = '#cfffcf';
our $red    = '#ffcfcf';
our $gray   = '#808080';
our $ignore = '#efefef';
our $info   = $gray;
our $label  = '#c08080';

sub new {
    my $pkg  = shift;
    my $self = bless { counts => Test::C2FIT::Counts->new(), @_ }, $pkg;

#
# TypeAdapter support in perl: the following hashes can contain a field/method name
# to Adapter mapping. Key is the columnName, value is a fully qualified package name
# of a TypeAdapter to use
#
    $self->{fieldColumnTypeMap}  = {} unless exists $self->{fieldColumnTypeMap};
    $self->{methodColumnTypeMap} = {} unless exists $self->{fieldColumnTypeMap};
    $self->{methodSetterTypeMap} = {}
      unless exists $self->{methodSetterTypeMap};    # see actionFixture
    return $self;
}

sub counts {
    my $self = shift;
    $self->{'counts'} = $_[0] if @_;
    return $self->{'counts'};
}

sub doTables {
    my $self = shift;
    my ($tables) = @_;

    $Test::C2FIT::Fixture::summary{'run date'} = scalar localtime( time() );
    $Test::C2FIT::Fixture::summary{'run elapsed time'} =
      Test::C2FIT::Runtime->new();

    while ($tables) {
        my $heading = $tables->at( 0, 0, 0 );
        if ($heading) {
            try {
                my $pkg     = $heading->text();
                my $fixture = $self->loadFixture($pkg);
                $fixture->counts( $self->counts() );
                $fixture->doTable($tables);
              }
              otherwise {
                my $e = shift;
                $self->exception( $heading, $e );
              };
        }
        $tables = $tables->more();
    }
}

sub doTable {
    my $self = shift;
    my ($table) = @_;
    $self->doRows( $table->parts()->more() );
}

sub doRows {
    my $self = shift;
    my ($rows) = @_;
    while ($rows) {
        my $more = $rows->more();
        $self->doRow($rows);
        $rows = $more;
    }
}

sub doRow {
    my $self = shift;
    my ($row) = @_;
    $self->doCells( $row->parts() );
}

sub doCells {
    my $self         = shift;
    my ($cells)      = @_;
    my $columnNumber = 0;

    while ($cells) {
        try {
            $self->doCell( $cells, $columnNumber );
          }
          otherwise {
            my $e = shift;
            $self->exception( $cells, $e );
          };
        $cells = $cells->more();
        ++$columnNumber;
    }
}

sub doCell {
    my $self = shift;
    my ( $cell, $columnNumber ) = @_;
    $self->ignore($cell);
}

# Annotations

sub right {
    my $self = shift;
    my ($cell) = @_;
    $cell->addToTag(qq| bgcolor="$green"|);
    $self->counts()->{'right'} += 1;
}

sub wrong {
    my $self = shift;
    my ( $cell, $actual ) = @_;
    $cell->addToTag(qq| bgcolor="$red"|);
    $cell->{'body'} = $self->escape( $cell->text() );
    $cell->addToBody( $self->label("expected") . "<hr>"
          . $self->escape($actual)
          . $self->label("actual") )
      if defined($actual);
    $self->counts()->{'wrong'} += 1;
}

sub ignore {
    my $self = shift;
    my ($cell) = @_;
    $cell->addToTag(qq| bgcolor="$ignore"|);
    $self->counts()->{'ignores'} += 1;
}

sub error {
    my $self = shift;
    my ( $cell, $message ) = @_;
    $cell->{'body'} = $self->escape( $cell->text() );
    $cell->addToBody( "<hr><pre>" . $self->escape($message) . "</pre>" );
    $cell->addToTag( ' bgcolor="' . $yellow . '"' );
    $self->counts()->{'exceptions'}++;
}

sub info {
    my $self = shift;
    my ( $cell, $message );
    if ( scalar @_ == 2 ) {
        ( $cell, $message ) = @_;
        $cell->addToBody( $self->info($message) );
    }
    else {
        $message = shift;
        return qq| <font color="$info">|
          . $self->escape($message)
          . qq|</font>|;
    }
}

sub exception {
    my $self = shift;
    my ( $cell, $exception ) = @_;

    #TBD include a stack trace: (impl. should be the same as under java)
    #
    # perl does not support this directly. One solution might be using own
    # $SIG{'__DIE__'} handler. Unfortunately, this may confuse other error
    # handling routines - those from the Error-module or those from
    # the "system under test"
    #

    #	$cell->addToTag(' bgcolor="ffffcf"');
    #	$cell->addToBody('<hr><font size=-2><pre>' .
    #		$exception .
    #		"</pre></font>");
    #	$self->counts()->{'exceptions'} += 1;
    $self->error( $cell, $exception );
}

# Utilities

sub label {
    my $self = shift;
    my ($string) = @_;
    return '' unless $string;
    return qq| <font size=-1 color="$label"><i>$string</i></font>|;
}

sub gray {
    my $self = shift;
    my ($string) = @_;
    return '' unless $string;
    return qq|<font color="$gray">$string</font>|;
}

sub escape {
    my $self = shift;
    my ($string) = @_;

    return $string unless $string;

    $string =~ s/\&/&amp;/g;
    $string =~ s/</&lt;/g;

    $string =~ s/  / &nbsp;/g;
    $string =~ s|\r\n|<br />|g;
    $string =~ s|\r|<br \/>|g;
    $string =~ s|\n|<br \/>|g;
    return $string;
}

sub camel {
    my ( $pkg, $string ) = @_;
    $string =~ s/\s+$//s;
    $string =~ s/\s(\S)/uc($1)/eg;
    return $string;
}

sub parse {
    my $self = shift;
    my ( $string, $type ) = @_;
    throw Test::C2FIT::Exception("can't yet parse $type\n")
      if $type ne "generic";
    return $string;
}

sub check {
    my $self = shift;
    my ( $cell, $adapter ) = @_;

    my $text = $cell->text();
    if ( !defined($text) || $text eq "" ) {
        try {
            $self->info( $cell, $adapter->toString( $adapter->get() ) );
          }
          otherwise {
            my $e = shift;
            $self->info( $cell, "error" );
          };
    }
    elsif ( not defined($adapter) ) {
        $self->ignore($cell);
    }
    elsif ( $text eq "error" ) {
        try {
            my $result = $adapter->invoke();
            $self->wrong( $cell, $adapter->toString($result) );
          }
          otherwise {

            #TBD The Java source distinguishes between illegal access
            # and "normal" exceptions.
            $self->right($cell);
          };
    }
    else {
        try {
            my $result = $adapter->get();
            if ( $adapter->equals( $adapter->parse($text), $result ) ) {
                $self->right($cell);
            }
            else {
                $self->wrong( $cell, $adapter->toString($result) );
            }
          }
          otherwise {
            my $e = shift;
            $self->exception( $cell, $e );
          };
    }
}

sub fixtureName {
    my $self   = shift;
    my $tables = shift;
    return $tables->at( 0, 0, 0 );
}

sub loadFixture {
    my $self        = shift;
    my $fixtureName = shift;

    my $foundButNotFixture =
      qq|"$fixtureName" was found, but it's not a fixture.\n|;

    my $fixture = $self->_createNewInstance($fixtureName);

    throw Test::C2FIT::Exception($foundButNotFixture)
      unless UNIVERSAL::isa( $fixture, 'Test::C2FIT::Fixture' );

    return $fixture;
}

#
#   creates a new Instance of a Package.
#   - cares about java/perl notation
#   - mangles full qualified package name for fit/fat/eg
#
#   - should be the only code creating instances of user specific packages
#
sub _createNewInstance {
    my ( $self, $name ) = @_;

    my $perlPackageName = $self->_java2PerlFixtureName($name);
    my $instance;
    my $notFound = qq|The fixture "$name" was not found.\n|;

    try {
        $instance = $perlPackageName->new();
      }
      otherwise {};
    if ( !ref($instance) ) {
        try {
            eval "use $perlPackageName;";
            warn 1, " Result of use pgkName: $@" if $@;
            $instance = $perlPackageName->new();
          }
          otherwise {
            my $e = shift;
            warn 1, " Error Instantiating a Package: $e";

            throw Test::C2FIT::Exception($notFound);
          };
    }

    throw Test::C2FIT::Exception( "$perlPackageName - instantiation error"
      )    # if new does not return a ref...
      unless ref($instance);

    return $instance;
}

sub _java2PerlFixtureName {
    my ( $self, $fixtureName ) = @_;
    $fixtureName =~ s/^fit\./Test\.C2FIT\./;

    # Need this because example and fat packages are in our namespace - prevents
    # creation of top level namespace, frowned upon by CPAN indexer.
    $fixtureName =~ s/^eg\./Test\.C2FIT\.eg\./;
    $fixtureName =~ s/^fat\./Test\.C2FIT\.fat\./;

    $fixtureName =~ s/\./::/g;
    return $fixtureName;
}

#
#   rules for determination of the TypeAdapter to be uses for a column
#
#   1. suggestFieldType / suggestMethodResultType returns the
#      fully qualified package name of the TypeAdapter (inherits from Test::C2FIT::TypeAdapter).
#
#   2. (when 1. returned undef)
#      Default behavior, i.e. Test::C2FIT::GenericAdapter for methods,
#      Test::C2FIT::GenericArrayAdapter for array-ref-fields or
#      Test::C2FIT::GenericAdapter for fields
#

sub suggestFieldType
{   # fields in ColumnFixture, RowFixture and setter parameter in ActionFixtures
    my ( $self, $fieldColumnName ) = @_;
    return $self->{fieldColumnTypeMap}->{$fieldColumnName};
}

sub suggestMethodResultType {    # method return values in all Fixtures
    my ( $self, $methodColumnName ) = @_;
    return $self->{methodColumnTypeMap}->{$methodColumnName};
}

sub suggestMethodParamType {  # method param - see ActionFixture and TypeAdapter
    my ( $self, $methodName ) = @_;
    return $self->{methodSetterTypeMap}->{$methodName};
}

package Test::C2FIT::Counts;

sub new {
    my $pkg = shift;
    bless {
        right      => 0,
        wrong      => 0,
        ignores    => 0,
        exceptions => 0
    }, $pkg;
}

sub toString {
    my $self = shift;
    join( ", ",
        map { $self->{$_} . " " . $_ } qw(right wrong ignores exceptions) );
}

sub tally {
    my $self = shift;
    my ($counts) = @_;

    $self->{'right'}      += $counts->{'right'};
    $self->{'wrong'}      += $counts->{'wrong'};
    $self->{'ignores'}    += $counts->{'ignores'};
    $self->{'exceptions'} += $counts->{'exceptions'};
}

package Test::C2FIT::Runtime;

use overload '""' => \&toString;

sub new {
    use Benchmark;
    my $pkg = shift;
    bless { start => new Benchmark() }, $pkg;
}

sub toString {
    my $self     = shift;
    my $end      = new Benchmark();
    my $timeDiff = timediff( $end, $self->{start} );
    my $timeStr  = timestr($timeDiff);
    return $timeStr;
}

1;

=pod

=head1 NAME

Test::C2FIT::Fixture - Base class of all fixtures. A fixture checks examples in a table (of the
input document) by running the actual program. Typically you neither use this class directly, nor
subclass it directly.


=head1 SYNOPSIS


=head1 DESCRIPTION


When your data is not stored as string, then you'll propably need an TypeAdapter. Either you 
fill an appropriate hash while instantiating a Fixture, or you overload an appropriate method.

=head1 METHODS

=over 4

=item B<suggestFieldType($columnName)>

Returns a fully qualified package/classname of a TypeAdapter suitable for parsing/checking of cell entries
of the column named "$columnName".

Default implementation uses a lookup in the instance's fieldColumnTypeMap hash.
Will be used in ColumnFixture, RowFixture and setter parameter of an ActionFixture.

=item B<suggestMethodResultType($methodName)>

Used in all Fixtures. Returns a fully qualified package/classname of a TypeAdapter suitable for parsing
cell entries of the column named "$methodName" and checking them to return values of the method $methodName().

=item B<suggestMethodParamType($methodName)>

Used in ActionFixture for setter-type methods. Returns a fully qualified 
package/classname of a TypeAdapter suitable for parsing
cell entries following a cell with the content of $methodName.


=back

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/


=cut

__END__

package fit;

// Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
// Released under the terms of the GNU General Public License version 2 or later.

import java.io.*;
import java.util.*;
import java.lang.reflect.*;
import java.text.DateFormat;

public class Fixture {

    public Map summary = new HashMap();
    public Counts counts = new Counts();
    protected String[] args;

    public class RunTime {
        long start = System.currentTimeMillis();
        long elapsed = 0;

        public String toString() {
            elapsed = (System.currentTimeMillis()-start);
            if (elapsed > 600000) {
                return d(3600000)+":"+d(600000)+d(60000)+":"+d(10000)+d(1000);
            } else {
                return d(60000)+":"+d(10000)+d(1000)+"."+d(100)+d(10);
            }
        }

        String d(long scale) {
            long report = elapsed / scale;
            elapsed -= report * scale;
            return Long.toString(report);
        }
    }



    // Traversal //////////////////////////

	/* Altered by Rick Mugridge to dispatch on the first Fixture */
    public void doTables(Parse tables) {
        summary.put("run date", new Date());
        summary.put("run elapsed time", new RunTime());
        if (tables != null) {
        	Parse fixtureName = fixtureName(tables);
            if (fixtureName != null) {
                try {
                    Fixture fixture = getLinkedFixtureWithArgs(tables);
                    fixture.interpretTables(tables);
                } catch (Exception e) {
                    exception (fixtureName, e);
                    interpretFollowingTables(tables);
                }
            }
        }
    }

    /* Added by Rick Mugridge to allow a dispatch into DoFixture */
    protected void interpretTables(Parse tables) {
  		try { // Don't create the first fixture again, because creation may do something important.
  			getArgsForTable(tables); // get them again for the new fixture object
  			doTable(tables);
  		} catch (Exception ex) {
  			exception(fixtureName(tables), ex);
  			return;
  		}
  		interpretFollowingTables(tables);
  	}

    /* Added by Rick Mugridge */
    private void interpretFollowingTables(Parse tables) {
        //listener.tableFinished(tables);
            tables = tables.more;
        while (tables != null) {
            Parse fixtureName = fixtureName(tables);
            if (fixtureName != null) {
                try {
                    Fixture fixture = getLinkedFixtureWithArgs(tables);
                    fixture.doTable(tables);
                } catch (Throwable e) {
                    exception(fixtureName, e);
		        }
		    }
            //listener.tableFinished(tables);
            tables = tables.more;
        }
    }

    /* Added from FitNesse*/
	protected Fixture getLinkedFixtureWithArgs(Parse tables) throws Exception {
		Parse header = tables.at(0, 0, 0);
        Fixture fixture = loadFixture(header.text());
		fixture.counts = counts;
		fixture.summary = summary;
		fixture.getArgsForTable(tables);
		return fixture;
	}
	
	public Parse fixtureName(Parse tables) {
		return tables.at(0, 0, 0);
	}

	public Fixture loadFixture(String fixtureName)
	throws InstantiationException, IllegalAccessException {
		String notFound = "The fixture \"" + fixtureName + "\" was not found.";
		try {
			return (Fixture)(Class.forName(fixtureName).newInstance());
		}
		catch (ClassCastException e) {
			throw new RuntimeException("\"" + fixtureName + "\" was found, but it's not a fixture.", e);
		}
		catch (ClassNotFoundException e) {
			throw new RuntimeException(notFound, e);
		}
		catch (NoClassDefFoundError e) {
			throw new RuntimeException(notFound, e);
		}
	}

	/* Added by Rick Mugridge, from FitNesse */
	protected void getArgsForTable(Parse table) {
	    ArrayList argumentList = new ArrayList();
	    Parse parameters = table.parts.parts.more;
	    for (; parameters != null; parameters = parameters.more)
	        argumentList.add(parameters.text());
	    args = (String[]) argumentList.toArray(new String[0]);
	}

    public void doTable(Parse table) {
        doRows(table.parts.more);
    }

    public void doRows(Parse rows) {
        while (rows != null) {
            Parse more = rows.more;
            doRow(rows);
            rows = more;
        }
    }

    public void doRow(Parse row) {
        doCells(row.parts);
    }

    public void doCells(Parse cells) {
        for (int i=0; cells != null; i++) {
            try {
                doCell(cells, i);
            } catch (Exception e) {
                exception(cells, e);
            }
            cells=cells.more;
        }
    }

    public void doCell(Parse cell, int columnNumber) {
        ignore(cell);
    }


    // Annotation ///////////////////////////////

    public static String green = "#cfffcf";
    public static String red = "#ffcfcf";
    public static String gray = "#efefef";
    public static String yellow = "#ffffcf";

    public  void right (Parse cell) {
        cell.addToTag(" bgcolor=\"" + green + "\"");
        counts.right++;
    }

    public void wrong (Parse cell) {
        cell.addToTag(" bgcolor=\"" + red + "\"");
		cell.body = escape(cell.text());
        counts.wrong++;
    }

    public void wrong (Parse cell, String actual) {
        wrong(cell);
        cell.addToBody(label("expected") + "<hr>" + escape(actual) + label("actual"));
    }

	public void info (Parse cell, String message) {
		cell.addToBody(info(message));
	}

	public String info (String message) {
		return " <font color=\"#808080\">" + escape(message) + "</font>";
	}

    public void ignore (Parse cell) {
        cell.addToTag(" bgcolor=\"" + gray + "\"");
        counts.ignores++;
    }

	public void error (Parse cell, String message) {
		cell.body = escape(cell.text());
		cell.addToBody("<hr><pre>" + escape(message) + "</pre>");
		cell.addToTag(" bgcolor=\"" + yellow + "\"");
		counts.exceptions++;
	}

    public void exception (Parse cell, Throwable exception) {
        while(exception.getClass().equals(InvocationTargetException.class)) {
            exception = ((InvocationTargetException)exception).getTargetException();
        }
        final StringWriter buf = new StringWriter();
        exception.printStackTrace(new PrintWriter(buf));
        error(cell, buf.toString());
    }

    // Utility //////////////////////////////////

    public String counts() {
        return counts.toString();
    }

    public static String label (String string) {
        return " <font size=-1 color=\"#c08080\"><i>" + string + "</i></font>";
    }

    public static String escape (String string) {
    	string = string.replaceAll("&", "&amp;");
    	string = string.replaceAll("<", "&lt;");
    	string = string.replaceAll("  ", " &nbsp;");
		string = string.replaceAll("\r\n", "<br />");
		string = string.replaceAll("\r", "<br />");
		string = string.replaceAll("\n", "<br />");
    	return string;
    }

    public static String camel (String name) {
        StringBuffer b = new StringBuffer(name.length());
        StringTokenizer t = new StringTokenizer(name);
        if (!t.hasMoreTokens())
            return name;
        b.append(t.nextToken());
        while (t.hasMoreTokens()) {
            String token = t.nextToken();
            b.append(token.substring(0, 1).toUpperCase());      // replace spaces with camelCase
            b.append(token.substring(1));
        }
        return b.toString();
    }

    public Object parse (String s, Class type) throws Exception {
        if (type.equals(String.class))              {return s;}
        if (type.equals(Date.class))                {return DateFormat.getDateInstance().parse(s);}
        if (type.equals(ScientificDouble.class))    {return ScientificDouble.valueOf(s);}
        throw new Exception("can't yet parse "+type);
    }

    public void check(Parse cell, TypeAdapter a) {
        String text = cell.text();
        if (text.equals("")) {
            try {
                info(cell, a.toString(a.get()));
            } catch (Exception e) {
                info(cell, "error");
            }
        } else if (a == null) {
            ignore(cell);
        } else  if (text.equals("error")) {
            try {
                Object result = a.invoke();
                wrong(cell, a.toString(result));
            } catch (IllegalAccessException e) {
                exception (cell, e);
            } catch (Exception e) {
                right(cell);
            }
        } else {
            try {
                Object result = a.get();
                if (a.equals(a.parse(text), result)) {
                    right(cell);
                } else {
                    wrong(cell, a.toString(result));
                }
            } catch (Exception e) {
                exception(cell, e);
            }
        }
    }

	/* Added by Rick, from FitNesse */
    public String[] getArgs() {
        return args;
    }

}
