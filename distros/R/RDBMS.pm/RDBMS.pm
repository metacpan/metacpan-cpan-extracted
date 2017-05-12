# $Id: RDBMS.pm,v 1.11 1997/11/15 21:46:06 bjepson Exp bjepson $

package Msql::RDBMS;
$VERSION = '0.93';

=head1 NAME

B<Msql::RDBMS> - Relational Database Management System for Msql

=head1 SYNOPSIS

   use Msql::RDBMS;

   $rdbms = new Msql::RDBMS;
   $rdbms->show;

=head1 DESCRIPTION

This is a fully catalog driven database management system for Perl 5
and mini-SQL. You should use it in conjunction with the sqldef.pl script
which will generate data definition language for your tables.

=head1 GENERATING DATA DEFINITION LANGUAGE

You must pass the name of a schema definition file to sqldef.pl (an
example, B<schema.def>, is included in the examples/ subdirectory of
the distribution).  See L<sqldef.pl>.

=head1 USAGE

You can call up the entire Relational Database Management System from
your browser with a URL like this:

   http://bozos.on.the.bus/sample.cgi?db=demo

Where B<sample.cgi> is a Perl script containing the three lines of
code shown in B<SYNOPSIS>.

=head1 DEBUGGING

You can get some debugging information, which consists of a CGI::dump,
and an SQL statement, if relevant, by including debug=1 in the URL.

=head1 TODO

  Generate forms for interactive data definition.
  Enforce referential integrity (cascade/block deletes).
* Enforce uniqueness for label columns.
* Add fancy display options that support automagic hyperlinking of
     URLs and email addresses.

* denotes feature present in the original PHP/FI version.

=head1 AUTHOR

Brian Jepson <bjepson@conan.ids.net>

Paul Sharpe <paul@miraclefish.com>

You may distribute this under the same terms as Perl itself.

=head1 SEE ALSO

L<sqldef.pl>

CGI::CGI, CGI::Carp, Msql

=cut

BEGIN {

    $| = 1;
    print "Content-type: text/html\n\n";
    use vars qw($header_printed);
    $header_printed = 1;
    use CGI::Carp qw(carpout);
    carpout(STDOUT);
}

require 5.002;
use CGI;
use CGI::Carp;
use Msql;
use Date::Format;
use Date::Parse;
use strict 'vars';

my %tableAttributes = ( "DESCRIPTION" => 'tbl_description');
my %comp_num = ("="        => "Equal To",
                "&gt;"     => "Greater Than",
                "&lt;"     => "Less Than",
                "&lt;="    => "Less Than or Equal To",
                "&gt;="    => "Greater Than or Equal To",
                "&lt;&gt;" => "Not Equal To");
my @comp_num = ("=", "&gt;", "&lt;", "&lt;=", "&gt;=", "&lt;&gt;");

my %comp_char = ("CLIKE"    => "Find Similar (Case-Insensitive)",
                 "LIKE"     => "Find Similar",
                 "="        => "Equal To",
                 "&lt;&gt;" => "Not Equal To");
my @comp_char = ("CLIKE", "LIKE","=", "&lt;&gt;");

sub new {
  my ($class) = shift;
  my $self    = {};
  bless $self,$class;

  # I'm starting to expose methods from this class for other
  # modules to use, and they might already have a database
  # connection.
  #
  my $dbh = shift;
  $self->initialize($dbh);

  $self;
}

sub show {
  my($self)  = shift;
  my($query) = $self->{'query'};

  #unless ($self->validate) {
  #    return;
  #}

  my($dumpdata) = $query->dump if $query->param('debug');

  if ($self->{'action'} eq "QUERY") {
    $self->tableInfo;
    $self->multiForm;
  } elsif ($self->{'action'} eq "GETQUERY") {
    $self->tableInfo;
    $self->getquery;
    foreach my $pkey (@{$self->{pkey}}) {
      $query->delete( $pkey );
    }
  } elsif ($self->{'action'} eq "NEW") {
    $self->tableInfo;
    $self->multiForm;
  } elsif ($self->{'action'} eq "EDIT") {
    $self->tableInfo;
    $self->multiForm;
  } elsif ($self->{'action'} eq "UPDATE") {
    $self->tableInfo;
    $self->update;
  } elsif ($self->{'action'} eq "INSERT") {
    $self->tableInfo;
    if ($self->insert) {
        $self->{'action'} = "EDIT";
    } else {
        $self->{'action'} = "NEW";
    }
    $self->multiForm;
  } elsif ($self->{'action'} eq "DELETE") {
    $self->tableInfo;
    $self->delete;
    foreach my $pkey (@{$self->{pkey}}) {
      $query->delete( $pkey );
    }
  } 

  $query->delete('submit');
  $self->showtables;

  if ($query->param('debug')) {
    $self->printbuff("<p>CGI::dump:<p>");
    $self->printbuff($dumpdata);
  }

  print $query->header unless $header_printed;
  print $query->start_html(-title=>$self->{'title'},
                           -bgcolor => '#FFFFFF');

  $self->errors;
  print $self->{buffer};
  print $query->end_html;
}

