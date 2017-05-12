package Rose::HTML::Form::Field::Group;

use strict;

use Carp();

# XXX: Can't use Scalar::Defer 0.11 (or possibly later) until some things
# XXX: are sorted out.  See: http://rt.cpan.org/Ticket/Display.html?id=31039
# XXX: Scalar::Defer 0.18 seems to work again.  Yay!
# XXX: ...but this whole approach is a bt too clever.
#use Scalar::Defer();

use Scalar::Util();
use Rose::HTML::Util();

use base 'Rose::HTML::Form::Field';

our $VERSION = '0.606';

our $Debug = undef;

use Rose::Object::MakeMethods::Generic
(
  scalar => [ qw(rows columns) ],

  'scalar --get_set_init' => 
  [
    qw(html_linebreak xhtml_linebreak) 
  ],

  boolean => [ 'linebreak' => { default => 1 } ],
);

sub init
{
  my($self) = shift;

  $self->{'items'}    = [];
  $self->{'values'}   = {};
  $self->{'labels'}   = {};
  $self->{'defaults'} = {};

  $self->SUPER::init(@_);
}

use constant HTML_LINEBREAK  => "<br>\n";
use constant XHTML_LINEBREAK => "<br />\n";

sub init_html_linebreak  { HTML_LINEBREAK  }
sub init_xhtml_linebreak { XHTML_LINEBREAK }

sub _item_class       { '' }
sub _item_group_class { '' }
sub _item_name        { 'item' }
sub _item_name_plural { 'items' }

sub children 
{
  Carp::croak "Cannot set children() for a pseudo-group ($_[0])"  if(@_ > 1);
  return wantarray ? () : [];
}

sub is_flat_group { 1 }

sub items
{
  my($self) = shift;

  if(@_)
  {
    $self->{'items'} = $self->_args_to_items({ localized => 0 }, @_);
    $self->label_items;
    $self->init_items;
  }

  return (wantarray) ? @{$self->{'items'} || []} : $self->{'items'};
}

sub visible_items
{
  my $items = shift->items or return;
  return wantarray ? (grep { !$_->hidden } @$items) : [ grep { !$_->hidden } @$items ];
}

sub show_all_items
{
  my($self) = shift;

  foreach my $item ($self->items)
  {
    $item->hidden(0);
  }
}

sub hide_all_items
{
  my($self) = shift;

  foreach my $item ($self->items)
  {
    $item->hidden(1);
  }
}

sub delete_item
{
  my($self, $value) = @_;

  my $delete_item = $self->item($value) or return;
  my $group_class = $self->_item_group_class;

  my $items = $self->items || [];

  my $i = 0;

  foreach my $item (@$items)
  {
    if($item->isa($group_class))
    {
      if(my $deleted = $item->delete_item($value))
      {
        return $deleted;
      }
    }

    last  if($item eq $delete_item);
    $i++;
  }

  return splice(@$items, $i, 1);
}

sub push_items { shift->add_items(@_) }
sub push_item  { shift->add_item(@_) }

sub pop_items
{
  my($self) = shift;

  my $items = $self->items || [];

  if(@_)
  {
    my $offset = $#$items - $_[0];
    return splice(@$items, $offset < 0 ? 0 : $offset)  
  }

  my @items = pop(@$items);
  $self->init_items  if(@items);
  return @items;
}

sub pop_item { shift->pop_items(@_) }

sub shift_items
{
  my($self) = shift;

  my $items = $self->items || [];

  my @items = @_ ? splice(@$items, 0, $_[0]) : shift(@$items);
  $self->init_items  if(@items);
  return @items;
}

sub shift_item { shift->shift_items(@_) }

sub unshift_items
{
  my($self) = shift;

  unshift(@{$self->{'items'}}, $self->_args_to_items({ localized => 0 }, @_));

  $self->init_items;
}

sub unshift_item { shift->unshift_items(@_) }

sub delete_items
{
  my($self) = shift;

  foreach my $arg (@_)
  {
    $self->delete_item($arg);
  }
}

sub delete_item_group
{
  my($self, $value) = @_;

  my $group_class = $self->_item_group_class;
  my $delete_item = UNIVERSAL::isa($value, $group_class) ? $value : ($self->item_group($value) or return);

  my $items = $self->items || [];

  my $i = 0;

  foreach my $item (@$items)
  {
    last  if($item eq $delete_item);

    if($item->isa($group_class))
    {
      if(my $deleted = $item->delete_item($value))
      {
        return $deleted;
      }
    }

    $i++;
  }

  return splice(@$items, $i, 1);
}

