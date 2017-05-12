package Rose::DB::Object::Metadata::ColumnList;

use strict;

use Rose::DB::Object::Metadata::Object;
our @ISA = qw(Rose::DB::Object::Metadata::Object);

our $VERSION = '0.02';

use overload
(
  '""' => sub 
  {
    my($self) = shift; 
    return join($", map { "$_" } @{$self->{'columns'} ||= $self->auto_init_columns});
  },
  fallback => 1,
);

sub columns
{
  my($self) = shift;

  my $meta = $self->parent;

  if(@_)
  {
    # Force stringification in case they're column objects
    # instead of just column names.
    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      $self->{'columns'} = [ map { "$_" } @{$_[0]} ];
    }
    else
    {
      $self->{'columns'} = [ map { "$_" } @_ ];
    }
  }

  return  unless(defined wantarray);

  unless($meta)
  {
    return wantarray ? @{$self->{'columns'} ||= []} :  ($self->{'columns'} ||= []);
  }

  unless(@{$self->{'columns'} ||= []})
  {
    $self->{'columns'} = $self->auto_init_columns;
  }

  # Expand into columns on return
  return wantarray ?  map { $meta->column($_) || $_ } @{$self->{'columns'} ||= []} : 
                    [ map { $meta->column($_) || $_ } @{$self->{'columns'} ||= []} ];
}

sub auto_init_columns { [] }

sub column_names
{
  my($self) = shift;

  if(@{$self->{'columns'} ||= []})
  {
    return wantarray ? @{$self->{'columns'}} : $self->{'columns'};
  }

  # This call with auto-init the columns if necessary
  my $columns = $self->columns; 

  return wantarray ? @$columns : $columns;
}

sub add_columns
{
  my($self) = shift;

  if(@_ == 1 && ref $_[0] eq 'ARRAY')
  {
    push @{$self->{'columns'}}, map { "$_" } @{$_[0]};
  }
  else
  {
    push @{$self->{'columns'}}, map { "$_" } @_;
  }

  return;
}

*add_column = \&add_columns;

sub delete_columns
{
  shift->{'columns'} = [];
  return;
}

1;
