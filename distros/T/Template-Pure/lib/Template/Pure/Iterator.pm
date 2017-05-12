use warnings;
use strict;

package Template::Pure::Iterator;

## Please not everything here is internal code... it will likely change a 
## lot so please rely only on the public interface.

use Scalar::Util 'blessed';

sub from_proto {
  my ($class, $proto, $pure, $options) = @_;
  my $sort_cb = delete $options->{'sort'};
  my $grep_cb = delete $options->{'grep'};
  my $filter_cb = delete $options->{'filter'};

  #sorry about this mess but I don't have time for a total redo right now
  $options->{pure} = $pure;

  if(blessed $proto) {
    return $class->from_object($proto, $filter_cb, $grep_cb, $sort_cb, $options);
  } else {
    my $type = 'from_' .lc ref $proto;
    return $class->$type($proto, $filter_cb, $grep_cb, $sort_cb, $options);
  }
}

sub from_object {
  my ($class, $obj, $filter_cb, $grep_cb, $sort_cb, $options) = @_;
  my ($index, $current) = (0);
 
  if(
    (my $next = $obj->can('next')) &&
    (my $all = $obj->can('all')) &&
    (my $reset = $obj->can('reset')) &&
    (my $count = $obj->can('count'))
  ) {

    $obj = $filter_cb->($options->{pure}, $obj) if defined $filter_cb;
    $obj = $grep_cb->($options->{pure}, $obj) if defined $grep_cb;
    $obj = $sort_cb->($options->{pure}, $obj) if defined $sort_cb;

    return bless +{
      _index => sub { return $index },
      _current_value => sub { return $current },
      _max_index => sub { return $obj->$count - 1 },
      _count => sub { return $obj->$count },
      _next => sub {
        if(my $next = $obj->$next) {
          $current = $next;
          $index++;
          return \$next;
        } else {
          return undef;
        }
      },
      _reset => sub { $reset->($obj) },
      _all => sub { return $all->($obj) },
      _is_first => sub { return (($index - 1) == 0 ? 1:0) },
      _is_last => sub { return $index == $count->($obj) ? 1:0 },
      _is_even => sub { return $index % 2 ? 0:1 },
      _is_odd => sub { return $index % 2 ? 1:0 },
    }, $class;
  } else {
    my %hash;
    if(my $fields = $obj->can($options->{fields_method} ||'display_fields')) {
      %hash = map { $_ => $obj->$_ } ($fields->($obj));
    } else {
      %hash =  %{$obj};
    }

    return $class->from_hash(\%hash, $filter_cb, $grep_cb, $sort_cb, $options);
  }

}

sub from_hash {
  my ($class, $hashref, $filter_cb, $grep_cb, $sort_cb, $options) = @_;

  my %hash = defined $filter_cb ?
    map { $filter_cb->($options->{pure}, $_, $hashref->{$_}) } keys %{$hashref} :
      %{$hashref};
  
  my @keys = defined $grep_cb ?
    grep { $grep_cb->($options->{pure}, $_, $hash{$_}) ? $_ : undef } keys %hash : 
    keys %hash;

  if(defined $sort_cb) {
    @keys = sort { $sort_cb->($options->{pure},\%hash, $a, $b) } @keys;
  }

  my $index = 0;
  my $current;
  my $current_key = $keys[$index];
  return bless +{
    _index => sub { return $current_key },
    _current_value => sub { return $current },
    _max_index => sub { return undef; },
    _count => sub { return scalar @keys },
    _next => sub {
      return undef if $index > $#keys;
      $current_key = $keys[$index];
      my $value = $hash{$current_key};
      $index++;
      $current = $value;
      return \$value;
    },
    _reset => sub { $index = 0 },
    _all => sub { return %hash },
    _is_first => sub { return $index-1 == 0 ? 1:0 },
    _is_last => sub { return $index-1 == $#keys ? 1:0 },
    _is_even => sub { return $index % 2 ? 0:1 },
    _is_odd => sub { return $index % 2 ? 1:0 },
  }, $class;
}

sub from_array {
  my ($class, $arrayref, $filter_cb, $grep_cb, $sort_cb, $options) = @_;
  my @array = defined $filter_cb ?
    map { $filter_cb->($options->{pure}, $_) } @$arrayref :
      @$arrayref;

  if(defined $grep_cb) {
    @array = grep { $grep_cb->($options->{pure}, $_) ? $_ : undef } @array;
  }

  if(defined $sort_cb) {
    @array = sort { $sort_cb->($options->{pure}, $arrayref, $a, $b) } @array;
  }

  my $index = 0;
  my $current;
  return bless +{
    _index => sub { return $index },
    _current_value => sub { return $current },
    _max_index => sub { return $#array },
    _count => sub { return scalar @array },
    _next => sub {
      return undef if $index > $#array;
      my $value = $array[$index];
      $index++;
      $current = $value;
      return \$value;
    },
    _reset => sub { $index = 0 },
    _all => sub { return @array },
    _is_first => sub { return $index-1 == 0 ? 1:0 },
    _is_last => sub { return $index-1 == $#array ? 1:0 },
    _is_even => sub { return $index % 2 ? 0:1 },
    _is_odd => sub { return $index % 2 ? 1:0 },
  }, $class;
}

sub current_value {
  my ($self) = @_;
  return $self->{_current_value}->($self);
}

sub next {
  my ($self) = @_;
  return $self->{_next}->($self);
}

sub reset {
  my ($self) = @_;
  return $self->{_reset}->($self);
}

sub all {
  my ($self) = @_;
  return $self->{_all}->($self);
}

sub count {
  my ($self) = @_;
  return $self->{_count}->($self);
}

sub index {
  my ($self) = @_;
  return $self->{_index}->($self);
}

sub max_index {
  my ($self) = @_;
  return $self->{_max_index}->($self);
}

sub is_first { $_[0]->{_is_first}->($_[0]) }
sub is_last { $_[0]->{_is_last}->($_[0]) }
sub is_even { $_[0]->{_is_even}->($_[0]) }
sub is_odd { $_[0]->{_is_odd}->($_[0]) }

sub is_paged { }

sub pager { }

sub page { }

sub is_ordered { }

1;
