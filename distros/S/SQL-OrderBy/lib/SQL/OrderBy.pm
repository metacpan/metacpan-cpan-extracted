# $Id: OrderBy.pm,v 1.5 2004/08/23 03:06:21 gene Exp $

package SQL::OrderBy;
$VERSION = '0.09';
use strict;
use warnings;
use Carp;

# Transform an order by clause.
sub toggle_resort {
    my %args = @_;

    # Set the column name list and the directions.
    my ($columns, $direction, $asc_desc) = get_columns(
        %args,
        name_direction => 1,
        numeric_direction => 1,
    );

    # Handle a selected column.
    if (my $name = $args{selected}) {
        ($name, $direction, $asc_desc) = _name_direction(
            $name, $direction, $asc_desc
        );

        # Toggle if the selected column was already the first one.
         if ($columns && @$columns && $name eq $columns->[0]) {
             $direction->{$name} = $direction->{$name} + 0 ? 0 : 1;
         }

        # Remove the selected column name from its old position.
        @$columns = grep { $_ ne $name } @$columns;
        # And add the selected column name to the beginning.
        unshift @$columns, $name;
    }

    # Convert from numeric, if asked to.
    %$direction = to_asc_desc ($direction, %args)
        unless $args{numeric_direction};

    # Fetch our "name direction" array.
    @$columns = col_dir_list ($columns, $direction);

    # Return the column ordering as an arrayref or string.
    return wantarray ? @$columns : join ', ', @$columns;
}

# Return the column names and directions as either hash/array
# references, or a column array, or an "order by" clause.
sub get_columns {
    my %args = @_;

    # Set the order array from the order_by argument.
    my @order;
    if (ref $args{order_by} eq 'ARRAY') {
        @order = @{ $args{order_by} };
#        warn "Empty order list provided." unless @order;
    }
    else {
        if ($args{order_by}) {
            # Strip off any unneeded SQL clauses.
            $args{order_by} =~ s/^.*?\border by\s+(.*)$/$1/i;
            # Split the order clause.
            @order = split /\s*,\s*/, $args{order_by};
        }
        else {
            @order = ();
#            warn "No statement or clause provided.\n" unless $args{order_by};
        }
    }

    # Hold column names and directions.
    my ($columns, $direction, $asc_desc);

    # Set the column array and direction hashes.
    for (@order) {
        (my $name, $direction, $asc_desc) = _name_direction(
            $_, $direction, $asc_desc
        );

        # Add the column to our columns array.
        push @$columns, $name;
    }

    # Make alpha directions if asked to.
    %$direction = to_asc_desc ($asc_desc, %args)
        unless $args{numeric_direction};

    # NOTE: name_direction only makes sense in an array context.
    if ($args{name_direction}) {
        $columns = [ $columns, $direction, $asc_desc ];
    }
    else {
        @$columns = col_dir_list ($columns, $direction);
    }

    return wantarray ? @$columns : join ', ', @$columns;
}

# Return an array of column names with their respective directions
# concatinated.  This is conditional concatination.  ASC/DESC vs.
# 1/0 issues do not concern us here.
sub col_dir_list {
    my ($columns, $direction) = @_;
    return map {
        $direction->{$_}
            ? "$_ $direction->{$_}"
            : $_
    } @$columns;
}

# Return alpha directions in place of numeric eqivalents.
sub to_asc_desc {
    my $dir = shift;
    my %args = @_;

    # Set default direction strings.
    my ($asc, $desc) = $args{uc_direction}
        ? ('ASC', 'DESC') : ('asc', 'desc');

    # Replace directions with "proper" values.
    for (keys %$dir) {
        # From numeric
        if (defined $dir->{$_} && $dir->{$_} =~ /^\d+$/) {
            $dir->{$_} = $dir->{$_}
                ? $args{show_ascending} ? $asc : ''
                : $desc;
        }
        # Use existing if present, ascend otherwise.
        else {
            $dir->{$_} = $dir->{$_}
                ? lc ($dir->{$_}) eq 'desc'
                    ? $dir->{$_}
                    : $args{show_ascending} ? $dir->{$_} : ''
                : $args{show_ascending} ? $asc : ''
        }
    }

    return %$dir;
}

sub _name_direction {
    my ($col, $direction, $asc_desc) = @_;

    if ($col =~ /^(.*?)(?:\s+(asc|desc))?$/i) {
        # Use the direction provided; Ascend by default.
        ($col, my $dir) = ($1, $2);
        # Set the numeric directions.
        $direction->{$col} = $dir && lc ($dir) eq 'desc' ? 0 : 1;
        # Set the case sensitive alpha directions.
        $asc_desc->{$col} = $dir ? $dir : '';
    }

    return $col, $direction, $asc_desc;
}

1;
__END__

=head1 NAME

SQL::OrderBy - Transform an SQL "order by" clause

