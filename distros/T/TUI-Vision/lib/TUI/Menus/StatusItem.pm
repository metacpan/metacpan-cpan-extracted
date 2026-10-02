package TUI::Menus::StatusItem;
# ABSTRACT: Class linking text, hot key, and command for use on a status line 

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusItem
  new_TStatusItem
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TStatusItem() { __PACKAGE__ }
sub new_TStatusItem { __PACKAGE__->from(@_) }

# public attributes
has next    => ( is => 'rw' );
has text    => ( is => 'rw', default => sub { die 'required' } );
has keyCode => ( is => 'rw', default => sub { die 'required' } );
has command => ( is => 'rw', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      text    => Str,               { alias   => 'aText' },
      keyCode => PositiveOrZeroInt, { alias   => 'key' },
      command => PositiveOrZeroInt, { alias   => 'cmd' },
      next    => Maybe[Object],     { default => undef },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aText, $key, $cmd, |$aNext)
  state $sig = signature(
    method => 1,
    pos => [
      Str,
      PositiveOrZeroInt,
      PositiveOrZeroInt,
      Maybe[Object], { default => undef },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( text => $args[0], keyCode => $args[1], 
    command => $args[2], next => $args[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  undef $self->{text};
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Menus::StatusItem - status line item for status line definitions

=head1 SYNOPSIS

  use TUI::Menus;

  my $item = new_TStatusItem(
    '~Alt+X~ Exit',
    kbAltX,
    cmQuit
  );

=head1 DESCRIPTION

C<TStatusItem> represents a single entry displayed on a L<TUI::Vision> status
line. Each item associates a text label with a keyboard shortcut and a command
identifier that is sent when the item is activated.

Status items are typically linked together to form a list and are referenced by
a L<TStatusDef|TUI::Menus::StatusDef> object. The status line displays the 
items belonging to the definition whose help context range matches the current 
application state.

This class is primarily used internally by the menu and status line
infrastructure and is rarely manipulated directly by application code.

=head1 ATTRIBUTES

The following attributes describe the status line item.

=head2 text

Text label displayed on the status line (I<Str>).

=head2 keyCode

Scan code of the hot key associated with the item (I<PositiveOrZeroInt>).

=head2 command

Command identifier generated when the item is selected
(I<PositiveOrZeroInt>, typically a C<cmXXXX> constant).

=head2 next

Optional reference to the next status line 
(L<TStatusItem|TUI::Menus::StatusItem>) in the item list.

=head1 CONSTRUCTOR

=head2 new

  my $item = TStatusItem->new(
    text    => $text,
    keyCode => $key,
    command => $command,
    next    => $next | undef
  );

Creates a new status line item.

=over

=item text

Text label of the item (I<Str>).

=item keyCode

Hot key scan code (I<PositiveOrZeroInt>).

=item command

Command identifier (I<PositiveOrZeroInt>).

=item next

Optional reference to the next status line item (I<TStatusItem> or undef).

=back

=head2 new_TStatusItem

  my $item = new_TStatusItem($text, $key, $command, | $next);

Factory-style constructor using positional arguments.

The $next parameter is optional and may be omitted entirely. This constructor
is provided for compatibility with traditional I<Turbo Vision> construction
patterns.

=head1 SEE ALSO

L<TStatusDef|TUI::Menus::StatusDef>, 
L<TStatusLine|TUI::Menus::StatusLine>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
