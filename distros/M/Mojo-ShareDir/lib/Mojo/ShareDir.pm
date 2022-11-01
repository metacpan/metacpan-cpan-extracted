package Mojo::ShareDir;
use Mojo::Base 'Mojo::File';

use Carp qw(croak);

use constant DEBUG => $ENV{MOJO_FILE_SHARE_DEBUG} || 0;

our @EXPORT_OK = qw(dist_path);
our $VERSION = '0.01';

our @AUTO_SHARE_DIST   = qw(auto share dist);
our @AUTO_SHARE_MODULE = qw(auto share module);
our $LOCAL_SHARE_DIR   = 'share';

sub dist_path { __PACKAGE__->new(@_) }

sub new {
  return shift->SUPER::new(@_) if ref $_[0];

  my ($class, $class_name, @child) = (shift, @_ ? shift : scalar caller, @_);
  my @class_parts = split /(?:-|::)/, (ref $class_name || $class_name);
  my $path        = $class->_new_from_inc(\@class_parts) || $class->_new_from_installed(\@class_parts);
  croak qq(Could not find dist path for "$class_name".) unless $path;

  $path = $path->child(@child)                            if @child;
  warn "[Share] $class->new($class_name, ...) == $path\n" if DEBUG;
  return $path;
}

sub _new_from_inc {
  my ($class, $class_parts) = @_;

  # Check if the class exists in %INC
  my $inc_key = sprintf '%s.pm', join '/', @$class_parts;
  return undef unless $INC{$inc_key} and -e $INC{$inc_key};

  # Find the absolute path to the module and then find the project root
  my $path = $class->SUPER::new($INC{$inc_key})->to_abs->to_array;
  pop @$path for 0 .. @$class_parts;

  # Return the project "root/share" if the directory exists
  my $share = $class->SUPER::new(@$path, $LOCAL_SHARE_DIR);
  return -d $share && $share;
}

sub _new_from_installed {
  my ($class, $class_parts) = @_;

  my @auto_path;
  push @auto_path, $class->SUPER::new(@AUTO_SHARE_DIST, join '-', @$class_parts);    # File::ShareDir::_dist_dir_new()
  push @auto_path, $class->SUPER::new('auto', @$class_parts);                        # File::ShareDir::_dist_dir_old()

  for my $auto_path (@auto_path) {
    for my $inc (@INC) {
      my $share = $class->SUPER::new($inc, $auto_path);
      return $share if -d $share;
    }
  }

  return undef;
}

1;

=encoding utf8

=head1 NAME

Mojo::ShareDir - Shared files and directories as Mojo::File objects

=head1 SYNOPSIS

=head2 Example use of Mojo::ShareDir

  use Mojo::ShareDir;

  # This will result in the same thing
  my $path = Mojo::ShareDir->new('My-Application');
  my $path = Mojo::ShareDir->new('My::Application');
  my $path = Mojo::ShareDir->new(My::Application->new);

=head2 Example Makefile.PL

  use strict;
  use warnings;
  use ExtUtils::MakeMaker;
  use File::ShareDir::Install;

  install_share 'share';
  WriteMakefile(...);

  package MY;
  use File::ShareDir::Install qw(postamble);

=head1 DESCRIPTION

L<Mojo::ShareDir> is a module that allows you to find shared files. This
module works together with L<File::ShareDir::Install>, which allow you to
install assets that are not Perl related. In addition, L<Mojo::ShareDir>
makes it very easy to find the files that you have not yet installed by
looking for projects after resolving C<@INC>.

=head1 FUNCTIONS

L<Mojo::ShareDir> implements the following functions, which can be imported
individually.

=head2 dist_path

  my $path = dist_path;
  my $path = dist_path "Some-Dist", @path;
  my $path = dist_path "Some::Module", @path;
  my $path = dist_path $some_object, @path;

Construct a new L<Mojo::ShareDir> object. Follows the same rules as L</new>.

=head1 METHODS

L<Mojo::ShareDir> inherits all methods from L<Mojo::File> and implements the
following new ones.

=head2 new

  my $path = Mojo::ShareDir->new;
  my $path = Mojo::ShareDir->new("Some-Dist", @path);
  my $path = Mojo::ShareDir->new("Some::Module", @path);
  my $path = Mojo::ShareDir->new($some_object, @path);

Construct a new L<Mojo::ShareDir> object with C<$path> set to either the
local "share/" path or the installed for a given distribution.

Will throw an exception if the distribution cannot be found.

To resolve the shared path, these rules will apply:

=over 2

=item * No arguments

Will use the caller package name.

=item * A dist name

To resolve the local path, by converting the dist name into a module name, and
look it up in C<%INC>. This means the module need to be loaded.

=item * A module name

See "A dist name" above.

=item * An object

Will find the class name for the object and apply the same rule as for "A
module name".

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C), Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<File::ShareDir::Install>

L<File::ShareDir>

L<File::Share>

=cut
