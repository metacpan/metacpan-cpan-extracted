package TUI::Views::CommandSet;
# ABSTRACT: A class for managing command sets

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCommandSet
  new_TCommandSet
);

use TUI::toolkit qw(
  :boolean
  :utils
);
use TUI::toolkit::Types qw(
  :is
  :types
);

sub TCommandSet() { __PACKAGE__ }
sub new_TCommandSet { __PACKAGE__->from(@_) }

my $loc = sub {    # $int ($cmd)
  assert ( @_ == 1 );
  assert ( is_PositiveOrZeroInt $_[0] );
  int( $_[0] / 8 ) % 32;
};

my $mask = sub {    # $int ($cmd)
  assert ( @_ == 1 );
  assert ( is_PositiveOrZeroInt $_[0] );
  1 << ( $_[0] % 8 );
};

my $disable_cmd = sub {    # void ($cmd)
  my ( $self, $cmd ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $cmd );
  $self->[ &$loc( $cmd ) ] &= ~ &$mask( $cmd );
  return;
};

my $enable_cmd = sub {    # void ($cmd)
  my ( $self, $cmd ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $cmd );
  $self->[ &$loc( $cmd ) ] |= &$mask( $cmd );
  return;
};

my $disable_cmd_set = sub {    # void ($tc)
  my ( $self, $tc ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $tc );
  $self->[$_] &= ~$tc->[$_] for 0 .. 31;
  return;
};

my $enable_cmd_set = sub {    # void ($tc)
  my ( $self, $tc ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $tc );
  $self->[$_] |= $tc->[$_] for 0 .. 31;
  return;
};

sub new {    # $obj (%args)
  state $sig = signature(
    method => 1,
    named => [
      copy_from => Object, { optional => 1 }
    ],
  );
  my ( $class, $args ) = $sig->( @_ );
  my $self = bless [ ( 0 ) x 32 ], $class;
  @$self = @{ $args->{copy_from} }
    if exists $args->{copy_from};
  return $self;
}

