package Net::IPAddress::Util::Collection::Tie;

use strict;
use warnings;
use 5.012;

use Carp qw( confess );

require Net::IPAddress::Util;

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my ($arg_ref) = @_;
  return bless $arg_ref => $class;
}

sub TIEARRAY {
  my ($class, $contents) = @_;
  $contents = [] unless defined $contents;
  @{$contents} = map { _checktype($_) } @{$contents};
  my $self = $class->new({ contents => $contents });
}

sub FETCH {
  my ($self, $i) = @_;
  return $self->{ contents }->[ $i ];
}

sub STORE {
  my ($self, $i, $v) = @_;
  $self->{ contents }->[ $i ] = _checktype($v);
  return $v;
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{$self->{ contents }};
}

sub EXISTS {
  my ($self, $i) = @_;
  return exists $self->{ contents }->[ $i ];
}

sub DELETE {
  my ($self, $i) = @_;
  return delete $self->{ contents }->[ $i ];
}

sub CLEAR {
  my ($self) = @_;
  $self->{ contents } = [ ];
  return $self->{ contents };
}

sub PUSH {
  my ($self, @l) = @_;
  push @{$self->{ contents }}, map { _checktype($_) } @l;
}

sub POP {
  my ($self) = @_;
  return pop @{$self->{ contents }};
}

sub UNSHIFT {
  my ($self, @l) = @_;
  unshift @{$self->{ contents }}, map { _checktype($_) } @l;
}

sub SHIFT {
  my ($self) = @_;
  return shift @{$self->{ contents }};
}

sub SPLICE {
  my ($self, $offset, $length, @l) = @_;
  $offset = 0 unless defined $offset;
  $length = $self->FETCHSIZE() - $offset unless defined $length;
  return splice @{$self->{ contents }}, $offset, $length, map { _checktype($_) } @l;
}

sub _checktype {
  my ($v) = @_;
  return $v if ref($v) eq 'Net::IPAddress::Util::Range';
  if (ref($v) eq 'HASH') {
    eval { $v = Net::IPAddress::Util::Range->new($v) };
  }
  if (!ref($v) or ref($v) eq 'ARRAY') {
    eval { $v = Net::IPAddress::Util->new($v) };
  }
  if (ref($v) eq 'Net::IPAddress::Util') {
    $v = Net::IPAddress::Util::Range->new({ ip => $v });
  }
  if (!defined($v) or ref($v) ne 'Net::IPAddress::Util::Range') {
    my $disp = defined($v) ? (ref($v) || 'bare scalar') : 'undef()';
    confess("Invalid data type ($disp)");
  }
  return $v;
}

1;

__END__

=head1 NAME

Net::IPAddress::Util::Collection::Tie - These aren't the droids you're looking for

=head1 METHODS

=over

=item new

No, seriously. You should not be poking around back here. You are likely to be eaten by a grue.

=back

=cut
