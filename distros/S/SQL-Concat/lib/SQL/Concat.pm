package SQL::Concat;
use 5.010;
use strict;
use warnings;
use Carp;

our $VERSION = "0.001";

use MOP4Import::Base::Configure -as_base
  , [fields => qw/sql bind/
     , [sep => default => ' ']]
  ;
use MOP4Import::Util qw/lexpand terse_dump/;

sub SQL {
  MY->new(sep => ' ')->concat(@_);
}

sub PAR {
  SQL(@_)->paren;
}

# Useful for OPT("limit ?", $limit, OPT("offset ?", $offset))
sub OPT {
  my ($expr, $value, @rest) = @_;
  return unless defined $value;
  SQL([$expr, $value], @rest);
}

sub PFX {
  my ($prefix, @items) = @_;
  return unless @items;
  my @non_empty = _nonempty(@items)
    or return;
  SQL($prefix => @non_empty);
}

sub _nonempty {
  grep {
    my MY $item = $_;
    if (not defined $item
        or not ref $item and $item !~ /\S/) {
      ();
    } elsif ($item->{sql} !~ /\S/) {
      ();
    } else {
      $item;
    }
  } @_;
}

# sub SELECT {
#   MY->new(sep => ' ')->concat(SELECT => @_);
# }

sub CAT {
  MY->concat_by(_wrap_ws($_[0]), @_[1..$#_]);
}

sub CSV {
  MY->concat_by(', ', @_);
}

sub _wrap_ws {
  my ($str) = @_;
  $str =~ s/^(\S)/ $1/;
  $str =~ s/(\S)\z/$1 /;
  $str;
}

# XXX: Do you want deep copy?
sub clone {
  (my MY $item) = @_;
  MY->new(%$item)
}

sub paren {
  shift->format_by('(%s)');
}

sub format_by {
  (my MY $item, my $fmt) = @_;
  my MY $clone = $item->clone;
  $clone->{sql} = sprintf($fmt, $item->{sql});
  $clone;
}

sub concat_by {
  my MY $self = ref $_[0]
    ? shift->configure(sep => shift)
    : shift->new(sep => shift);
  $self->concat(@_);
}

sub concat {
  my MY $self = ref $_[0] ? shift : shift->new;
  if (defined $self->{sql}) {
    croak "concat() called after concat!";
  }
  my @sql;
  $self->{bind} = [];
  foreach my MY $item (@_) {
    next unless defined $item;
    if (not ref $item) {
      push @sql, $item;
    } else {

      $item = $self->of_bind_array($item)
        if ref $item eq 'ARRAY';

      $item->validate_placeholders;

      push @sql, $item->{sql};
      push @{$self->{bind}}, @{$item->{bind}};
    }
  }
  $self->{sql} = join($self->{sep}, @sql);
  $self
}

sub of_bind_array {
  (my MY $self, my $bind_array) = @_;
  my ($s, @b) = @$bind_array;
  $self->new(sql => $s, bind => \@b);
}

sub validate_placeholders {
  (my MY $self) = @_;

  my $nbinds = $self->{bind} ? @{$self->{bind}} : 0;

  unless ($self->count_placeholders == $nbinds) {
    croak "SQL Placeholder mismatch! sql='$self->{sql}' bind="
      .terse_dump($self->{bind});
  }

  $self;
}

sub count_placeholders {
  (my MY $self) = @_;

  unless (defined $self->{sql}) {
    croak "Undefined SQL Fragment!";
  }

  $self->{sql} =~ tr,?,?,;
}

sub as_sql_bind {
  (my MY $self) = @_;
  if (wantarray) {
    ($self->{sql}, lexpand($self->{bind}));
  } else {
    [$self->{sql}, lexpand($self->{bind})];
  }
}

#========================================

sub BQ {
  if (ref $_[0]) {
    croak "Meaningless backtick for reference! ".terse_dump($_[0]);
  }
  if ($_[0] =~ /\`/) {
    croak "Can't quote by backtick: text contains backtick! $_[0]";
  }
  q{`}.$_[0].q{`}
}


sub _sample {

  my $name;

  SQL(select => "*" => from => table => );

  my $comp = SQL::Concat->new(sep => ' ')
    ->concat(SELECT => foo => FROM => 'bar');

  my $composed = SQL(SELECT => "*" =>
                     FROM   => entries =>
                     WHERE  => ("uid =" =>
                                PAR(SQL(SELECT => uid => FROM => authors =>
                                        WHERE => ["name = ?", $name])))
                   );

  my ($sql, @bind) = $composed->as_sql_bind;
}

1;