sub delete_item_groups
{
  my($self) = shift;

  foreach my $arg (@_)
  {
    $self->delete_item_group($arg);
  }
}

sub items_localized
{
  my($self) = shift;

  if(@_)
  {
    $self->{'items'} = $self->_args_to_items({ localized => 1 }, @_);
    $self->init_items;
  }

  return (wantarray) ? @{$self->{'items'}} : $self->{'items'};
}

sub items_html_attr
{
  my($self, $name) = (shift, shift);

  if(@_)
  {
    foreach my $item ($self->items)
    {
      $item->html_attr($name, @_);
    }

    return @_;
  }

  foreach my $item (@{[ $self->items ]})
  {
    return $item->html_attr($name);
  }

  return undef;
}

sub delete_items_html_attr
{
  my($self) = shift;

  foreach my $item ($self->items)
  {
    $item->delete_html_attr(@_);
  }
}

*fields           = \&items;
*fields_localized = \&items_localized;

sub _html_item { $_[1]->html_field }
sub _xhtml_item { $_[1]->xhtml_field }

sub _args_to_items
{
  my($self, $options) = (shift, shift);

  my(%labels, @choices, $items);

  my $class = $self->_item_class;
  my $group_class = $self->_item_group_class;
  my $label_method = $options->{'localized'} ? 'label_id' : 'label';

  if(@_ == 1 && ref $_[0] eq 'HASH')
  {
    %labels = %{$_[0]};
    @choices = sort keys %labels;
  }
  else
  {
    my $args;

    # XXX: Hack to allow a reference to an array of plain scalars
    # XXX: to be taken as a list of values.
    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      $args = $_[0];

      unless(grep { ref $_ } @$args)
      {
        $args = [ map { $_ => $_  } @$args ];
      }
    }
    else { $args = \@_ }

    while(@$args)
    {
      my $arg = shift(@$args);

      if(UNIVERSAL::isa($arg, $class) || UNIVERSAL::isa($arg, $group_class))
      {
        push(@$items, $arg);
      }
      elsif(!ref $arg)
      {
        my $item = $class->new(value => $arg);

        if(!ref $args->[0])
        {
          $item->$label_method(shift(@$args));
          push(@$items, $item);
        }
        elsif(ref $args->[0] eq 'HASH')
        {
          my $pairs = shift(@$args);

          while(my($method, $value) = each(%$pairs))
          {
            $item->$method($value);
          }

          push(@$items, $item);
        }
        elsif(ref $args->[0] eq 'ARRAY')
        {
          my $group = $group_class->new(label => $arg,
                                        items => shift @$args);
          push(@$items, $group);
        }
        else
        {
          Carp::croak "Illegal or incorrectly positioned ", $self->_item_name_plural,
                      " argument: $args->[0]";
        }

      }
      else
      {
        Carp::croak "Illegal or incorrectly positioned ", $self->_item_name_plural,
                    " argument: $args->[0]";
      }
    }
  }

  if(keys %labels)
  {
    my @items;

    my $class = $self->_item_class;

    foreach my $value (@choices)
    {
      push(@$items, $class->new(value         => $value, 
                                $label_method => $labels{$value}));
    }
  }

  foreach my $item (@$items)
  {
    # Connect item to group
    $item->parent_group($self)  if($item->can('parent_group'));

    # XXX: This whole approach is a bit too clever and leak-prone.

    # # Speculatively hook up localizer and locale
    # # XXX: Scalar::Defer 0.11 breaks this (http://rt.cpan.org/Ticket/Display.html?id=31039)
    # # XXX: Scalar::Defer 0.18 seems to work again.  Yay!
    # Scalar::Util::weaken(my $welf = $self);
    # $item->localizer(Scalar::Defer::defer { $welf->localizer });
    # #$item->localizer(sub { $welf->localizer });
    # 
    # # XXX: Use lame workaround instead.
    # #Scalar::Util::weaken(my $welf = $self);
    # #$item->localizer(sub { $welf->localizer });
    # 
    # if(my $parent = $self->parent_form)
    # {
    #   # XXX: Scalar::Defer 0.11 breaks this (http://rt.cpan.org/Ticket/Display.html?id=31039)
    #   # XXX: Scalar::Defer 0.18 seems to work again.  Yay!
    #   Scalar::Util::weaken(my $warent = $parent);
    #   $item->locale(Scalar::Defer::defer { $warent->locale });
    #   # XXX: Use lame workaround instead.
    #   #$item->locale(sub { $parent->locale });
    # }
  }

  return (wantarray) ? @$items : $items;
}

