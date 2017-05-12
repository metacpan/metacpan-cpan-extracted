package RWDE::DB::Items;

use strict;
use warnings;

use Error qw(:try);

use RWDE::AbstractFactory;
use RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

=pod

=head2 fetch

routine to fetch object data using a custom query
This function uses dynamic run time determination of class types, fields. 

=cut

sub fetch {
  my ($self, $params) = @_;

  # dynamically pull in the name of the table where our object is mapped
  my $table = $self->get_static({ value => '_table' });

  my @fieldnames = @{ $self->get_static({ value => '_fieldnames' }) };

  my ($where, $query_params) = $self->generate_where($params);

  my $ordering = $self->generate_ordering($params);

  local ($") = ",";    #";
  my $result = $self->issue_query(
    {
      complete_query => "SELECT @fieldnames FROM $table $where $ordering",
      query_params   => $query_params
    }
  );

  my @items;
  foreach my $row (@{$result}) {
    push(@items, $self->fill_new({ row => $row }));
  }

  return \@items;
}

sub fetch_by_id_set {
  my ($self, $params) = @_;

  $self->check_params({ required => ['id_set'], supplied => $params });

  return
    unless (@{ $$params{id_set} } > 0);

  # Use the supplied identity field
  # or get the default one for the object
  my $id = $$params{'id'};

  $id = $self->get_static({ value => '_id' })
    unless defined $id;

  my @ids = @{ $$params{id_set} };

  local ($") = ",";    #"
  my $query = " $id IN (@ids) ";

  if (defined $$params{query}) {
    $$params{query} = $$params{query} . ' AND ' . $query;
  }
  else {
    $$params{query} = $query;
  }

  #FIXME make sure we have a query_params hash -- is this necessary?
  $$params{query_params} = defined($$params{query_params}) ? $$params{query_params} : undef;

  return $self->fetch($params);
}

=head2 fetch_single

Get the single result from the database

=cut

sub fetch_single {
  my ($self, $params) = @_;

  my $select = $$params{select}
    or throw RWDE::DevelException({ info => 'No target specified for fetch_single' });

  my $table;
  try {
    $table = $self->get_static({ value => '_table' });
  }
  catch Error {

  };

  my ($where, $query_params) = $self->generate_where($params);

  my $ordering = $self->generate_ordering($params);

  my $complete_query;
  if (defined $table) {
    $complete_query = "SELECT $select FROM $table $where $ordering";
  }
  else {
    $complete_query = "SELECT $select";
  }

  my $result = $self->issue_query({ complete_query => $complete_query, query_params => $query_params, deny_update => 1 });

  return $$result[0][0];
}

sub fetch_ids {
  my ($self, $params) = @_;

  my (@ids, $table, $term);

  #use the supplied id or get the primary key
  my $id = $$params{'id'} ? $$params{'id'} : $self->get_static({ value => '_id' });

  # dynamically pull in the name of the table where our object is mapped
  $table = $self->get_static({ value => '_table' });

  my ($where, $query_params) = $self->generate_where($params);
  my $ordering = $self->generate_ordering($params);

  my $complete_query = "SELECT $id FROM $table $where $ordering";

  my $result = $self->issue_query({ complete_query => $complete_query, query_params => $query_params });

  foreach my $row (@{$result}) {
    push(@ids, shift @{$row});
  }

  return \@ids;
}

=pod
=head2 fetch_join($params)

This function uses dynamic run time determination of class types, fields. 
The first type passed is used for basis for join, the table it is joining with
has to have the id of the first one embedded. It creates associations via
identity fields. The objects need to have an accessor method for the 
associated type, so that it can work even if it is not populated through
the Items class. 

=cut

sub fetch_join {
  my ($self, $params) = @_;

  $self->check_params({ required => [ 'jointype', 'joinkey' ], supplied => $params });

  my ($fields,     @fieldnames,     $term,    $table,     $jointerm,      @queryfieldnames);
  my ($joinfields, @joinfieldnames, $joinkey, $jointable, $jointable_key, @queryjoinfieldnames);

  my @items;
  my $jointype = $$params{'jointype'};

  # dynamically require the object type we are going to try and use
  $term     = RWDE::AbstractFactory->instantiate({ class => $self });
  $jointerm = RWDE::AbstractFactory->instantiate({ class => $jointype });

  # dynamically pull in the name of the table where our object is mapped
  $table     = $term->{_table};
  $jointable = $jointerm->{_table};

  #typically both items will share the same name to join on
  $joinkey = $$params{joinkey};

  #special exceptions if the 2 items to be joined do not share the same key
  $jointable_key = $$params{jointable_key};

  # dynamically pull in the list of fieldnames we will be dealing with for that table
  @fieldnames     = @{ $term->{_fieldnames} };
  @joinfieldnames = @{ $jointerm->{_fieldnames} };

  @queryfieldnames     = @{ $term->{_fieldnames} };
  @queryjoinfieldnames = @{ $jointerm->{_fieldnames} };

  # expand out the list of potential fieldnames for a database query
  foreach my $f (@queryfieldnames) {
    $f = $table . "." . $f . " AS " . $f;
  }

  foreach my $f (@queryjoinfieldnames) {
    $f = $jointable . "." . $f . " AS " . $f;
  }

  $fields     .= join(',', @queryfieldnames);
  $joinfields .= join(',', @queryjoinfieldnames);

  my ($where, $query_params) = $self->generate_where($params);
  my $ordering = $self->generate_ordering($params);

  my $join_on = (defined($jointable_key)) ? "$table.$joinkey = $jointable.$jointable_key" : "$table.$joinkey = $jointable.$joinkey";
  my $complete_query = "SELECT $fields, $joinfields FROM $table JOIN $jointable ON ($join_on) $where $ordering";

  my $result = $self->issue_query({ complete_query => $complete_query, query_params => $query_params });

  foreach my $row (@{$result}) {
    my $item     = $self->fill_new({ row     => $row });
    my $joinitem = $jointype->fill_new({ row => $row });

    $item->{$jointype} = ($joinitem);
    push(@items, $item);
  }

  return \@items;
}

=pod
=head2 join_count_query($params)

=cut

sub join_count_query {
  my ($self, $params) = @_;

  $self->check_params({ required => [ 'jointype', 'joinkey' ], supplied => $params });

  my ($fields,     @fieldnames,     $term,    $table,     $jointerm,      @queryfieldnames);
  my ($joinfields, @joinfieldnames, $joinkey, $jointable, $jointable_key, @queryjoinfieldnames);

  my @items;

  # dynamically require the object type we are going to try and use
  $term     = RWDE::AbstractFactory->instantiate({ class => $self });
  $jointerm = RWDE::AbstractFactory->instantiate({ class => $$params{'jointype'} });

  # dynamically pull in the name of the table where our object is mapped
  $table     = $term->{_table};
  $jointable = $jointerm->{_table};

  $joinkey = $$params{joinkey};

  #special exceptions if the 2 items to be joined do not share the same key
  $jointable_key = $$params{jointable_key};

  my ($where, $query_params) = $self->generate_where($params);
  my $join_on        = (defined($jointable_key)) ? "$table.$joinkey = $jointable.$jointable_key" : "$table.$joinkey = $jointable.$joinkey";
  my $complete_query = "SELECT COUNT(*) FROM $table JOIN $jointable ON ($join_on) $where";
  my $result         = $self->issue_query({ complete_query => $complete_query, query_params => $query_params });

  return $$result[0][0];
}

=head2 count_query

routine to perform a count based on a custom query

=cut

sub count_query {
  my ($self, $params) = @_;

  if (!defined($$params{count})) {
   $$params{select} = 'COUNT(*)';
  }
  else {
   $$params{select} = 'COUNT('.$$params{count}.')';
  }

  # make sure that we don't accidentally pass in anything which would break the count query
  return $self->fetch_single({ query => $$params{query}, query_params => $$params{query_params}, select => $$params{select} });
}
                   
# Allow Record classes to optimize lookups: i.e. split tables
sub optimize_query{}

sub issue_query {
  my ($self, $params) = @_;

  $self->check_params({ required => ['complete_query'], supplied => $params });

  my $dbh = $self->get_dbh();

  my $query = $$params{complete_query};

  #if we are in a transaction (passively invoked by get_dbh) - then insert a "FOR UPDATE" for this call
  if (!$$params{deny_update} && (RWDE::DB::DbRegistry->has_transaction({ db => $self->get_db() }))) {
    $query .= ' FOR UPDATE';
  }                             

  $self->optimize_query({ query => \$query, query_params => $$params{query_params} });

  my $sth = $dbh->prepare($query)
    or throw RWDE::DevelException({ info => 'Failure to prepare query.' });

  if (defined($$params{query_params}) and scalar @{ $$params{query_params} } > 0) {
    $sth->execute(@{ $$params{query_params} })
      or throw RWDE::DevelException({ info => 'Failure to execute query:' . $dbh->errstr() });
  }
  else {
    $sth->execute()
      or throw RWDE::DevelException({ info => 'Failure to execute query:' . $dbh->errstr() });
  }

  return $sth->fetchall_arrayref;
}

sub fetch_count {
  my ($self, $params) = @_;

  my $terms_ref = $self->fetch($params);
  my $count     = $self->count_query($params);

  return ($terms_ref, $count);
}

sub fetch_join_count {
  my ($self, $params) = @_;

  my $result       = $self->fetch_join($params);
  my $result_count = $self->join_count_query($params);

  return ($result, $result_count);
}

# Return objects in a hash structure indexed by term's id
sub fetch_hash {
  my ($self, $params) = @_;

  my $term_hash = {};

  foreach my $term (@{ $self->fetch($params) }) {
    $$term_hash{ $term->get_id } = $term;
  }

  return $term_hash;
}

sub generate_ordering {
  my ($self, $params) = @_;

  my $ordering = '';

  # Handle paging if necessary
  if ($$params{order}) {
    $ordering .= " ORDER BY $$params{order} ";

    #ascending is the default unless this is declared
    if (defined($$params{ordering})) {
      $ordering .= $$params{ordering};
    }
  }

  if (defined $$params{startidx}) {
    my $startidx = $$params{startidx};
    $startidx = 0 if ($startidx < 0);
    $ordering .= " OFFSET $startidx ";
  }

  if (defined $$params{maxreturn}) {
    my $maxreturn = $$params{maxreturn};
    $maxreturn += 0;
    $maxreturn = 50 if ($maxreturn > 200 or $maxreturn < 1);
    $ordering .= " LIMIT $maxreturn ";
  }

  return $ordering;
}

sub generate_where {
  my ($self, $params) = @_;

  my $where = '';
  my @query_params;

  #either we have an SQL query passed with params
  if (defined($$params{query}) || defined $$params{query_params}) {
    $where = $$params{query};

    if (defined $$params{query_params}) {
      @query_params = @{ $$params{query_params} };
    }

  }

  #or we have a bunch of search_fields we should sift through
  #and generate a query
  elsif (defined($$params{search_fields})) {
    my @queryparts;    # parts for the "WHERE clause"

    foreach my $field (@{ $$params{search_fields} }) {
      next
        if not defined $$params{$field};

      if (ref $$params{$field} eq 'ARRAY') {

        #TODO add placeholders instead of explicit quoting
        push @queryparts, "$field IN ('" . join("','", @{ $$params{$field} }) . "')";
      }
      elsif ($field =~ m/^(.*)\_not/o) {
        push(@queryparts,   "$1 <> ?");
        push(@query_params, $$params{$field});
      }
      elsif ($field =~ m/^(.*)\_start/o) {
        push(@queryparts,   "$1 >= ?");
        push(@query_params, $$params{$field});
      }
      elsif ($field =~ m/^(.*)\_end/o) {
        push(@queryparts,   "$1 <= ?");
        push(@query_params, $$params{$field});
      }
      elsif ($$params{$field} =~ m/%/) {
        push(@queryparts,   "$field LIKE ?");
        push(@query_params, $$params{$field});
      }
      else {
        push(@queryparts,   "$field = ?");
        push(@query_params, $$params{$field});
      }
    }    #end foreach field

    if (scalar @queryparts > 0) {
      $where = join ' AND ', @queryparts;
    }
  }

  if (defined $where and $where ne '') {
    $where = " WHERE $where";
  }

  return ($where, \@query_params);
}

1;
