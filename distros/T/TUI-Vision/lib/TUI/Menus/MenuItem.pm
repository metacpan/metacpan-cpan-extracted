package TUI::Menus::MenuItem;
# ABSTRACT: Class linking text, hot key, command, and help for use within a menu

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuItem
  newLine
  new_TMenuItem
);

use Carp ();
use Scalar::Util qw( looks_like_number );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Views::Const qw( hcNoContext );
use TUI::Views::View;

sub TMenuItem() { __PACKAGE__ }
sub new_TMenuItem { __PACKAGE__->from(@_) }

# public attributes
has next     => ( is => 'rw' );
has name     => ( is => 'rw', default => sub { die 'required' } );
has command  => ( is => 'rw', default => 0 );
has disabled => ( is => 'rw', default => false );
has keyCode  => ( is => 'rw', default => sub { die 'required' }  );
has helpCtx  => ( is => 'rw', default => hcNoContext );
has param    => ( is => 'rw', default => '' );
has subMenu  => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      name    => Str,               { alias => 'aName' },
      keyCode => PositiveOrZeroInt, { alias => 'aKeyCode' },
      command => PositiveOrZeroInt, { alias => 'aCommand', optional => 1 },
      subMenu => Maybe[Object],     { alias => 'aSubMenu', optional => 1 },
      helpCtx => PositiveOrZeroInt, { alias => 'aHelpCtx', optional => 1 },
      param   => Str,               { alias => 'p',        optional => 1 },
      next    => Maybe[Object],     { alias => 'aNext',    optional => 1 },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{disabled} = !TView->commandEnabled( $self->{command} );
  return;
}

sub from {    # $obj ($aName, |$aCommand, $aKeyCode, |$aSubMenu, $aHelpCtx, |$p, |$aNext)
  if ( looks_like_number $_[3] ) {
    state $sig = signature(
      method => 1,
      pos    => [
        Str,
        PositiveOrZeroInt,
        PositiveOrZeroInt,
        PositiveOrZeroInt, { default => hcNoContext },
        Str,               { default => '' },
        Maybe[Object],     { default => undef },
      ],
    );
    my ( $class, @args ) = $sig->( @_ );
    return $class->new( name => $args[0], command => $args[1], 
      keyCode => $args[2], helpCtx => $args[3], param => $args[4], 
        next => $args[6] );
  } 
  else {
    state $sig = signature(
      method => 1,
      pos    => [
        Str,
        PositiveOrZeroInt,
        Maybe[Object],
        PositiveOrZeroInt, { default => hcNoContext },
        Maybe[Object],     { default => undef },
      ],
    );
    my ( $class, @args ) = $sig->( @_ );
    return $class->new( name => $args[0], keyCode => $args[1], 
      subMenu => $args[2], helpCtx => $args[3], next => $args[4] );
  }
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  undef $self->{name};
  if ( $self->{command} == 0 ) {
    undef $self->{subMenu};
  }
  else {
    undef $self->{param};
  }
  return;
}

sub append {    # void ($aNext)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aNext ) = $sig->( @_ );
  $self->{next} = $aNext;
  return;
}

sub newLine () {    # $menuItem ()
  return TMenuItem->new(
    name    => '',
    command => 0,
    keyCode => 0,
    helpCtx => hcNoContext,
    param   => '',
    next    => undef,
  );
}

1

__END__

=pod

=head1 NAME

TUI::Menus::MenuItem - represents a single menu item or submenu entry

=head1 SYNOPSIS

  use TUI::Menus;

  # command item (generates a command)
  my $item =
    new_TMenuItem('~O~pen...', cmFileOpen, kbF3, hcNoContext, 'F3');

  # submenu item (opens a submenu)
  my $sub =
    new_TMenuItem('~F~ile', kbNoKey, $subMenu, hcNoContext);
  
  # chaining menu items
  my $menu =
      new_TMenuItem('~O~pen...', cmFileOpen, kbF3, hcNoContext, 'F3')
    + new_TMenuItem('E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X');

=head1 DESCRIPTION

C<TMenuItem> represents a single entry in a menu structure. Menu items are
linked together to form a list and are used by menu views such as
C<TMenuBar> and C<TMenuBox> to display selectable commands.

Each menu item may represent either a command entry or a submenu entry.
This is determined by whether the item contains a command or a submenu
reference.

Menu items are typically created using factory constructors and combined
using the overloaded C<+> operator to form complete menu structures.

=head1 ATTRIBUTES

The following attributes describe the state of a menu item.

=over

=item name

Text displayed for the menu item (I<Str>).  
Marked characters may be used to define a hotkey.

=item command

Command identifier generated when the item is selected
(I<PositiveOrZeroInt>).

=item keyCode

Scan code of the hot key associated with the menu item
(I<PositiveOrZeroInt>).

=item disabled

Boolean flag indicating whether the item is disabled.

=item helpCtx

Help context identifier associated with the menu item
(I<PositiveOrZeroInt>).

=item param

Optional parameter string displayed next to the menu item, such as a shortcut
label (I<Str>).

=item subMenu

Optional submenu associated with this item (I<TMenu>).

=item next

Reference to the next menu item in the list (I<TMenuItem>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $item = TMenuItem->new(
    name    => $name,
    keyCode => $keyCode,
    command => $command,
    subMenu => $subMenu,
    helpCtx => $helpCtx,
    param   => $param,
    next    => $next
  );

Creates a new menu item.

=over

=item name

Text displayed for the menu item.

=item keyCode

Hot key scan code.

=item command

Command identifier. This parameter is optional for submenu entries.

=item subMenu

Optional submenu associated with this item.

=item helpCtx

Optional help context identifier.

=item param

Optional parameter string displayed next to the item.

=item next

Optional reference to the next menu item.

=back

=head2 new_TMenuItem

  my $item = new_TMenuItem(
    $name,
    $command,
    $keyCode,
    | $helpCtx,
    | $param,
    | $next
  );

  my $item = new_TMenuItem(
    $name,
    $keyCode,
    $subMenu,
    | $helpCtx,
    | $next
  );

Factory-style constructor for menu items.

This constructor supports two distinct forms, corresponding directly to the
original Turbo Vision constructors:

=over

=item *

Command item form: creates a selectable menu entry that generates a command
when activated.

=item *

Submenu item form: creates a menu entry that opens a submenu instead of
generating a command.

=back

The constructor automatically determines which form is used based on the
supplied arguments.

Menu items are typically combined using the overloaded C<+> operator to form
linked lists representing complete menu structures.

=head2 newLine

  my $item = newLine();

Creates a separator line entry for use in menus.

=head1 METHODS

=head2 append

  $item->append($next);

Appends another menu item to the end of the menu item chain.

=head1 EXAMPLE

The following example shows how command items and submenu items are combined
to build a menu structure.

  my $menu =
      new_TSubMenu('~F~ile', hcNoContext)
        + new_TMenuItem('~O~pen...', cmFileOpen, kbF3, hcNoContext, 'F3')
        + new_TMenuItem('~S~ave as...', cmFileSave, hcNoContext)
        + newLine
        + new_TMenuItem('E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X')
      + new_TSubMenu('~H~elp', hcNoContext)
        + new_TMenuItem('~A~bout', cmAbout, hcNoContext);

=head1 SEE ALSO

L<TUI::Menus::Menu>,
L<TUI::Menus::MenuBar>,
L<TUI::Menus::MenuBox>

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