sub parent_field
{
  my($self) = shift; 

  if(@_)
  {
    if(my $parent = $self->SUPER::parent_field(@_))
    {
      foreach my $item ($self->items)
      {
        $item->parent_field($parent)  unless($item->parent_field);
      }
    }    
  }

  return $self->SUPER::parent_field;
}

# XXX: This whole approach is a bit too clever and leak-prone.
# sub parent_form
# {
#   my($self) = shift; 
# 
#   if(@_)
#   {
#     if(my $parent = $self->SUPER::parent_form(@_))
#     {
#       foreach my $item ($self->items)
#       {
#         # XXX: Scalar::Defer 0.11 breaks this (http://rt.cpan.org/Ticket/Display.html?id=31039)
#         # XXX: Scalar::Defer 0.18 seems to work again.  Yay!
#         Scalar::Util::weaken(my $warent = $parent);
#         $item->locale(Scalar::Defer::defer { $warent->locale });
#         # XXX: Use lame workaround instead.          
#         #$item->locale(sub { $parent->locale });
#       }
#     }
#   }
# 
#   return $self->SUPER::parent_form;
# }

sub add_items
{
  my($self) = shift;

  push(@{$self->{'items'}}, $self->_args_to_items({ localized => 0 }, @_));

  $self->init_items;
}

*add_item = \&add_items;

sub add_items_localized
{
  my($self) = shift;

  push(@{$self->{'items'}},  $self->_args_to_items({ localized => 1 }, @_));

  $self->init_items;
}

*add_item_localized = \&add_items_localized;

sub label_items
{
  my($self) = shift;

  my $labels    = $self->{'labels'} || {};
  my $label_ids = $self->{'label_ids'} || {};

  return  unless(%$labels || %$label_ids);

  foreach my $item ($self->items)
  {
    my $value = $item->html_attr('value');

    next  unless(defined $value);

    if(exists $label_ids->{$value})
    {
      $item->label_id($label_ids->{$value});
    }
    elsif(exists $labels->{$value})
    {
      $item->label($labels->{$value});
    }
  }
}

sub clear
{
  my($self) = shift;

  $self->{'values'} = undef;

  foreach my $item ($self->items)
  {
    local $item->{'auto_invalidate_parent'} = $self->auto_invalidate_parent;
    $item->clear;
  }

  $self->error(undef);
  $self->has_partial_value(0);
  $self->is_cleared(1);

  $self->init_items;
}

sub clear_labels
{
  my($self) = shift;

  delete $self->{'labels'};
  delete $self->{'label_ids'};

  foreach my $item ($self->items)
  {
    $item->label_id(undef);
    $item->label('');
  }

  return;
}

sub reset_labels
{
  my($self) = shift;

  delete $self->{'labels'};
  delete $self->{'label_ids'};

  foreach my $item ($self->items)
  {
    $item->label_id(undef);
    $item->label($item->value);
  }

  return;
}

sub reset
{
  my($self) = shift;

  $self->input_value(undef);

  foreach my $item ($self->items)
  {
    $item->reset;
  }

  $self->error(undef);
  $self->has_partial_value(0);
  $self->is_cleared(0);

  $self->init_items;
}

sub labels    { shift->_labels(0, @_) }
sub label_ids { shift->_labels(1, @_) }

sub _labels
{
  my($self, $localized) = (shift, shift);

  my $key = $localized ? 'label_ids' : 'labels';

  if(@_)
  {
    my %labels;

    if(@_ == 1 && ref $_[0] eq 'HASH')
    {
      $self->{$key} = $_[0];
    }
    else
    {
      Carp::croak "Odd number of items found in $key() hash argument"
        unless(@_ % 2 == 0);

      $self->{$key} = { @_ };
    }

    $self->label_items;
  }

  my $want = wantarray;

  return  unless(defined $want);

  my $group_class = $self->_item_group_class;

  my %labels;

  # Dumb linear search for now
  foreach my $item ($self->items)
  {
    if($item->isa($group_class))
    {
      foreach my $subitem ($item->items)
      {
        $labels{$subitem->html_attr('value')} = $subitem->label;
      }
    }
    else
    {
      $labels{$item->html_attr('value')} = $item->label;
    }
  }

  return $want ? %labels : \%labels;
}

