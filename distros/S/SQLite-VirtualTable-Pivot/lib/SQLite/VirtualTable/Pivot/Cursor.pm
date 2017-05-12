=head1 NAME

SQLite::VirtualTable::Pivot::Cursor - a cursor for a pivot table query

=head1 DESCRIPTION

Objects in this class represent cursors for queries on pivot tables.

They maintatin a statement handle corresponding to an unpivotted
query on the base table.   The pivotting operation is done one
row at a time, as data is returned; i.e. we order by the id, and
group on the fly.

It must be possible for multiple cursors to exist at once on the
same pivot table, in case it occurs more than once in a query.

=head1 SEE ALSO

L<SQLite::VirtualTable::Pivot>

=cut

package SQLite::VirtualTable::Pivot::Cursor;

use base 'Class::Accessor::Contextual';
use Data::Dumper;

# State variables (probably could be simplified)
__PACKAGE__->mk_accessors(qw| first last done row_id queued |);
__PACKAGE__->mk_accessors(qw| sth current_row               |);

# list of temp tables
__PACKAGE__->mk_accessors(qw| temp_tables                   |);

# the virtual table to whom we belong
__PACKAGE__->mk_accessors(qw| virtual_table                 |);

sub debug($)  { return unless $ENV{DEBUG}; print STDERR "# $_[0]\n"; }

sub reset {
    my $self = shift;
    $self->set( first       => 1  );
    $self->set( done        => 0  );
    $self->set( queued      => {} );
    $self->set( "last"      => 0  );
    $self->set( current_row => [] );
    $self->set( last_row    => [] );
    $self->set( temp_tables => [] );
    return $self;
}

sub get_next_row {
  my $self = shift;
  $self->{queued}      = {};
  $self->{last_row}    ||= [];
  $self->{current_row} ||= [];
  return if $self->done;
  $self->{row_id}++;
  $self->{done} = $self->{last};
  my $row      = $self->{current_row};
  my $last_row = $self->{last_row};
  my $queued   = $self->{queued};
  $self->{last} = 0;
  while ($self->first || $self->virtual_table->_row_values_are_equal($row->[0],$last_row->[0])) {
    $self->set( first => 0 );
    if (@$row) {
        $queued->{ $row->[1] } = $row->[2];
        $queued->{$self->virtual_table->pivot_row} = $row->[0];
    }
    @$last_row = @$row;
    $self->{last} = !( @$row = $self->sth->fetchrow_array );
    last if $self->{last};
  }
  my $dumped = Dumper($self->queued);
  $dumped =~ s/\n|\s//g;
  debug "called next, queued is now $dumped ";
  @$last_row = @$row;
}

sub column_value {
    my $self = shift;
    my $column_name = shift;
    debug "column $column_name: $self->{queued}->{$column_name}";
    return $self->queued->{$column_name};
}

1;


