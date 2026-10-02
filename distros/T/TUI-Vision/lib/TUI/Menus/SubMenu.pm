package TUI::Menus::SubMenu;
# ABSTRACT: Class for a submenu off a menu bar or menu box 

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSubMenu
  new_TSubMenu
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Views::Const qw( hcNoContext );
use TUI::Menus::Menu;
use TUI::Menus::MenuItem;

sub TSubMenu() { __PACKAGE__ }
sub new_TSubMenu { __PACKAGE__->from(@_) }

extends TMenuItem;

# predeclare private methods
my (
  $add_menu_item,
  $add_sub_menu,
);

sub from {    # $obj ($nm, $key, |$helpCtx)
  state $sig = signature(
    method => 1,
    pos    => [
      Str,
      PositiveOrZeroInt,
      PositiveOrZeroInt, { default => hcNoContext },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( name => $args[0], keyCode => $args[1], 
    helpCtx => $args[2] );
}

sub _add_menu_item { goto &$add_menu_item }
$add_menu_item = sub {    # $s ($s, $i, |undef)
  my ( $s, $i ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s );
  assert ( is_Object $i and $i->isa( TMenuItem ) );
  my $sub = $s;
  $sub = $sub->{next}
    while $sub->{next};

  if ( !$sub->{subMenu} ) {
    $sub->{subMenu} = TMenu->new( items => $i );
  }
  else {
    my $cur = $sub->{subMenu}{items};
    $cur = $cur->{next}
      while $cur->{next};
    $cur->{next} = $i;
  }
  return $s;
};

sub _add_sub_menu { goto &$add_sub_menu }
$add_sub_menu = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TSubMenu ) );
  my $cur = $s1;
  $cur = $cur->{next}
    while $cur->{next};
  $cur->{next} = $s2;
  return $s1;
};

sub add {    # $s ($s1, $s2|$i, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $s1, $s2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  $s2->isa( TSubMenu )
    ? goto &$add_sub_menu
    : goto &$add_menu_item
}

use overload
  '+' => \&add,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TUI::Menus::SubMenu - submenu item for menu bars and menu boxes

=head1 HIERARCHY

  TObject
    TMenuItem
      TSubMenu

=head1 SYNOPSIS

  use TUI::Menus;

  my $submenu =
    new_TSubMenu('~F~ile', kbAltF)
      + new_TMenuItem('~O~pen', cmOpen)
      + new_TMenuItem('~S~ave', cmSave)
      + newLine
      + new_TMenuItem('E~x~it', cmQuit);

=head1 DESCRIPTION

C<TSubMenu> represents a submenu entry that can be attached to a menu bar or
menu box. It is a specialized form of L<TMenuItem|TUI::Menus::MenuItem> that 
owns a list of child menu items.

Submenus are typically constructed using operator chaining, allowing menu
structures to be built declaratively.

=head1 CONSTRUCTOR

This class does not define its own construction parameters and relies on the
standard L<TMenuItem|TUI::Menus::MenuItem> initialization.

=head2 new

  my $item = TSubMenu->new(
    name    => $name,
    command => $command,
    subMenu => $subMenu,
    # optional ..
    (
      helpCtx => $helpCtx,
      next    => $next,
    )
  );

Creates a new submenu item.

=over

=item name

Text displayed for the menu item (I<Str>).

=item command

Command identifier (I<PositiveOrZeroInt>). This parameter is optional for 
submenu entries.

=item subMenu

Optional submenu associated with this item (I<Object>).

=item helpCtx

Optional help context identifier (I<PositiveOrZeroInt>).

=item next

Optional reference to the next menu item (I<Object>).

=back

=head2 new_TSubMenu

  my $submenu = new_TSubMenu($name, $key, $helpCtx = hcNoContext);

Creates a new submenu item.

=over

=item name

The displayed submenu name, usually containing a hotkey marker (I<Str>).

=item key

Keyboard shortcut associated with the submenu (I<PositiveOrZeroInt>).

=item helpCtx

Optional help context identifier (I<PositiveOrZeroInt>).

=back

=head1 METHODS

=head2 add

  my $submenu = $submenu->add($item | $submenu, | $swap);

Adds a menu item or submenu to this submenu.

This method implements the C<+> operator, allowing menu items to be chained
together.

=head1 OPERATORS

=head2 +

  my $list = $submenu1 + $submenu2;

Appends C<$submenu2> to the end of the list beginning at C<$submenu1>.

The operation returns the head element of the resulting list, allowing
multiple append operations to be chained.

=head1 USAGE NOTES

C<TSubMenu> is not normally instantiated directly via C<new>. Instead, the
factory function C<new_TSubMenu> should be used.

Menu structures are commonly built using chained additions, which preserves
the original I<Turbo Vision> menu construction style.

=head1 SEE ALSO

L<TMenuItem|TUI::Menus::MenuItem>,
L<TMenuBar|TUI::Menus::MenuBar>,
L<TMenuBox|TUI::Menus::MenuBox>

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
