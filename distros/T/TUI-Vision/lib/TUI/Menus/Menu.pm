package TUI::Menus::Menu;
# ABSTRACT: Linked list of TMenuItem records

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenu
  new_TMenu
);

use Devel::StrictMode;
use Scalar::Util qw( weaken );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TMenu() { __PACKAGE__ }
sub new_TMenu { __PACKAGE__->from(@_) }

# public attributes
has items => ( is => 'rw' );
has deflt => ( is => 'bare' );    # weak_ref => 1

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named  => [
      items => Object, { optional => 1, },
      deflt => Object, { optional => 1, alias => 'default' },
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
  $self->{deflt} //= $self->{items};
  weaken $self->{deflt} if $self->{deflt};
  &$lock_value( $self->{deflt} ) if STRICT;
  return;
}

sub from {    # $obj (| $itemList, | $TheDefault)
  state $sig = signature(
    method => 1,
    pos => [
      Object, { optional => 1 },
      Object, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( items => $args[0], default => $args[0] );
    $_ == 2 and return $class->new( items => $args[0], default => $args[1] );
  }
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  while ( $self->{items} ) {
    my $temp = $self->{items};
    $self->{items} = $self->{items}{next};
    undef $temp;
  }
  &$unlock_value( $self->{deflt} ) if STRICT;
  return;
}

sub deflt {    # $view|undef (|$view|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $view ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{deflt};
  }
  SET: {
    &$unlock_value( $self->{deflt} ) if STRICT;
    weaken $self->{deflt}
      if $self->{deflt} = $view;
    &$lock_value( $self->{deflt} ) if STRICT;
    return;
  }
}

1

__END__

=pod

=head1 NAME

TUI::Menus::Menu - container for menu item lists

=head1 SYNOPSIS

  use TUI::Menus;

  my $menu =
      new_TMenu(
        new_TMenuItem('~O~pen', cmOpen)
      + new_TMenuItem('~S~ave', cmSave)
      );

=head1 DESCRIPTION

C<TMenu> represents a container used to build menu structures for menu bars
and menu boxes. It holds a linked list of C<TMenuItem> objects and an optional
default item.

Menu objects are typically created indirectly using helper constructors and
combined using the overloaded C<+> operator. The resulting menu structure is
passed to menu views such as C<TMenuBar> or C<TMenuBox>.

C<TMenu> is a data structure and does not perform any drawing or event
processing itself.

=head1 ATTRIBUTES

The following attributes describe the contents of the menu.

=over

=item items

Reference to the first menu item in the list (I<TMenuItem>).

=item deflt

Optional reference to the default menu item (I<TMenuItem>).  
This item may be highlighted or preselected depending on the menu view.

=back

=head1 CONSTRUCTOR

=head2 new

  my $menu = TMenu->new(
    items => $items,
    deflt => $default
  );

Creates a new menu container.

=over

=item items

Optional reference to a list of menu items (I<TMenuItem>).

=item deflt

Optional default menu item (I<TMenuItem>).

=back

=head2 new_TMenu

  my $menu = new_TMenu($items | undef, | $default);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 deflt

  my $item = $menu->deflt();
  $menu->deflt($item);

Gets or sets the default menu item.

=head1 SEE ALSO

L<TUI::Menus::MenuItem>,
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
