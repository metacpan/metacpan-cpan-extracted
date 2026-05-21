package TUI::toolkit;

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.08';
our $AUTHORITY = 'cpan:BRICKPOOL';

use autodie::Scope::Guard ();
use Carp ();
use Devel::StrictMode;
use Import::Into;
use Module::Loaded ();
use PerlX::Assert::PP;
use Symbol ();

use Importer ();
our @EXPORT = qw(
  true
  false
  assert
  has
  extends
  signature
);

our @EXPORT_OK = qw(
  is_Moo
  is_Moos
  is_Moose
  is_UNIVERSAL
);

our %EXPORT_TAGS = (
  all => [
    @EXPORT, 
    @EXPORT_OK
  ],

  backend => [
    @EXPORT_OK
  ],

  boolean => [qw(
    true
    false
  )],

  oo => [qw(
    has
    extends
  )],

  utils => [qw(
    assert
    signature
  )],
);

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }
BEGIN { require Devel::GlobalDestruction unless $] >= 5.014 }
BEGIN { *PERL_ONLY = $ENV{PERL_ONLY} ? sub() { !!1 } : sub() { !!0 } }
BEGIN { sub XS_ASSERT () { eval q[ require PerlX::Assert ]; !$@ } }
BEGIN { sub XS_PARAMS () { eval q[ require Type::Params  ]; !$@ } }
BEGIN { sub SUB_UTIL  () { eval q[ require Sub::Util     ]; !$@ } }

our $name;
BEGIN {
  $name = 'UNIVERSAL::Object';    # default if no other toolkit is found
  foreach my $toolkit ( qw( Moose Moo Moos ) ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }

  sub is_Moo       (){ $name eq 'Moo'               }
  sub is_Moos      (){ $name eq 'Moos'              }
  sub is_Moose     (){ $name eq 'Moose'             }
  sub is_UNIVERSAL (){ $name eq 'UNIVERSAL::Object' }
}

our %ADDED = ();

my %DEFAULT = (
  Moose => [qw( extends with has before after around override super augment 
    inner blessed confess )],
  Moo => [qw( extends with has before after around )],
  Moos => [qw( extends with has blessed confess )],
  'UNIVERSAL::Object' => [qw( extends has blessed confess )],
);

sub import {
  my ( $class, @imports ) = @_;
  my $caller = caller();
  return if $^H{ __PACKAGE__ . "/$caller" };

  # Resolve semantic imports
  my $exports = Importer->get( $class, @imports );
  my %want    = map { $_ => 1 } keys %$exports;

  # OO backend routing
  if ( my @syms = grep { $want{$_} } @{ $DEFAULT{$name} } ) {

    # Note: strict and warnings will also be enabled for caller
    SWITCH: {
      is_Moose and do {
        require Moose;
        Moose->import::into( $caller, @syms );
        last;
      };
      is_Moo and do {
        require Moo;
        Moo->import::into( $caller, @syms );
        last;
      };
      is_Moos and do {
        require Moos;
        _my_moos_export( $caller, @syms );
        _around_hook( $caller, has => \&_my_moos_has ) if $want{has};
        _add_demolish( 'Moos::Object' ) unless $ADDED{DEMOLISH}++;
        last;
      };
      is_UNIVERSAL and do {
        require TUI::toolkit::UO::Antlers;
        TUI::toolkit::UO::Antlers->import::into( $caller, @syms );
        last;
      };
      DEFAULT: {
        warn "No backend for TUI::toolkit\n";
        last;
      }
    } #/ SWITCH:

  } #/ if ( my @syms = grep {...})
  
  # boolean backend routing
  if ( $want{true} || $want{false} ) {
    require TUI::toolkit::boolean;
    TUI::toolkit::boolean->import::into( $caller, 
      grep { $want{$_} } qw( true false )
    );
  }

  # assert routed to backend
  if ( $want{assert} ) {
    if ( XS_ASSERT and not PERL_ONLY ) {
      # suppress void warnings for XS backend
      warnings->unimport( 'void' );
      PerlX::Assert->import::into( $caller, 'assert' );
    }
    else {
      PerlX::Assert::PP->import::into( $caller );
    }
  }

  # signature routed to backend
  if ( $want{signature} ) {
    if ( XS_PARAMS and not PERL_ONLY ) {
      Type::Params->import::into( $caller, 'signature' );
    }
    else {
      TUI::toolkit::Params->import::into( $caller, 'signature' );
    }
  }

  # Add a dump method to the class if it doesn't already have one
  $^H{ __PACKAGE__ . "/$caller" } = autodie::Scope::Guard->new(sub {
    _add_dump( $caller ) unless $caller->can( 'dump' );
  });

  # exports living in this module
  Importer->import_into( $class, $caller, @{ $EXPORT_TAGS{backend} } );
} #/ sub import