sub tableInfo {
  my($self) = shift;

  die "No table name was specified." unless $self->{'table'};

  # grab some metadata
  $self->{'title'} = RDBMSGetTableAttribute(
                       $self->{'dbh'}, $self->{'table'}, "DESCRIPTION");

  @{$self->{'pkey'}}  = RDBMSGetPrimaryKey($self->{'dbh'}, $self->{'table'});
  @{$self->{'label'}} = RDBMSGetLabelKey($self->{'dbh'}, $self->{'table'});
  @{$self->{'fkey'}}  = RDBMSGetForeignKey($self->{'dbh'}, $self->{'table'});

  my (@columns, %columns);

  RDBMSGetColumnInfo($self->{'dbh'}, $self->{'table'},
                     \@columns, \%columns);

  @{$self->{'columns'}} = @columns;
  %{$self->{'column_info'}} = %columns;
}

sub showtables {
  my ($self) = shift;
  my (%fn, @row, $rownum);
  my ($sth) = $self->{'dbh'}->Query("select tbl_name, tbl_description
                                     from systables");

  my ($query) = $self->{'query'};

  $self->printbuff("<p>");
  $self->printbuff("<hr>");
  $self->printbuff("<strong>Table Options</strong><p>");
  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  while (@row = $sth->FetchRow()) {
    $query->param('table', $row[$fn{'tbl_name'}]);

    $query->param('action', "QUERY");
    my $url = $query->self_url;
    $self->printbuff(qq[<a href="$url">Query</a>&nbsp;/&nbsp;]);


    # The query all records URL
    #
    $query->param('action', "GETQUERY");
    $query->param('ignore_conditions', "TRUE");
    $query->param('submit', "Query");
    $url = $query->self_url;
    $self->printbuff(qq[<a href="$url">View</a>&nbsp;/&nbsp;]);
    $query->delete('ignore_conditions');


    $query->param('action', "NEW");
    $url = $query->self_url;
    $self->printbuff(qq[<a href="$url">Add</a>]);

    $self->printbuff(qq[<font color="green">]);
    $self->printbuff(" $row[$fn{tbl_description}]");
    $self->printbuff(qq[</font>]);

    if ($rownum < $sth->numrows) {
      $self->printbuff( "<BR>");
    }

    $rownum++;
  }
}

sub initialize {
  my $self = shift;
  my $dbh = shift;
  $self->{'query'} = new CGI;

  my $query = $self->{'query'}; # make things a little easier

  $self->{'table'}  = $query->param('table');
  $self->{'db'}     = $query->param('db');
  $self->{'action'} = $query->param('action');

  die "A database name must be specified" unless $self->{'db'};

  if (ref $dbh eq 'Msql') {
      $self->{dbh} = $dbh;
  } else {
      $self->{'dbh'} = Msql->Connect('localhost') 
        or die "Could not connect to mSQL!";
      $self->{'dbh'}->SelectDB($self->{'db'}) 
        or die "Database " . $self->{'db'} . " does not exist.";
  }
}

#
# this is a pretty overloaded method which will handle
# add, edit, query forms
#
sub multiForm {
  my($self)  = shift;
  my($query) = $self->{'query'};

  my ($i, $numrows, $urlaction, $submit, $pkeyfield, @row_edit);
  my ($ref_prompt, $filter, $expr, %fn_edit, $sth_edit);

  my @columns = @{$self->{'columns'}};
  my %columns = %{$self->{'column_info'}};

  if ($self->{'action'} eq "NEW") {
    $ref_prompt  = "Add Entry";
    $i = -1;
    $numrows = 0;
    $query->param('action', "INSERT");
    $submit = "Add";
  } elsif ($self->{'action'} eq "QUERY") {
    $ref_prompt  = "Enter Query Parameters (leave blank to see all records)";
    $i = -1;
    $numrows = 0;
    $query->param('action', "GETQUERY");
    $submit = "Query";
  } elsif ($self->{'action'} eq "EDIT") {
    $ref_prompt = "Edit Entry";
    # if the primary key was passed in as a CGI variable,
    # then it means that this form was meant to only
    # bring up the row corresponding to that key.
    #
    my $filter = $self->pkeyFilter;
    $sth_edit  = $self->{'dbh'}->Query(
                           "select * from $self->{'table'} $filter");
    @fn_edit{@{$sth_edit->name}} = (0..@{$sth_edit->name}-1);
    $numrows = $sth_edit->numrows;
    $query->param('action', "UPDATE");
    $submit = "Change";
  }

  $self->printbuff( "<table border>");
  for (; $i < $numrows; $i++) {

    if ($i >= 0) {
      @row_edit = $sth_edit->FetchRow();
    }
  
    $self->printbuff( "<tr><td>");
    $self->printbuff( "<strong>$ref_prompt</strong>:\n");
    $self->printbuff( "<pre>");
  
    # start the form
    $self->printbuff( $query->startform(-method=>'GET',
                            -action=>$query->script_name));
    $self->printbuff( $query->hidden("debug"));
    $self->printbuff( $query->hidden("table"));
    $self->printbuff( $query->hidden("action"));
    $self->printbuff( $query->hidden("db"));
    $self->printbuff( $query->hidden("cart"));

    my $column;
    foreach $column (@columns) {
      my ($col_value, $comparisons);
      my ($col_name)  = $columns{$column}{'col_name'};
      my ($col_label) = $columns{$column}{'col_label'};
      my ($col_type)  = $columns{$column}{'col_type'};
      my ($col_query) = $columns{$column}{'col_query'};
      my ($col_len)   = $columns{$column}{'col_len'};
      $col_len = 10 unless $col_len;
      $col_len = 11 if ( $col_type eq 'date' );
      $col_len = 20 if ( $col_type eq 'datetime' );
    
      if ($col_query > 0 || $self->{'action'} ne "QUERY") {
        if ($i == -1) {
          if ($col_type eq "char") {
            $col_value = "";
            $comparisons = $query->popup_menu(-name=>"$col_name" . "_compare",
                                              -values=>\@comp_char,
                                              -labels=>\%comp_char);
          } elsif ($col_type eq "int") {
            #$col_value = 0;
            $comparisons = $query->popup_menu(-name=>"$col_name" . "_compare",
                                              -values=>\@comp_num,
                                              -labels=>\%comp_num);
                                            
          } elsif ($col_type eq "real") {
            #$col_value = 0.0;
            $comparisons = $query->popup_menu(-name=>"$col_name" . "_compare",
                                              -values=>\@comp_num,
                                              -labels=>\%comp_num);
          } elsif ($col_type eq "money") {
            #$col_value = 0.0;
            $comparisons = $query->popup_menu(-name=>"$col_name" . "_compare",
                                              -values=>\@comp_num,
                                              -labels=>\%comp_num);
          }
        } else {
          $col_value = $row_edit[$fn_edit{$col_name}];
        }

        if ($col_type eq 'real' || $col_type eq 'money') {
          #$col_value *= 1;
        } elsif ( $col_type eq 'datetime' ) {
          if ( $col_value ) {
            $col_value = ctime($col_value);        # convert to human readable
          }
        } elsif ( $col_type eq 'boolean' ) {
          $col_value = 'NULL' if ( ! $col_value );
        }
      
        # display hidden fields for the primary key
        # !! but not if PRIMARY *and* FOREIGN !!
        if (   grep(/$col_name/, @{$self->{'pkey'}}) &&
             ! grep(/$col_name/, @{$self->{'fkey'}}) ) {
          $pkeyfield = $query->hidden($col_name, $col_value);
          $self->printbuff($pkeyfield);
        } elsif ( $col_type !~ /(created|modified)/ ) {
          # but for other types, display the label with
          # some padding...
          $self->printbuff( $col_label . (" " x (20 - length($col_label))));
          
          # if it's a foreign key, some special handling
          # is required.
          #
          if ( grep(/$col_name/, @{$self->{'fkey'}}) ) {
            #my $show_none = $self->{'action'} eq "QUERY" ?  1 : 0;
            my $show_none = 1;
            my $popup = $self->RDBMSForeignPopup(col_name  => $col_name,
                                                 col_value => $col_value,
                                                 show_none => $show_none);
            $self->printbuff($popup);
          } else {
            if ($self->{'action'} eq "QUERY") {
              chop($comparisons);
              $self->printbuff( $comparisons);
            }

            # if it's a normal old field, just put up a 
            # regular old text field (or textarea, if it's
            # a big field)
            #
            if ( $col_len > 65 || $col_type eq 'text' ) {
              $self->printbuff( $query->textarea(-name=>$col_name,
                                     -default=>$col_value,
                                     -rows=>5, 
                                     -cols=>45));
            } elsif ( $col_type eq 'boolean' ) {
                $self->printbuff($query->radio_group(-name=>$col_name,
                                    -values=>[1,0],
                                    -default=>$col_value,
                                    -labels=>{1=>'Yes',
                                              0=>'No'}) );
            } else {
              $self->printbuff( $query->textfield(-name=>$col_name,
                                      -default=>$col_value,
                                      -size=>$col_len, 
                                      -maxlength=>$col_len));
            }
          }
          $self->printbuff( "\n");
        }
      }
    }
    
    $self->printbuff( $query->reset );

    # If we are dealing with a compound primary key, the Change button
    # won't really work at all. As a result, if the value of $submit is
    # change, and there is more than one primary key, we won't show it.
    #
    if ($submit ne 'Change' or @{$self->{pkey}} == 1) {
        $self->printbuff( $query->submit(-name=>"submit",
                                         -value=>$submit));
    }
    $self->printbuff( $query->endform);

    if ($self->{'action'} eq "EDIT") {
      $query->param('action', "DELETE");
      $self->printbuff( $query->startform(-method=>'GET',
                              -action=>$query->script_name));
      $self->printbuff( $query->hidden("debug"));
      $self->printbuff( $query->hidden("table"));
      $self->printbuff( $query->hidden("db"));
      $self->printbuff( $query->hidden("action"));
      $self->printbuff( $query->hidden("cart"));
      $self->printbuff( $pkeyfield);
      $self->printbuff( $query->submit(-name=>"submit",
                           -value=>"Delete"));
      $self->printbuff( $query->endform);
    }
    
    $self->printbuff( "</td></tr>");
    
  }
  $self->printbuff( "</table>");

  if ($self->{'action'} eq "EDIT") {
      # get a list of dependent tables
      #
      my $tbl_name = $self->{'table'};
      my $desc = $self->{'title'};
      
      my $url = $query->script_name . "?db=" . $self->{'db'} .
                                      "&table=" . $tbl_name .
                                      "&action=NEW" .
                                      "&cart=" . $query->param('cart') .
                                      "&debug=" . $query->param('debug');
      $self->printbuff(qq[<a href="$url">Add a new record to this (the $desc) table.</a><br>]);

      my @rows;

      # Get the set of tables that are children of this table, such that
      # their dependence on this table is one part of a multivalued primary
      # key.
      # 
      my $sql = qq[
                SELECT DISTINCT systables.tbl_name, systables.tbl_description, a.col_name, a.fkey_col
                   FROM syskeys a, systables, syskeys b
                   WHERE a.tbl_name = '$tbl_name'
                   AND a.key_type = 'FOREIGN'
                   AND b.col_name = a.col_name
                   AND a.tbl_name = b.tbl_name
                   AND b.key_type = 'PRIMARY'
                   AND systables.tbl_name = a.fkey_tbl
                   ];

      my %fkey_map;
      my $sth = $self->{'dbh'}->Query($sql);
      while (my %row = $sth->fetchhash()) {
        push @rows, \%row;
        $fkey_map{ $row{col_name} } = $row{fkey_col};
      }

      $sql = qq[
                SELECT b.tbl_name, systables.tbl_description
                   FROM syskeys a, syskeys b, systables
                   WHERE a.tbl_name = '$tbl_name'
                   AND a.key_type = 'PRIMARY'
                   AND b.key_type = 'FOREIGN'
                   AND a.col_name = b.col_name
                   AND a.tbl_name <> b.tbl_name
                   AND systables.tbl_name = b.tbl_name
                   ];
      $sth = $self->{'dbh'}->Query($sql);
      while (my %row = $sth->fetchhash()) {
        push @rows, \%row;
      }

      # construct the key/value pairs for the primary keys
      #
      my $pkeystring;
      foreach my $pkey (@{$self->{pkey}}) {

        # Is there a corresponding entry in the map of col_names to
        # fkey_cols? If so, use the fkey_col instead of the col_name.
        #
        my $pkey_colname = $fkey_map{$pkey} || $pkey;
        $pkeystring .= "&$pkey_colname=" . $query->param($pkey);
      }

      foreach my $row (@rows) {

          my %row = %$row;

          my $url = $query->script_name . "?db=" . $self->{'db'} .
                                          "&table=" . $row{tbl_name} .
                                          "&action=GETQUERY" .
                                          "$pkeystring" .
                                          "&cart=" . $query->param('cart') .
                                          "&debug=" . $query->param('debug');
          $self->printbuff(qq[<a href="$url">View related records from the $row{tbl_description} table.</a><br>]);

          $url = $query->script_name . "?db=" . $self->{'db'} .
                                          "&table=" . $row{tbl_name} .
                                          "&action=NEW" .
                                          "$pkeystring" .
                                          "&cart=" . $query->param('cart') .
                                          "&debug=" . $query->param('debug');
          $self->printbuff(qq[<a href="$url">Add a new related record to the $row{tbl_description} table.</a><p>]);
      
      }
  }
}

#
# perform a query that was defined in multiForm
#
sub getquery {
  my ($self) = shift;
  my ($query) = $self->{'query'};
  my @columns = @{$self->{'columns'}};
  my %columns = %{$self->{'column_info'}};
  my ($comparison, $value, $sql, $seen);
  my $table   = $self->{'table'};

  $self->printbuff( "<h1>Choose from the list of $self->{'title'}</h1>");

  my($pkey_columns, @label_columns, $label_columns, @from, $from, $where, $order);
  foreach (@columns) {
    $comparison = $query->param($_ . '_compare');

    # Convert from the HTML elements to ASCII...
    #
    $comparison =~ s/&lt;/</g;
    $comparison =~ s/&gt;/>/g;

    $comparison = '=' unless $comparison;
    $value      = $query->param($_);

    $query->delete($_ . '_compare');
    $query->delete($_);

    # wrap char types in a single quote.
    if ($comparison =~ /LIKE/i) {
        $value = qq[%$value%];
    }

    if ($columns{$_}{'col_type'} =~ /^(char|text|date)$/ && $value) {
      $value = $self->{'dbh'}->quote($value);
    }

    # convert text dates to time format
    if ($columns{$_}{'col_type'} =~ /(datetime|created|modified)/
      && $value ) {
      $value = str2time($value);
    }

    # Ignore conditions has been added to allow the View link to select all
    # records, ignoring any ids and values that may have stuck around in
    # the query string.
    #
    if ( !$query->param('ignore_conditions') and $value ne '' 
         and $value ne 'NULL' ) {
      $where .= " AND " if $seen; $seen = 1;
      $where .= " $table.$_ $comparison $value ";
    }

    # handle LABEL columns
    my $column = $_;
    if ( grep(/$column/, @{$self->{'label'}}) ) {

      my($labels);

      if ( grep(/$column/, @{$self->{'fkey'}}) ) {                   # fkey labels 
        # should really recurse in the case where
        # columns are LABEL+FOREIGN
        my ($fkeytable, $fkeycolumn, @fkeylabels) =                   # get label fields from
          $self->RDBMSGetForeignKeyInfo($column);                  # related table
        $labels = keyColumns($fkeytable, \@fkeylabels);

        push(@label_columns, @fkeylabels);
        push(@from, $fkeytable) if ( ! grep(/$fkeytable/, @from) );

        $where .= "AND " if $seen; $seen = 1;
        $where .= "$table.$column = $fkeytable.$fkeycolumn\n";
      } else {                                                          # regular labels
        $labels = "$table.$column";
        push(@label_columns, $column);
      }

      # build SELECT clause
      if ( $label_columns ) {
        $label_columns .= ", $labels";
      } else {
        $label_columns  = $labels;
      }

      # build ORDER BY clause
      if ( $order ) {
        $order .= ", $labels";
      } else {
        $order = "$labels";
      }
    }
  }
  
  $from = $table;
  foreach ( @from ) { $from .= ", $_"; }

  $pkey_columns  = keyColumns($table, $self->{'pkey'});

  $sql  = "SELECT   $pkey_columns";
  $sql .= ", $label_columns" if ( $label_columns );
  $sql .= "\n";
  $sql .= "FROM     $from\n";
  $sql .= "WHERE    $where\n" if ( $where );
  $sql .= "ORDER BY $order\n" if ( $order );

  $self->printbuff( "<p>$sql<p>") if $query->param('debug');
  my($sth, %fn, @row, $count, $url, $this_label);

  $query->delete('submit');
  $query->param('action', "EDIT");

  $sth = $self->{'dbh'}->Query($sql);
  $self->error($sql) if $self->{debug};
  return if $self->error;
  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  my(%row);
  while (%row = $sth->FetchHash()) {
    $count++;
    # set query string parameters for primary key columns
    foreach ( @{$self->{'pkey'}} ) {
      $query->param($_, $row{$_});
    }

    $this_label = '';
    foreach ( @label_columns ) {
        $this_label .= qq[<FONT COLOR="green">|</FONT>] if ( $this_label );
        $this_label .= $row{$_};
    }

    $url = $query->self_url;
    $self->printbuff( qq[<a href="$url">$this_label</a><br>]);
  }
  # delete pkey from query string
  foreach ( @{$self->{'pkey'}} ) {
    $query->delete($_);
  }

  $self->printbuff("No rows matched your query.") unless $count;
}

sub keyColumns {
  my ($table, $column_ref) = @_;
  my $column_string        = '';

  foreach ( @$column_ref ) {
    $column_string .= ', ' if ( $column_string );
    $column_string .= "$table.$_";
  }

  return $column_string;
}

sub update {
  my ($self)  = shift;
  my ($query) = $self->{'query'};
  my ($seen, $value, $column_list, $sql);

  my @columns = @{$self->{'columns'}};
  my %columns = %{$self->{'column_info'}};

  my $column;
  foreach $column (@columns) {
    if ( ! grep(/$column/, @{$self->{'pkey'}}) 
      && $columns{$column}{'col_type'} ne 'created' ) {
      $value = $query->param($column);

      # wrap char types in a single quote.
      if ($columns{$column}{'col_type'} =~ /^(char|text|date)$/) {
        $value = $self->{dbh}->quote($value);
      }

      if ( $columns{$column}{'col_type'} =~ /^int|real|boolean$/ ) {
        $value = 'NULL' if ( $value eq '' );
      }

      if ($columns{$column}{'col_type'} eq 'real' 
          || $columns{$column}{'col_type'} eq 'money') {
        $value *= 1 if ( $value ne 'NULL' );
      }

      # pseudo type 'datetime'
      # CAVEAT: this will hang if datetime is before the epoch
      if ( $columns{$column}{'col_type'} eq 'datetime' ) {
        if ( $value ) {
          $value = str2time($value);        # convert to time value
        } else {
          $value = 'NULL';
        }
      }

      # pseudo type 'modified'
      if ( $columns{$column}{'col_type'} eq 'modified' ) {
        $value = time;                        # 'now'
      }

      $column_list .= ", " if $seen;
      $column_list .= "$column = $value";
      $seen = 1;
    }
  }

  my $filter = $self->pkeyFilter;
  my ($sth);
  $sql = "UPDATE $self->{'table'} SET $column_list $filter";

  $self->printbuff("<p>$sql<p>") if $query->param('debug');

  $self->log($sql);
  $sth = $self->{'dbh'}->Query($sql);

  unless ($self->error) {
    $self->printbuff( "The data was changed successfully.");
  } else {
    $self->printbuff( "The action was unsuccessful.");
  }
}

sub insert {
  my ($self) = shift;
  my ($query) = $self->{'query'};
  my ($seen, $value, $column_list, $insert_list, $sql);

  my @columns = @{$self->{'columns'}};
  my %columns = %{$self->{'column_info'}};

  my $column;
  foreach $column (@columns) {
    $column_list .= ", " if $seen;
    $column_list .= $column;

    $value = $query->param($column);

    if ( $columns{$column}{'col_type'} =~ /^int|real|boolean$/ ) {
      $value = 'NULL' if ( ! $value );
    }

    if (   grep(/$column/, @{$self->{'pkey'}}) ) {            # pkey
      if ( ! grep(/$column/, @{$self->{'fkey'}}) ) {            # ! fkey
        # get a new id
        $sql    = qq[SELECT _seq FROM ] . $self->{'table'};
        my $sth = $self->{dbh}->query($sql);
        return 0 if $self->error;

        my %result_hash = $sth->fetchhash;
        my $id          = $result_hash{_seq};

        $value = $id;
      }
      $query->param($column, $value);
    }

    # wrap char types in a single quote.
    if ( $columns{$column}{'col_type'} =~ /^(char|text|date)$/ ) {
      $value = $self->{dbh}->quote($value);
    }

    # PAS Wednesday Jul 16 12:50:52 1997
    # This is making me carp!
    #
    # check uniqueness of the "label" column
    #
    #if ($column eq $self->{'label'}) {
    #  $sql = qq[SELECT * FROM ] .  $self->{'table'} .
    #         qq[ WHERE $column = $value];
    #  my $sth = $self->{dbh}->query($sql);
    #  if ($sth->numrows > 0) {
    #      $self->error(qq[Sorry; there's already a row in that table named ] . 
    #                      $query->param($column_) . qq[.]);
    #      return 0;
    #  }
    #}

    if ($columns{$column}{'col_type'} eq 'real' 
        || $columns{$column}{'col_type'} eq 'money') {
      $value *= 1 if ( $value ne 'NULL' );
    }

    # pseudo type 'datetime'
    # CAVEAT: this will hang if datetime is before the epoch
    if ( $columns{$column}{'col_type'} eq 'datetime' ) {
      if ( $value ) {
        $value = str2time($value);        # convert to time value
      } else {
        $value = 'NULL';
      }
    }

    # pseudo types 'created' and 'modified'
    if ( $columns{$column}{'col_type'} =~ /(created|modified)/ ) {
      $value = time;                        # 'now'
    }

    $insert_list .= ", " if $seen;
    $insert_list .= $value;
    
    $seen = 1;
  }

  $sql = "INSERT INTO $self->{'table'} ( $column_list ) 
        VALUES ( $insert_list )";

  $self->printbuff( "<p>$sql<p>") if $query->param('debug');

  $self->log($sql);
  my($sth) = $self->{'dbh'}->Query($sql);

  unless ($self->error) {
    $self->printbuff( "The new data was added successfully.");
  } else {
    $self->printbuff( "The action was unsuccessful.");
  }

  return 1;
}

sub delete {
  my ($self) = shift;
  my ($query) = $self->{'query'};

  my ($sql, $sth, $filter);
  $filter = $self->pkeyFilter;
  $sql    = "DELETE FROM $self->{'table'} $filter";
  $self->printbuff( "<p>$sql<p>") if $query->param('debug');

  $self->log($sql);
  $sth = $self->{'dbh'}->Query($sql);
  unless ($self->error) {
    $self->printbuff( "The row was deleted successfully.");
  } else {
    $self->printbuff( "The action was unsuccessful.");
  }
}

#
# semi-static methods
#

sub RDBMSGetTableAttribute {

  my $dbh   = shift;
  my $table = shift;

  my $attrib_key = shift;
  my $attrib = $tableAttributes{$attrib_key};
  my (@row, %fn, $col, $sth);

  $sth = $dbh->Query ("select * from systables 
                     where tbl_name = '$table'") || die;
  die "Could not locate specified table." unless @row = $sth->FetchRow();

  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  $row[$fn{'tbl_description'}];

}

sub RDBMSGetColumnInfo {
  my $dbh   = shift;
  my $table = shift;
  my $columns_array = shift;
  my $columns_hash  = shift;
  my (@row, %fn, $col, $sth_columns);

  $sth_columns = $dbh->Query("select * from syscolumns 
                            where tbl_name = '$table'");
  @fn{@{$sth_columns->name}} = (0..@{$sth_columns->name}-1);

  while (@row = $sth_columns->FetchRow()) {
    $$columns_array[$col++] = $row[$fn{'col_name'}];
    foreach (@{$sth_columns->name}){
      $$columns_hash{$row[$fn{'col_name'}]}{$_} = $row[$fn{$_}];
    }
  }
}

sub RDBMSGetKey {
  my $dbh   = shift;
  my $table = shift;
  my $key   = shift;
  my ($sth, %fn, @row);

  $sth = $dbh->Query ("select col_name from syskeys
                          where tbl_name = '$table' 
                          and key_type = '$key'");

  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  return undef unless (@row = $sth->FetchRow());

  $row[$fn{'col_name'}];
}

sub RDBMSGetLabelKey {
  RDBMSGetKeyColumns(shift, shift, "LABEL");
}

sub RDBMSGetPrimaryKey {
  RDBMSGetKeyColumns(shift, shift, "PRIMARY");
}

sub RDBMSGetForeignKey {
  RDBMSGetKeyColumns(shift, shift, "FOREIGN");
}

# PAS Wednesday Jul 23 13:08:30 1997
# return a list of rows
# a) so that we can have multiple label columns
# b) so that we can have composite keys
sub RDBMSGetKeyColumns {
  my $dbh   = shift;
  my $table = shift;
  my @keys  = @_;
  my ($sth, %fn, @row);

  # build condition for list of keytypes to get
  my $key_condition = '';
  $_ = shift @keys;
  $key_condition .= " and (key_type = '$_' ";
  while ( $_ = shift @keys ) {
    $key_condition .= " or key_type = '$_'";
  }
  $key_condition .= ')';

  $sth = $dbh->Query("select col_name
                      from   syskeys
                      where  tbl_name = '$table'
                      $key_condition");

  #return undef unless (@row = $sth->FetchRow());
  return () unless (@row = $sth->FetchRow());

  # get all rows with this key type
  while ( $_ = $sth->FetchRow() ) {
    push(@row, $_);
  }

  @row;
}

sub RDBMSGetKeyType {
  my $dbh    = shift;
  my $table  = shift;
  my $column = shift;
  my ($sth, %fn, @row);

  $sth = $dbh->Query ("select key_type from syskeys
                          where tbl_name = '$table' 
                          and   col_name = '$column'");
  
  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  return undef unless (@row = $sth->FetchRow());

  $row[$fn{'key_type'}];

}

sub RDBMSGetTableOfKey {
  my $dbh    = shift;
  my $column = shift;
  my $key    = shift;
  my ($sth, %fn, @row);

  $sth = $dbh->Query ("select tbl_name from syskeys
                          where col_name = '$column' 
                          and key_type = '$key'");

  @fn{@{$sth->name}} = (0..@{$sth->name}-1);
  return undef unless (@row = $sth->FetchRow());

  $row[$fn{'tbl_name'}];
}

sub RDBMSGetTableOfPrimaryKey {
  RDBMSGetTableOfKey(shift, shift, "PRIMARY");
}

#### Method: error()
=pod

=over 4

=item error()

The error handling method will handle errors in two ways. 
The first is to pass it no values whatsoever; it will 
check the mini-SQL connection for errors, and register 
any error that is found with the list of errors for this 
form. The second way to use this is to pass in a 
user-defined error, which will be registered in the list 
of errors, but this will not check the mini-SQL connection 
for errors. This is a good method to invoke after any SQL 
call; it returns true if there was an error, and all
errors will get displayed when you invoke display_page().

=back

=cut
####
sub error {
    my $self = shift;

    # if the user passed in an error, use that 
    # message, or look for one in the mSQL connection.
    #
    my $error = shift || $self->{dbh}->errmsg;

    # if there was an error, add it to the list of errors, 
    # and return 1.
    #
    if ($error) {
        push @{$self->{errors}}, $error;
        return 1;
    }
}
#### Method: errors()
=pod

=over 4

=item errors()

This method displays all of the errors in the list of 
errors. Each error is displayed in a threatening red 
color. This is normally called by display_page(), but 
if you want to annoy your users, you should call it as 
often as possible.

=back

=cut
####
sub errors {

    my $self = shift;
    my @errors = @{$self->{errors}};

    # iterate over the list of errors, and display them 
    # in a big red font.
    #
    foreach (@errors) {
        print qq[<font size="+2" color="red">];
        print;
        print qq[</font><p>];
    }

}

#### Method: printbuff()
=pod

=over 4

=item printbuff()

Adds some text to the HTML buffer.

=back

=cut
####
sub printbuff {
    my $self = shift;
    $self->{buffer} .= join(" ", @_);
}

sub validate {
    my $self = shift;
    my $query = $self->{query};
    my $cart = $query->param('cart');
    my $uid  = $query->param('uid');
    my $pwd  = $query->param('pwd');

    my $url = $query->script_name . "?db=" . $self->{'db'} .
              "&debug=" . $query->param('debug');
    my $tryagain = qq[<p>Follow <a href="$url">this link</a> to log in again.];

    # if there's no cart, but there's a userid and password,
    # try to log in.
    #
    if (!$cart && $uid && $pwd) {

        $query->delete('uid');
        $query->delete('pwd');

        # check user id and password
        #
        my $sth = $self->{dbh}->query(
            qq[select password from sysusers where userid='$uid']);
        if (ref($sth)) {
            my %hash = $sth->fetchhash;
            unless (crypt($pwd, substr($pwd, 0, 2)) eq $hash{password}) {
                print "Bad userid or password. $tryagain";
                exit;
            }
        } else {
            my $msg = $self->{dbh}->errmsg;
            die "Error trying to get user information: $msg";
            exit;
        }

        $cart = time . $$;
        $query->param('cart', $cart);

        # open the cart
        #
        my $fn = "/var/tmp/$cart.cart";
        open(CART, "> $fn") || die "Couldn't create user profile: $fn ($!)";
        my $ip = $ENV{REMOTE_ADDR};
        print CART $ip;
        close(CART);
        chmod 0666,$fn;

        return 1;

    }

    # if there's no cart, go to the login page.
    #
    if (!$cart) {
    
        $self->{buffer} = '';
        $self->printbuff( $query->start_html(-title=>$self->{'title'},
                                             -bgcolor => '#FFFFFF'));
        $self->printbuff(qq[<h1>Please Log In</h1><hr>]);
        $self->printbuff(qq[<center>]);

        $self->printbuff($query->startform);
        $self->printbuff(qq[<p>User Id: ]);
        $self->printbuff( $query->textfield( -name => 'uid',
                                             -size => 8));

        $self->printbuff(qq[ Password: ]);
        $self->printbuff( $query->password_field( -name => 'pwd',
                                             -size => 8));
        $self->printbuff(qq[<p>]);
        $self->printbuff( $query->submit( -name => 'submit',
                                          -value => 'Log In'));
        $self->printbuff($query->hidden('db'));
        $self->printbuff($query->endform);
        #$self->printbuff(qq[</center>]);

        print $query->header unless $header_printed;
        $self->errors;
        print $self->{buffer};
        print $query->end_html;
        return 0;

    }

    if ($cart) {
        # open the cart
        #
        my $fn = "/var/tmp/$cart.cart";
        unless (open(CART, $fn)) {
            print "Couldn't open user profile: $fn ($!) $tryagain";
            exit;
        }

        my $ip = <CART>;
        close(CART);
        chomp $ip;
        if ($ip ne $ENV{REMOTE_ADDR}) {
            print "Bogus user profile: $fn (Bad IP Address) $tryagain";
            exit;
        }

        return 1;
    }
}

sub log {
    my $self = shift;
    my $data = shift;
    my $logfile = $self->{logfile} || return;

    open (LOG, ">>$logfile") || die "Could not open $logfile: $!";

    if (flock(LOG, 2)) {
        seek(LOG, 0, 2);
        print LOG "$data \\g\n";
    } else {
        $self->error("Could not lock: $logfile");
    }
    flock(LOG, 8);
    close (LOG);
    chmod 0666,$logfile;
} 

sub set_logfile {
    my $self = shift;
    $self->{logfile} = shift;
}

sub RDBMSForeignPopup {
    my $self = shift;
    my %parms = @_;
    my $col_name  = $parms{col_name};
    my $col_value = $parms{col_value};
    my $show_none = $parms{show_none};

    # find the table and column names which relate to this column
    # (the foreign key from the current table)
    # this information should be stated explicitly in the schema
    #
    #my ($ref_fkeytable) = 
              #RDBMSGetTableOfPrimaryKey($self->{dbh}, $col_name);

    my ($fkeytable, $fkeycolumn, @fkeylabels) = 
      $self->RDBMSGetForeignKeyInfo($col_name);

    my($fkeylabels) = keyColumns($fkeytable, \@fkeylabels);

    my $sql = "SELECT   $fkeytable.$fkeycolumn";
    $sql   .= ", $fkeylabels"           if ( $fkeylabels );
    $sql   .= "\n";
    $sql   .= "FROM     $fkeytable\n";
    $sql   .= "ORDER BY $fkeylabels\n"  if ( $fkeylabels );

    my $sth = $self->{'dbh'}->Query($sql);

    my ($ml) = 0;

    my (%menu_labels, @menu_options, %fn, @row);
    # if the screen is in query-mode, then make
    # sure to add a "none" option...
    #
    if ($show_none) {
        $menu_labels{"0"}    = "[ None ]";
        $menu_options[$ml++] = "NULL";
    }
            
    # do the usual voodoo to process each row in the
    # result set. Make two arrays; one (scalar) of only the
    # option values, and a hash of the option values (the
    # foreign key value) and the option labels.
    #
    #@fn{@{$sth->name}} = (0..@{$sth->name}-1);
    while (@row = $sth->FetchRow()) {
      #$menu_labels{$row[$fn{$col_name}]} = $row[$fn{$fkeylabels}];
      #$menu_options[$ml++] = $row[$fn{$col_name}];

      $menu_options[$ml++] = $row[$fkeycolumn];
      $menu_labels{$row[$fkeycolumn]} = join(',', @row[1 .. $#row]);
    }

    # throw it up there as a popup menu
    my $query = $self->{query};
    return $query->popup_menu(-name=>$col_name, 
                              -values=>\@menu_options,
                              -labels=>\%menu_labels,
                              -default=>$col_value);
}

# build SQL 'WHERE' clause to filter on pkey
sub pkeyFilter {
  my $self  = shift;
  my $query = $self->{'query'};

  my @pkey_value;
  foreach ( @{$self->{'pkey'}} ) {
    push(@pkey_value, $query->param($_));
  }

  my $filter = '';
  if ( @pkey_value ) {
    my @pkey_column = @{$self->{'pkey'}};
    my $i;

    $filter = " where $pkey_column[0] = $pkey_value[0] ";
    for ($i = 1; $i <= $#pkey_value; $i++) {
      $filter .= " and $pkey_column[$i] = $pkey_value[$i]";
    }
  }

  return $filter;
}

# IN:  foreign key column name
# OUT: related table and column
#      list of label columns from related table
sub RDBMSGetForeignKeyInfo {
  my $self     = shift;
  my $col_name = shift;

  my $sql   = "SELECT fkey_tbl, fkey_col
               FROM   syskeys 
               WHERE  tbl_name = '$self->{'table'}'
               AND    col_name = '$col_name' 
           AND    key_type = 'FOREIGN'";
  my ($sth) = $self->{'dbh'}->Query($sql);
  my ($fkey_tbl, $fkey_col) = $sth->fetchrow;

  # find out what the "label keys" of that table are
  my (@fkey_labels) = RDBMSGetLabelKey($self->{'dbh'}, $fkey_tbl);

  return($fkey_tbl, $fkey_col, @fkey_labels);
}

1;
