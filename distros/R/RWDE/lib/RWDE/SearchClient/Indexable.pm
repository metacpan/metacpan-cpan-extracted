package RWDE::SearchClient::Indexable;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Exceptions;
use RWDE::Search;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 509 $ =~ /(\d+)/;

=pod

=head2 add_to_index

Add the content defined in my derived to the remote searchable index

=cut

sub add_to_index {
  my ($self, $params) = @_;

  $self->_check_index();

  my $index_path;
  if (defined($$params{index_path})) {
    $index_path = $$params{index_path};
  }
  else {
    $index_path = $self->get_index_path();
  }

  my $index_data;

  # This try block exists because errors/exceptions are behaving VERY strange here. 
  # Try using an error statement in this method!
  try {
    $index_data = $self->get_index_hash();
  }

  catch Error with {
    my $ex = shift;

   $self->syslog_msg('info', "$ex");
   $self->syslog_msg('info', "You likely have attempted to add an invalid class term to a class index.");
    $ex->throw();
  };

  RWDE::Search->index_document(
    {
      index_fields => $self->get_index_fields(),
      index_path   => $index_path,
      index_data   => $index_data
    }
  );

  return ();
}


sub optimize_index {
  my ($self, $params) = @_;
  
  # dynamically require the object type we are going to try and use
  my $term = RWDE::AbstractFactory->instantiate({ class => $self });

  $term->_check_index();

  my $index_path;
  if (defined($$params{index_path})) {
    $index_path = $$params{index_path};
  }
  else {
    $index_path = $term->get_index_path();
  }

  RWDE::Search->optimize_index(
    {
      index_path   => $index_path,
      index_fields => $term->get_index_fields(),
    }
  );

  return ();
}


# Delete the defined index_item from the remote searchable index.

sub delete_from_index {
  my ($self, $params) = @_;

  $self->_check_index();

  throw RWDE::DataNotFoundException({ info => "Item to delete from search index was not specified." })
    unless defined $$params{item_id};

  my $index_path;

  if (defined($$params{index_path})) {
    $index_path = $$params{index_path};
  }

  else {
    $index_path = $self->get_index_path();
  }

  RWDE::Search->delete_document(
    {
      index_path => $index_path,
      index_fields => $self->get_index_fields(),
      item_id   => $$params{item_id} # "primary key" to delete from the search index
    }
  );

  return ();
}


# search for content in the index
sub search_index {
  my ($self, $params) = @_;

  # create the object type we are going to use to 
  # get the static data through polymorphism
  my $term = RWDE::AbstractFactory->instantiate({ class => $self });

  $term->_check_index();

  throw RWDE::DataNotFoundException({ info => "No items matched your query" })
    unless defined $$params{query} || defined $$params{query_text};

  my ($docs, $total) = @{RWDE::Search->search_index(
      {
        maxreturn  => $$params{maxreturn},
        startidx   => $$params{startidx},
        query      => $$params{query},
        query_text => $$params{query_text},
        category   => $$params{category},
        index_path => $$params{index_path},
        index_fields => $term->get_index_fields()
      }
    )};

  unless (ref $docs eq 'ARRAY') {
    throw RWDE::DataBadException({ info => "Searching is temporarily unavailable, please try again later." });
  }

  throw RWDE::DataNotFoundException({ info => "No items matched your query" })
    unless (scalar @{$docs} > 0);

  return ($docs, $total);
}

=pod

=head2 get_index_hash

Return back the hash defined by the object as targets for indexing 
specified in an object for indexing as .

=cut

sub get_index_hash {
  my ($self, $params) = @_;

  my $field_values;

  foreach my $key (keys %{ $self->get_index_fields() }) {
    $$field_values{$key} = $self->$key;
  }

  return $field_values;
}

sub get_index_fields {
  my ($self, $number) = @_;

  $self->check_object();  

  return $self->{_index_fields};
}

#Determine if a class supports indexing or not. Private method.

sub _check_index {
  my ($self, $params) = @_;

  my $class = ref $self || $self;

  if (not defined $self->get_index_fields()) {
    throw RWDE::DevelException({ info => "Class $class doesn't support indexing" });
  }

  return ();
}

sub get_index_table {
  my ($self, $number) = @_;
  
  return $self->{_table};
}

sub get_index_divide {
  my ($self, $number) = @_;
  
  return $self->{_index_divide};
}


1;