sub from {    # $obj (|$tc)
  state $sig = signature(
    method => 1,
    pos    => [ Object, { optional => 1 } ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( copy_from => $args[0] );
  }
  return;
}

sub clone {    # $clone ()
  state $sig = signature(
    method => 1,
    pos => [],
  );
  my ( $self ) = $sig->( @_ );
  my @data = @$self;
  return bless [ @data ], ref $self;
}

sub has {    # $bool ($cmd)
  state $sig = signature(
    method => Object,
    pos => [PositiveOrZeroInt],
  );
  my ( $self, $cmd ) = $sig->( @_ );
  return ( $self->[ &$loc( $cmd ) ] & &$mask( $cmd ) ) != 0;
}

sub disableCmd {    # void ($cmd|$tc)
  state $sig = signature(
    method => Object,
    pos => [Defined],
  );
  my ( $self, $arg ) = $sig->( @_ );
  ref $arg
    ? goto &$disable_cmd_set
    : goto &$disable_cmd;
}

sub enableCmd {    # void ($cmd|$tc)
  state $sig = signature(
    method => Object,
    pos => [Defined],
  );
  my ( $self, $arg ) = $sig->( @_ );
  ref $arg
    ? goto &$enable_cmd_set
    : goto &$enable_cmd;
}

sub isEmpty {    # $bool ()
  state $sig = signature(
    method => Object,
    pos => [],
  );
  my ( $self ) = $sig->( @_ );
  for ( 0 .. 31 ) {
    return false if $self->[$_] != 0;
  }
  return true;
}

sub intersect {    # $tc ($tc1, $tc2, |$wap)
  state $sig = signature(
    pos => [Object, Object, Bool, { optional => 1 }],
  );
  my ( $tc1, $tc2, $swap ) = $sig->( @_ );
  ( $tc1, $tc2 ) = ( $tc2, $tc1 ) if $swap;
  my $temp = $tc1->clone();
  $temp->intersect_assign( $tc2 );
  return $temp;
}

sub union {    # $tc ($tc1, $tc2, |$wap)
  state $sig = signature(
    pos => [Object, Object, Bool, { optional => 1 }],
  );
  my ( $tc1, $tc2, $swap ) = $sig->( @_ );
  ( $tc1, $tc2 ) = ( $tc2, $tc1 ) if $swap;
  my $temp = $tc1->clone();
  $temp->union_assign( $tc2 );
  return $temp;
}

sub equal {    # $bool ($tc1, $tc2, |$wap)
  state $sig = signature(
    pos => [Object, Object, Bool, { optional => 1 }],
  );
  my ( $tc1, $tc2, $swap ) = $sig->( @_ );
  for ( 0 .. 31 ) {
    return false if $tc1->[$_] != $tc2->[$_];
  }
  return true;
}

sub not_equal {    # $bool ($tc1, $tc2, |$wap)
  state $sig = signature(
    pos => [Object, Object, Bool, { optional => 1 }],
  );
  my ( $tc1, $tc2, $swap ) = $sig->( @_ );
  return !equal( $tc1, $tc2 );
}

sub include {    # $self ($cmd|$tc, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [Defined, Bool, { optional => 1 }],
  );
  my ( $self, $other, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->enableCmd( $other ); 
  return $self;
}

sub exclude {    # $self ($cmd|$tc, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [Defined, Bool, { optional => 1 }],
  );
  my ( $self, $other, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->disableCmd( $other );
  return $self;
}

sub intersect_assign {    # $self ($tc, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [Object, Bool, { optional => 1 }],
  );
  my ( $self, $tc, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->[$_] &= $tc->[$_] for 0 .. 31;
  return $self;
}

sub union_assign {    # $self ($tc, |$wap)
  state $sig = signature(
    method => Object,
    pos    => [Object, Bool, { optional => 1 }],
  );
  my ( $self, $tc, $swap ) = $sig->( @_ );
  assert ( not $swap );
  $self->[$_] |= $tc->[$_] for 0 .. 31;
  return $self;
}

sub dump {    # $str ()
  state $sig = signature(
    method => Object,
    pos => [],
  );
  my ( $self ) = $sig->( @_ );
  my $dump = "$self=";
  $dump .= join ':' => map { sprintf("%02x", $self->[$_]) } 0 .. 31;
  $dump .= "\n";
  return $dump;
}

use overload
  '+=' => \&include,
  '-=' => \&exclude,
  '&=' => \&intersect_assign,
  '|=' => \&union_assign,
  '&'  => \&intersect,
  '|'  => \&union,
  '==' => \&equal,
  '!=' => \&not_equal,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TUI::Views::CommandSet - value type for managing sets of commands

=head1 HIERARCHY

  TCommandSet (value type)
    used by TView and derived classes

=head1 SYNOPSIS

  use TUI::Views;

  my $cmds = TCommandSet->new;

  $cmds->enableCmd(cmQuit);
  $cmds->disableCmd(cmDelete);

  if ($cmds->has(cmQuit)) {
    ...
  }

  my $other = TCommandSet->new;
  $other->enableCmd(cmCopy);

  my $union = $cmds | $other;
  my $inter = $cmds & $other;

=head1 DESCRIPTION

C<TCommandSet> represents a set of command identifiers. It is used throughout
TUI::Vision to enable, disable, and query commands associated with views.

This type is a lightweight value type and is not derived from C<TObject>.
Internally, a command set represents up to 256 commands, corresponding to the
range of commands that can be selectively enabled or disabled.

C<TCommandSet> supports set-style operations through Perl operator overloading,
allowing command sets to be combined, intersected, and compared using natural
expressions.

=head1 CONSTRUCTOR

=head2 new

  my $set = TCommandSet->new(
    copy_from => $other | undef
  );

Creates a new command set.

=over

=item copy_from

Optional command set to copy from.

=back

=head1 METHODS

=head2 clone

  my $copy = $set->clone();

Creates and returns a copy of the command set.

=head2 disableCmd

  $set->disableCmd($cmd | $other);

Disables a command or all commands contained in another command set.

=head2 enableCmd

  $set->enableCmd($cmd | $other);

Enables a command or all commands contained in another command set.

=head2 equal

  my $bool = $set->equal($a, $b);

Returns true if two command sets are equal.

Implements the C<==> operator.

=head2 exclude

  $set = $set->exclude($cmd | $other);

Removes a command or command set from the current set.

Implements the C<-=> operator.

=head2 has

  my $bool = $set->has($cmd);

Returns true if the specified command is contained in the set.

=head2 include

  $set = $set->include($cmd | $other);

Adds a command or command set to the current set.

Implements the C<+=> operator.

=head2 intersect

  my $set = $set->intersect($a, $b);

Returns the intersection of two command sets.

Implements the C<&> operator.

=head2 intersect_assign

  $set = $set->intersect_assign($other);

Assigns the intersection of another command set to the current set.

Implements the C<&=> operator.

=head2 isEmpty

  my $bool = $set->isEmpty();

Returns true if the command set contains no commands.

=head2 not_equal

  my $bool = $set->not_equal($a, $b);

Returns true if two command sets are not equal.

Implements the C<!=> operator.

=head2 union

  my $set = $set->union($a, $b);

Returns the union of two command sets.

Implements the C<|> operator.

=head2 union_assign

  $set = $set->union_assign($other);

Assigns the union of another command set to the current set.

Implements the C<|=> operator.

=head1 OPERATOR OVERLOADING

C<TCommandSet> supports set operations via Perl operator overloading.

=over

=item *

C<+=> - include commands

=item *

C<-=> - exclude commands

=item *

C<&>  - intersection

=item *

C<&=> - intersection assignment

=item *

C<|>  - union

=item *

C<|=> - union assignment

=item *

C<==> - equality comparison

=item *

C<!=> - inequality comparison

=back

=head1 SEE ALSO

L<TUI::Views::View>,
L<TUI::Drivers::Event>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