=head1 SYNOPSIS

  use SQL::OrderBy;

  @order = SQL::OrderBy::toggle_resort(
      order_by => ['name', 'artist', 'album'],
      selected => 'artist',
      show_ascending => 1,
  );  # ('artist asc', 'name asc', 'album asc')

  # resort ad infinitum
  $initial_order = 'name, artist, album';
  print scalar SQL::OrderBy::toggle_resort(
      selected => 'time',
      order_by => scalar SQL::OrderBy::toggle_resort(
          selected => 'artist',
          order_by => scalar SQL::OrderBy::toggle_resort(
              selected => 'artist',
              order_by => $initial_order,
          )
      )
  );  # 'time, artist desc, name, album'


The following functions are either used by the resort function(s)
or exist to allow compatibility with other SQL statement handling
modules.

  %direction = SQL::OrderBy::to_asc_desc( \%direction );
  # (name=>'', artist=>'desc', album=>'')

  %direction = SQL::OrderBy::to_asc_desc(
      \%direction,
      show_ascending => 1
  );  # (name=>'asc', artist=>'desc', album=>'asc')

  @columns = SQL::OrderBy::get_columns(
      order_by => 'Name, Artist Desc, Album'
  );  # ('Name', 'Artist Desc', 'Album')

  $columns = SQL::OrderBy::get_columns(
      order_by => ['NAME', 'ARTIST DESC', 'ALBUM'],
      show_ascending => 1,
      uc_direction   => 1,
  );  # 'NAME ASC, ARTIST DESC, ALBUM ASC'

  # Fetch the columns as a name array and direction hashes.
  @columns = SQL::OrderBy::get_columns(
      order_by => 'name, artist deSc, album',
      name_direction    => 1,
      numeric_direction => 1,
  );  # ( ['name', 'artist', 'album'],
      #   {name=>1, artist=>0, album=>1},
      #   {name=>'', artist=>'deSc', album=>''} )

  # Output a "column direction" array.
  @columns = SQL::OrderBy::col_dir_list(
      \@column_names, \%direction
  );  # ('name', 'artist desc', 'album')

=head1 DESCRIPTION

This package simply transforms an SQL "order by" clause by moving or
adding column names and toggling their ascending/descending state.

=head1 PRIMARY FUNCTIONS

=head2 toggle_resort

  @columns = toggle_resort(
      order_by => $order_clause_or_list,
      selected => $column_name,
      show_ascending    => $w,
      uc_direction      => $x,
      name_direction    => $y,
      numeric_direction => $z,
  );

  $columns = toggle_resort(
      order_by => $order_clause_or_list,
      selected => $column_name,
      show_ascending => $w,
      uc_direction   => $x,
  )

This function implements a simple but essential feature of GUI database
environments, where the user interacts with a database table by sorting
and resorting via "toggled" column headings during search refinement.

In this, the selected column name is moved (or added) to the beginning
of the clause.  If this column was the first in the original clause,
its sort direction is flipped between ascending (asc) and descending
(desc).

This function takes a required SQL "order by" clause that can be
provided as either a string or an array reference, and a "selected"
column name.  If no selected column is provided, no "toggling" or
moving is done.

In a scalar context, this function returns the clause as a comma
separated string.  In an array context, this function returns a list
of column names with their respective sort directions.

These optional flags affect the format of the returned data structure
and are all off by default.

  Expose the ascending column directions.
  show_ascending => 0

  Render any new alpha column direction in uppercase.
  uc_direction => 0

  Return references to the column names and their directions.
  (only makes sense in an array context)
  name_direction => 0

  Return Boolean column directions, instead of asc/desc.
  (only makes sense if the name_direction flag is on)
  numeric_direction => 0

=head1 CONVENIENCE FUNCTIONS

=head2 get_columns

  @columns = get_columns (
      order_by => $order_clause_or_list,
      # Optional arguments:
      show_ascending    => $w,
      uc_direction      => $x,
      name_direction    => $y,
      numeric_direction => $z,
  );

  $columns = get_columns (
      order_by => $order_clause_or_list,
      # Optional arguments:
      show_ascending => $w,
      uc_direction   => $x,
  );

This function simply returns a well formed order by clause or list.
It can accept either a string or array reference for the order_by
argument.

In a scalar context, this function returns the clause as a (CSV)
string.  In an array context, this function returns a list of column
names with their respective sort directions as numeric hash and a
hash of the exact sort directions passed in.

* The optional arguments are described in the toggle_resort function
documentation, above.

=head2 col_dir_list

  @columns = col_dir_list (\@columns, \%direction);

Return an array of column names with their respective directions
concatinated.

This function takes a reference to an array of column names and a
reference to a direction hash.

=head2 to_asc_desc

  %direction = to_asc_desc (
      \%direction,
      # Optional arguments:
      show_ascending => $w,
      uc_direction   => $x,
  )

Return column directions as alpha keywords in place of their numeric
eqivalents.

If the direction hash contains any alpha (asc/desc) values, the
function uses those by default.

* The optional arguments are described in the toggle_resort function
documentation, above.

=head1 DEPENDENCIES

None.

=head1 EXPORTS

None, Nothing, Nada.

=head1 TO DO

Add functions for different kinds of resorting.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
