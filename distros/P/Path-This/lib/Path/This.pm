package Path::This;

use strict;
use warnings;
use Carp ();
use Cwd ();
use File::Basename ();
use Sub::Util ();

our $VERSION = '0.003';

sub THISFILE () { Cwd::abs_path((caller)[1]) }
sub THISDIR () {
  my $file = (caller)[1];
  return -e $file ? File::Basename::dirname(Cwd::abs_path $file) : Cwd::getcwd;
}

sub import {
  my $class = shift;
  my ($package, $file) = caller;

  my ($abs_file, $abs_dir);
  foreach my $item (@_) {
    if ($item =~ m/\A([&\$])?THISFILE\z/) {
      my $symbol = $1;
      unless (defined $abs_file) {
        $abs_file = Cwd::abs_path $file;
      }
      if (!$symbol) {
        my $const_file = $abs_file;
        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::THISFILE"} = \&{Sub::Util::set_subname
          "${package}::THISFILE", sub () { $const_file }};
      } elsif ($symbol eq '&') {
        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::THISFILE"} = \&THISFILE;
      } elsif ($symbol eq '$') {
        no strict 'refs';
        *{"${package}::THISFILE"} = \$abs_file;
      }
    } elsif ($item =~ m/\A([&\$])?THISDIR\z/) {
      my $symbol = $1;
      unless (defined $abs_dir) {
        $abs_dir = defined $abs_file ? File::Basename::dirname($abs_file)
          : -e $file ? File::Basename::dirname($abs_file = Cwd::abs_path $file)
          : Cwd::getcwd;
      }
      if (!$symbol) {
        my $const_dir = $abs_dir;
        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::THISDIR"} = \&{Sub::Util::set_subname
          "${package}::THISDIR", sub () { $const_dir }};
      } elsif ($symbol eq '&') {
        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::THISDIR"} = \&THISDIR;
      } elsif ($symbol eq '$') {
        no strict 'refs';
        *{"${package}::THISDIR"} = \$abs_dir;
      }
    } else {
      Carp::croak qq{"$item" is not exported by the $class module};
    }
  }
}

1;

=head1 NAME

Path::This - Path to this source file or directory

=head1 SYNOPSIS

  use Path::This '$THISFILE';
  print "This file is $THISFILE\n";

  use Path::This '$THISDIR';
  use lib "$THISDIR/../lib";

=head1 DESCRIPTION

Exports package variables by request that represent the current source file or
directory containing that file. Dynamic or constant sub versions can also be
requested. Paths will be absolute with symlinks resolved.

Note that the package variable or constant sub will be exported to the current
package globally. If the same package will be used in multiple files, use the
dynamic sub export so the file path will be calculated when the sub is called.

=head1 EXPORTS

=head2 $THISFILE

=head2 &THISFILE

=head2 THISFILE

  print "$THISFILE\n";
  my $file = THISFILE;

Absolute path to the current source file. Behavior is undefined when called
without a source file (e.g. from the command line or STDIN). C<$THISFILE> will
export a package variable, C<&THISFILE> will export a dynamic subroutine, and
C<THISFILE> will export an inlinable constant.

=head2 $THISDIR

=head2 &THISDIR

=head2 THISDIR

  print "$THISDIR\n";
  my $dir = THISDIR;

Absolute path to the directory containing the current source file, or the
current working directory when called without a source file (e.g. from the
command line or STDIN). C<$THISDIR> will export a package variable, C<&THISDIR>
will export a dynamic subroutine, and C<THISDIR> will export an inlinable
constant.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<FindBin>, L<Dir::Self>, L<lib::relative>
