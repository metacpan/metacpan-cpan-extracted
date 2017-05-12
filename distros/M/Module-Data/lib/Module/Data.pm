use 5.006;    # our
use strict;
use warnings;

package Module::Data;

our $VERSION = '0.013';

# ABSTRACT: Introspect context information about modules in @INC

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( around has );
use Sub::Quote qw( quote_sub );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;

  unshift @args, 'package' if @args % 2 == 1;

  return $class->$orig(@args);
};






































has package => (
  required => 1,
  is       => 'ro',
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars, ValuesAndExpressions::RestrictLongStrings)
  isa => quote_sub q{}
    . q{die "given undef for 'package' , expects a Str/module name" if not defined $_[0];}
    . q{die " ( 'package' => $_[0] ) is not a Str/module name, got a ref : " . ref $_[0] if ref $_[0];}
    . q{require Module::Runtime;}
    . q{Module::Runtime::check_module_name( $_[0] );},
);

has _notional_name => (
  is   => 'ro',
  lazy => 1,
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
  default => quote_sub q{} . q{require Module::Runtime;} . q{return Module::Runtime::module_notional_filename( $_[0]->package );},
);











sub loaded {
  my ($self) = @_;
  return exists $INC{ $self->_notional_name };
}















## no critic ( ProhibitBuiltinHomonyms )
sub require {
  my ($self) = @_;
  return $self->package if $self->loaded;

  require Module::Runtime;
  Module::Runtime::require_module( $self->package );
  return $self->package;
}

sub _find_module_perl {
  my ($self) = @_;
  $self->require;
  return $INC{ $self->_notional_name };
}

sub _find_module_emulate {
  my ($self) = @_;
  require Path::ScanINC;
  Path::ScanINC->VERSION('0.011');
  return Path::ScanINC->new()->first_file( $self->_notional_name );
}

sub _find_module_optimistic {
  my ($self) = @_;
  return $INC{ $self->_notional_name } if $self->loaded;
  return $self->_find_module_emulate;
}

## use critic















has path => (
  is       => 'ro',
  lazy     => 1,
  init_arg => undef,
  builder  => '_build_path',
);

sub _build_path {
  my ( $self, ) = @_;
  my $value = $self->_find_module_optimistic;
  return if not defined $value;
  require Path::Tiny;
  return Path::Tiny::path($value)->absolute;
}

















has root => (
  is       => 'ro',
  lazy     => 1,
  init_arg => undef,
  builder  => '_build_root',
);

sub _build_root {
  my ($path) = $_[0]->path;

  # Parent ne Self is the only cross-platform way
  # I can think of that will stop at the top of a tree
  # as / is not applicable on windows.
  while ( $path->parent->absolute ne $path->absolute ) {
    if ( not $path->is_dir ) {
      $path = $path->parent;
      next;
    }
    if ( $path->child( $_[0]->_notional_name )->absolute eq $_[0]->path->absolute ) {
      return $path->absolute;
    }
    $path = $path->parent;
  }
  return;

}





















sub _version_perl {
  my ($self) = @_;
  $self->require;

  # has to load the code into memory to work
  return $self->package->VERSION;
}

sub _version_emulate {
  my ($self) = @_;
  my $path = $self->path;
  require Module::Metadata;
  my $i = Module::Metadata->new_from_file( $path, collect_pod => 0 );
  return $i->version( $self->package );
}

sub _version_optimistic {
  my ($self) = @_;
  return $self->package->VERSION if $self->loaded;
  return $self->_version_emulate;
}

sub version {
  my ( $self, ) = @_;
  return $self->_version_optimistic;
}









no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Data - Introspect context information about modules in @INC

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	use Module::Data;

	my $d = Module::Data->new( 'Package::Stash' );

	$d->path; # returns the path to where Package::Stash was found in @INC

	$d->root; # returns the root directory in @INC that 'Package::Stash' was found inside.

	# Convenient trick to discern if you're in a development environment

	my $d = Module::Data->new( 'Module::Im::Developing' );

	if ( -e $d->root->parent->subdir('share') ) {
		# Yep, this dir exists, so we're in a dev context.
		# because we know in the development context all modules are in lib/*/*
		# so if the modules are anywhere else, its not a dev context.
		# see File::ShareDir::ProjectDistDir for more.
	}

	# Helpful sugar.

	my $v = $d->version;

=head1 METHODS

=head2 package

Returns the package the C<Module::Data> instance was created for. In essence,
this will just return the value you passed during C<new>, nothing more, nothing
less.

	my $package = $md->package

=head2 loaded

Check to see if the module is already recorded as being loaded in C<%INC>

	if ( $md->loaded ) {
		say "$md was loaded";
	}

=head2 require

Require the module be loaded into memory and the global stash.

  my $mod = Module::Data->new( 'Foo' ); # nothing much happens.
  $mod->require; # like 'require Foo';

Returns the L</package> name itself for convenience so you can do

  my $mod = Module::Data->new('Foo');
  $mod->require->new( %args );

=head2 path

A Path::Tiny object with the absolute path to the found module.

	my $md = Module::Data->new( 'Foo' );
	my $path = $md->path;

C<$path> is computed optimistically. If the L</package> is listed as being
L</loaded>, then it asks C<%INC> for where it was found, otherwise, the path is
resolved by simulating C<perl>'s path look up in C<@INC> via
L<< C<Path::ScanINC>|Path::ScanINC >>.

=head2 root

Returns the base directory of the tree the module was found at.
( Probably from @INC );

	local @INC = (
		"somewhere/asinine/",
		"somewhere/in/space/",   # Where Lib::Foo::Bar is
		"somethingelse/",
	);
	my $md = Module::Data->new( "Lib::Foo::Bar");
	$md->path ; # somewhere/in/space/Lib/Foo/Bar.pm
	my $root = $md->root # somewhere/in/space

=head2 version

If the module appears to be already loaded in memory:

	my $v = $md->version;

is merely shorthand for $package->VERSION;

However, if the module is not loaded into memory, all efforts to extract the
value without loading the code permanently are performed.

Here, this means we compute the path to the file manually ( see L</path> ) and
parse the file with L<< C<Module::Metadata>|Module::Metadata >> to statically extract C<$VERSION>.

This means you can unleash this code on your entire installed module tree, while
incurring no permanent memory gain as you would normally incur if you were to
C<require> them all.

=for Pod::Coverage   BUILDARGS

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