# sub labels
# {
#   my($self) = shift;
# 
#   if(@_)
#   {
#     my %labels;
# 
#     if(@_ == 1 && ref $_[0] eq 'HASH')
#     {
#       $self->{'labels'} = $_[0];
#     }
#     else
#     {
#       Carp::croak "Odd number of items found in labels() hash argument"
#         unless(@_ % 2 == 0);
# 
#       $self->{'labels'} = { @_ };
#     }
# 
#     $self->label_items;
#   }
# 
#   my $want = wantarray;
# 
#   return  unless(defined $want);
# 
#   my $group_class = $self->_item_group_class;
# 
#   my %labels;
# 
#   # Dumb linear search for now
#   foreach my $item ($self->items)
#   {
#     if($item->isa($group_class))
#     {
#       foreach my $subitem ($item->items)
#       {
#         $labels{$subitem->html_attr('value')} = $subitem->label;
#       }
#     }
#     else
#     {
#       $labels{$item->html_attr('value')} = $item->label;
#     }
#   }
# 
#   return $want ? %labels : \%labels;
# }

sub html_field
{
  my($self) = shift;
  my $sep = ($self->linebreak) ? $self->html_linebreak : ' ';
  return join($sep, map { $_->html_field } $self->visible_items);
}

*html_fields = \&html_field;

sub xhtml_field
{
  my($self) = shift;
  my $sep = ($self->linebreak) ? $self->xhtml_linebreak : ' ';
  return join($sep, map { $_->xhtml_field } $self->visible_items);
}

*xhtml_fields = \&xhtml_field;

sub escape_html
{
  my($self) = shift;

  if(@_)
  {
    my $val = $self->SUPER::escape_html(@_);

    foreach my $item ($self->items)
    {
      $item->escape_html($val);
    }

    return $val;
  }

  return $self->SUPER::escape_html(@_);
}

sub hidden_fields
{
  my($self) = shift;

  my @hidden;

  foreach my $item ($self->items)
  {
    push(@hidden, $item->hidden_field)  if(defined $item->internal_value);
  }

  return (wantarray) ? @hidden : \@hidden;
}

# XXX: Could someday use Rose::HTML::Table::*

sub html_table
{
  my($self, %args) = @_;

  my $items = $args{'items'};

  return  unless(ref $items && @$items);

  my $xhtml = delete $args{'_xhtml'} || 0;
  my $format_item = $args{'format_item'} || ($xhtml ? \&_xhtml_item : \&_html_item);

  my $total = @$items;
  my $rows  = $args{'rows'}    || $self->rows    || 1;
  my $cols  = $args{'columns'} || $self->columns || 1;

  my $per_cell = $total / ($rows * $cols);

  if($total % ($rows * $cols))
  {
    $per_cell = int($per_cell + 1);
  }

  my @table;

  my $i = 0;

  for(my $x = 0; $x < $cols; $x++)
  {
    for(my $y = 0; $y < $rows; $y++)
    {
      my $end = $i + $per_cell - 1;
      $end = $#$items  if($end > $#$items);
      $table[$y][$x] = [ @$items[$i .. $end] ];
      $i += $per_cell;
    }
  }

  my $sep = ($self->linebreak) ? $xhtml ? $self->xhtml_linebreak : $self->html_linebreak : ' ';

  my $html = '<table' . Rose::HTML::Util::html_attrs_string($args{'table'}) . ">\n";

  my @tr_attrs = (ref $args{'tr'} eq 'ARRAY') ? @{$args{'tr'}} : ($args{'tr'});
  my @td_attrs = (ref $args{'td'} eq 'ARRAY') ? @{$args{'td'}} : ($args{'td'});

  my $tr = 0;

  foreach my $col (@table)
  {
    my $tr_attrs = $tr_attrs[$tr] || $tr_attrs[-1];

    $html .= '<tr' . Rose::HTML::Util::html_attrs_string($tr_attrs) . ">\n";

    my $td = 0;

    foreach my $row (@$col)
    {
      my $td_attrs = $td_attrs[$td] || $td_attrs[-1];

      $html .= '<td' . Rose::HTML::Util::html_attrs_string($td_attrs) . '>' .
               join($sep, map { $self->$format_item($_) } @$row) .
               "</td>\n";

      $td++;
    }

    $html .= "</tr>\n";
    $tr++;
  }

  $html .= "</table>\n";

  return $html;
}

*xhtml_table = \&html_table;

1;