sub unimport {
  my $caller = caller();
  return unless $^H{ __PACKAGE__ . "/$caller" };

  if ( XS_PARAMS and not PERL_ONLY ) {
    Type::Params->unimport::out_of( $caller );
  }
  else {
    TUI::toolkit::Params->unimport::out_of( $caller );
  }
  if ( XS_ASSERT and not PERL_ONLY ) {
    PerlX::Assert->unimport::out_of( $caller );
  }
  else {
    PerlX::Assert::PP->unimport::out_of( $caller );
  }
  TUI::toolkit::boolean->unimport::out_of( $caller );
  if ( is_Moose ) {
    Moose->unimport::out_of( $caller );
  }
  elsif ( is_Moo ) {
    Moo->unimport::out_of( $caller );
  }
  elsif ( is_Moos ) {
    Moos->unimport::out_of( $caller );
  } 

  $^H{ __PACKAGE__ . "/$caller" } = 0;
}

# Split fully qualified name into package and symbol
sub _split_fqn {    # ($pkg, $sym) = _split_fqn($fqn)
  my ( $fqn ) = @_;
  assert ( defined $fqn && !ref $fqn );
  my ( $pkg, $sym ) = $fqn =~ m/^(.*)::([^:]+)\z/ 
                    ? ( $1, $2 ) 
                    : ( 'main', $fqn );
  $pkg = 'main' if !defined( $pkg ) || $pkg eq '';
  return ( $pkg, $sym );
}

# Get the symbol table hash for a package, or undef if it does not exist
sub _get_package_stash {    # \%stash|undef ($pkg)
  my ( $pkg ) = @_;
  assert ( defined $pkg && !ref $pkg );

  return \%:: if $pkg eq '' || $pkg eq 'main';

  $pkg =~ s/::\z//;
  my @parts = split /::/, $pkg;
  my $stash = \%::;    # main::

  no strict 'refs';
  for my $p (@parts) {
    return undef if $p eq '';
    my $key = "${p}::";
    return undef if !exists $stash->{$key};
    my $glob = $stash->{$key};
    my $next = *{$glob}{HASH} or return undef;
    $stash = $next;
  }
  return $stash;
}

# Adds a new method to an existing class
sub _create_method {    # void ($class, $name, \&code)
  my ( $class, $name, $code ) = @_;
  assert ( defined $class and !ref $class );
  assert ( defined $name and !ref $name );
  assert ( defined $code and ref $code eq 'CODE' );
  
  # Build fully-qualified name (keeps $name if already qualified)
  my $fqn = Symbol::qualify( $name, $class );
  my ( $pkg, $sym ) = _split_fqn( $fqn );

  my $stash = _get_package_stash( $pkg );
  unless ( defined $stash ) {
    warn "Cannot add method $fqn to non-existing package $pkg\n";
    return;
  }

  $code = Sub::Util::set_subname( $fqn, $code ) if SUB_UTIL;    # nicer traces
  my $glob = Symbol::qualify_to_ref( $sym, $pkg );
  *{$glob} = $code;   # warns if redefining an existing method
  return;
} #/ sub _create_method

# An around method modifier without checking of an existing method
sub _around_hook {    # void ($class, $name, \&code)
  my ( $class, $name, $code ) = @_;
  assert ( defined $class and !ref $class );
  assert ( defined $name and !ref $name );
  assert ( defined $code and ref $code eq 'CODE' );

  my $fqn = Symbol::qualify( $name, $class );    # builds full name
  my ( $pkg, $sym ) = _split_fqn( $fqn );

  my $stash = _get_package_stash( $pkg );
  unless ( defined $stash ) {
    warn "Cannot hook method $fqn from non-existing package $pkg\n";
    return;
  }

  # glob ref for installation
  my $glob = Symbol::qualify_to_ref( $sym, $pkg );
  my $orig = *{$glob}{CODE};
  unless ( $orig ) {
    warn "Cannot wrap non-existing method $fqn\n";
    return;
  }

  my $wrapper = sub { $code->( $orig, @_ ) };
  $wrapper = Sub::Util::set_subname( $fqn, $wrapper ) if SUB_UTIL;

  no warnings 'redefine';
  *{$glob} = $wrapper;
  return;
} #/ sub _around_hook

# We are I<patching> the Moos C<has> arguments to support C<< is => 'bare' >> 
# and C<< default => scalar|ref >>
sub _my_moos_has {    # $return (\&orig, $self, @_)
  my ( $orig, $self, %args ) = @_;
  if ( exists $args{is} && $args{is} eq 'bare' ) {
    $args{is} = 'rw';
    $args{_skip_setup} = 1;
  }
  if ( exists $args{default} && ref $args{default} ne 'CODE' ) {
    my $default = $args{default};
    $args{default} = sub { $default };
  }
  return $self->$orig( %args );
} #/ sub _my_moos_has

