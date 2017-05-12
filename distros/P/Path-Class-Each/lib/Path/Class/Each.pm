package Path::Class::Each;

use warnings;
use strict;

use Carp qw( croak );
use Path::Class;

our $VERSION = '0.03';

=head1 NAME

Path::Class::Each - Iterate lines in a file

=head1 VERSION

This document describes Path::Class::Each version 0.03

=head1 SYNOPSIS

  use Path::Class;
  use Path::Class::Each;

  ## Files ##

  # Iterator interface
  my $iter = file( 'foo', 'bar' )->iterator;
  while ( defined( my $line = $iter->() ) ) {
    print "Line: $line\n";
  }

  # 'next' interface
  my $file = file( 'foo', 'bar' );
  while ( defined( my $line = $file->next ) ) {
    print "Line: $line\n";
  }

  # Callback interface
  file( 'foo', 'bar' )->each(
    sub {
      print "Line: $_\n";
    }
  );

  ## Directories ##
  
  # Iterator interface
  my $iter = dir( 'foo', 'bar' )->iterator;
  while ( defined( my $file = $iter->() ) ) {
    print "File: $file\n";
  }

  # 'next' interface
  my $file = dir( 'foo', 'bar' );
  while ( defined( my $file = $dir->next_file ) ) {
    print "File: $file\n";
  }

  # Callback interface
  dir( 'foo', 'bar' )->each(
    sub {
      print "File: $_\n";
    }
  );

=head1 DESCRIPTION

C<Path::Class::Each> augments L<Path::Class::File> and
L<Path::Class::Dir> to provide three different ways of iterating over
the lines of a file and three ways of iterating the files recursively
contained in a directory.

C<Path::Class::File> provides a C<slurp> method that returns the
contents of a file (either as a scalar or an array) but has no support
for reading a file a line at a time. For large files it may be desirable
to iterate through the lines; that's where this module comes in.

C<Path::Class::Dir> provides C<children> which returns the files and
directories immediately contained in a directory but does not expose a
'find' interface to recursively search a directory. This module provides
iterators that visit all the files in the directory tree below a
directory.

=head1 INTERFACE

=head2 File Iterators

=head3 C<< Path::Class::File->iterator >>

Get an iterator that returns the lines in a file. Returns C<undef> when
there are no more lines to return.

  my $iter = file( 'foo', 'bar' )->iterator;
  while ( defined( my $line = $iter->() ) ) {
    print "Line: $line\n";
  }

If the file can not be opened an exception will be thrown (using
C<croak>).

The following options may be passed as key, value pairs:

=over

=item C<< chomp >>

Newlines will be trimmed from each line read.

=item C<< iomode >>

Passed as the C<mode> argument to C<open>. See
L<Path::Class::File::open> for details. If omitted defaults to 'r'
(read-only).

=back

Here's how options are passed:

  my $chomper = file('foo', 'bar')->iterator( chomp => 1 );

=cut

sub Path::Class::File::iterator {
  my $self = shift;
  my @opt  = @_;

  croak "each requires a number of name => value options"
   if @opt % 2;

  my %opt   = ( @opt, iomode => 'r' );
  my $mode  = delete $opt{iomode};
  my $chomp = delete $opt{chomp};

  croak "Unknown options: ", join ', ', sort keys %opt
   if keys %opt;

  my $fh = $self->open( $mode ) or croak "Can't read $self: $!\n";
  return sub {
    my $line = <$fh>;
    return unless defined $line;
    chomp $line if $chomp;
    return $line;
  };
}

=head3 C<< Path::Class::File->next >>

Return the next line from a file. Returns C<undef> when all lines have
been read.

Internally L<iterator> is called if necessary to create a new iterator.
The same options that L<iterator> accepts may be passed to C<next>:

  my $file = file( 'foo', 'bar' );
  while ( defined( my $line = $file->next( chomp => 1 ) ) ) {
    print "Line: $line\n";
  }

=head4 NOTE

It may be tempting to use an idiom like:

  # DON'T DO THIS
  while ( my $line = file('foo')->next ) {
    ...
  }

That will create a new C<Path::Class::File> and, therefore, a new
iterator each time it is called with the result that the first line of
the file will be returned repeatedly.

=head3 C<< Path::Class::File->each >>

Call a supplied callback for each line in a file. The same options that
L<iterator> accepts may be passed:

  file( 'foo', 'bar' )->each( chomp => 1, sub { print "Line: $_\n" } );

Within the callback the current line will be in C<$_>.

=head2 Directory Iterators

=head3 C<< Path::Class::Dir->iterator >>

Return an iterator that returns each of the files in and below a
directory.

By default only files are returned. The following options may be
supplied to modify this behaviour:

=over

=item C<< dirs >>

Return directories as well as files.

=item C<< no_files >>

Return directories only.

=back

=cut

sub Path::Class::Dir::iterator {
  my ( $self, @opt ) = @_;

  croak "each requires a number of name => value options"
   if @opt % 2;

  my %opt      = @opt;
  my $dirs     = delete $opt{dirs};
  my $no_files = delete $opt{no_files};

  my @queue = $self->children( @opt );
  return sub {
    TRY: {
      return unless @queue;
      my $obj = shift @queue;
      if ( $obj->isa( 'Path::Class::Dir' ) ) {
        unshift @queue, $obj->children( @opt );
        redo TRY unless $dirs || $no_files;
      }
      else {
        redo TRY if $no_files;
      }
      return $obj;
    }
  };
}

=head3 C<< Path::Class::Dir->next_file >>

Return the next file from a recursive search of a directory. Returns
C<undef> when all lines have been read.

Internally L<iterator> is called if necessary to create a new iterator.
The same options that L<iterator> accepts may be passed to C<next_file>:

  my $dir = dir( 'foo', 'bar' );
  while ( defined( my $file = $dir->next_file ) ) {
    print "File: $file\n";
  }

=head3 C<< Path::Class::Dir->next_dir >>

Return the next directory from a recursive search of a directory.

=cut

sub Path::Class::Dir::next_dir { shift->next_file( no_files => 1 ) }

=head3 C<< Path::Class::Dir->each >>

Call a supplied callback for each file in a directory. The same options
that L<iterator> accepts may be passed:

  dir( 'foo', 'bar' )->each( dirs => 1, sub { print "Object: $_\n" } );

Within the callback the current file will be in C<$_>.

=head3 C<< Path::Class::Dir->each_dir >>

Call a supplied callback for each subdirectory in a directory.

=cut

sub Path::Class::Dir::each_dir { shift->each( no_files => 1, @_ ) }

BEGIN {
  my @extend = qw( Path::Class::File Path::Class::Dir );
  for my $class ( @extend ) {
    no strict 'refs';
    *{"${class}::each"} = sub {
      my ( $self, @opt ) = @_;
      my $cb   = pop @opt;
      my $iter = $self->iterator( @opt );
      while ( defined( local $_ = $iter->() ) ) { $cb->() }
    };
    my $next = $class eq 'Path::Class::Dir' ? 'next_file' : 'next';
    *{"${class}::${next}"} = sub {
      my $self = shift;
      $self->{_iter} = $self->iterator( @_ ) unless $self->{_iter};
      my $line = $self->{_iter}->();
      delete $self->{_iter} unless defined $line;
      return $line;
    };
  }
}

1;
__END__

=head1 DEPENDENCIES

L<Path::Class>

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Andy Armstrong C<< <andy@hexten.net> >>. All
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