# Import only what is requested and not the Moos default
sub _my_moos_export {    # void ($caller, @names)
  my ( $caller, @names ) = @_;
  {
    no warnings 'redefine';
    local *Moos::_export = sub { };
    Moos->import::into( $caller );
  }
  my $meta = Moos::Meta::Class->initialize( $caller );
  for my $name ( @names ) {
    my $code = Moos->can( $name )
      or Carp::croak "Moos has no keyword '$name'";

    Moos::_export( $caller, $name => $code, $meta );
  }
  return;
}

# Provide an equivalent dump method using L<Data::Dumper>, unless one already 
# exists
sub _add_dump {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = ref $proto || $proto;
  _create_method( $target, 
    dump => sub {
      no warnings 'once';
      my $self = shift;
      require Data::Dumper;
      local $Data::Dumper::Sortkeys = 1;
      local $Data::Dumper::Maxdepth = shift if @_;
      my $str = Data::Dumper::Dumper $self;
      $str =~ s/(^|\s)\$VAR\d+\b/$1'$self'/g;
      return $str;
    }
  );
  return;
}

# Provide DEMOLISH if it is not available
sub _add_demolish {    # void ($target)
  my ( $proto ) = @_;
  assert ( $proto );
  my $target = ref $proto || $proto;
  return if $target->can( 'DESTROY' );
  _create_method( $target, 
    DESTROY => sub {
      my $self = shift;
      my $class = ref $self || $self;

      my $in_global_destruction = defined ${^GLOBAL_PHASE}
        ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
        : Devel::GlobalDestruction::in_global_destruction();

      # Call all DEMOLISH methods starting with the derived classes.
      foreach ( @{ mro::get_linear_isa( $class ) } ) {
        no strict 'refs';
        my $demolish = *{$_.'::DEMOLISH'}{CODE};
        next unless $demolish;
        $self->$demolish( $in_global_destruction )
      }
      return;
    }
  );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::toolkit - Unified OO facade for the TUI::Vision framework

=head1 SYNOPSIS

  package Point;
  use TUI::toolkit;   # has extends signature assert true false

  has x => ( is => 'rw' );
  has y => ( is => 'rw' );

  no TUI::toolkit;  # remove keywords (has, extends, etc.) from namespace
                    # keep methods (new, dump, DESTROY)

  my $p = Point->new( x => 1, y => 2 );
  say $p->dump;

=head1 DESCRIPTION

TUI::toolkit provides a unified object system facade for the
TUI::Vision framework. It corresponds to the functionality of
C<TV::toolkit> and offers a consistent set of OO features regardless of
which backend toolkit is available.

C<TV::toolkit> dynamically selected an OO backend from:

=over 4

=item * Moos  
Minimalistic attribute and method generator.

=item * Moo  
Lightweight meta-object system.

=item * Moose  
Full-featured meta-object system.

=item * UNIVERSAL::Object  
Modern, minimal object base class.

=back

The selection is made at compile time for each caller of C<use TUI::toolkit>.
Whichever toolkit is active, C<TUI::toolkit> installs a consistent set of
keywords and behaviors, including:

=over 4

=item * define C<true> and C<false> constants

=item * C<assert> - assertion keyword

=item * C<has> - attribute declaration

=item * C<extends> - simple class inheritance

=item * C<signature> - subroutine signature validation

=item * an optional C<dump> method, unless already present

=item * a C<DESTROY> method that dispatches C<DEMOLISH> in MRO order

=back

Importing of C<blessed> and C<confess> are not provided, but can be imported 
from L<Scalar::Util> and L<Carp> respectively.

The goal is to provide a predictable minimum OO feature set regardless of
which backend toolkit is already in use.

=head1 BACKEND BEHAVIOR

If any of these toolkits are already loaded, C<TUI::toolkit> uses them
directly:

=over 4

=item * C<Moos> - primary minimal backend (defaults to this when available)

=item * C<Moo> - lightweight attribute and method generator

=item * C<Moose> - full meta-object system

=back

No attempt is made to replace or extend the backend beyond injecting
C<dump> and C<DESTROY> when appropriate.

If none of Moos/Moo/Moose are loaded, a very small L<LUNIVERSAL::Object> based 
OO layer is used. 

This exists only to keep modules functional in environments where no of the 
other toolkits are available. It is not intended to be a full object system.

=head1 SEE ALSO

=over 4

=item * L<Moos>

=item * L<Moo>

=item * L<Moose>

=item * L<Devel::StrictMode>

=item * L<Type::Params>

=item * L<PerlX::Assert>

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

Copyright (c) 2024-2026 the L</AUTHORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
