package Sys::Headers;
#
# $Id: $
#

use 5.00503;
use strict;
use File::Spec::Functions qw[splitpath rel2abs];
use Cwd;
use Config;
use Carp;

use vars qw[$VERSION];

require lib;
import lib _get_headers_dir();

# do { my @r=(q$Revision: $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$VERSION = '0.01';

sub import {
  shift;
  package main;
  require "$_.ph" foreach @_;
  package __PACKAGE__;
}

sub convert_headers {
  my $headers_dir = _get_headers_dir();
  croak "Must pass even number of arguments to convert_headers()." if @_ % 2;
  my %args = @_;
  foreach ( @{$args{includedirs}} ) {
    my $cwd = cwd;
    chdir $_;
    system "$Config{scriptdir}/h2ph -r -l -d $headers_dir *";
    chdir $cwd;
  }
  foreach ( @{$args{headers}} ) {
    my( $path, $file ) = (splitpath $_)[1,2];
    my $cwd  = cwd;
    chdir $path;
    system "$Config{scriptdir}/h2ph -a -l -d $headers_dir $file";
    chdir $cwd;
  }
}

sub _get_headers_dir {
  ( my $package = __PACKAGE__ . '.pm' ) =~ s!::!/!g;
  my $dir = rel2abs +(split /\./ => $INC{$package})[0];
  if ( -e $dir ) {
    if ( -d _ ) {
      return $dir;
    } else {
      croak "$dir exists and is not a directory\n";
    }
  } else {
    if ( mkdir $dir ) {
      return $dir;
    } else {
      croak "Couldn't mkdir( $dir ): $!\n";
    }
  }
}

1;
__END__

=head1 NAME

Sys::Headers - Perl interface to system headers.

=head1 SYNOPSIS

 # Update your header repository
 use Sys::Headers;
 Sys::Headers::convert_headers(
   includedirs => [ qw[
                       /usr/include
                       /usr/local/include
                       /usr/local/apache/include
                  ] ],
   headers     => [ qw[
                       /home/cwest/include/cwest.h
                  ] ],
 );

 # Use headers in your program
 use Sys::Headers qw[paths sys/fcntl];
 my $null = _PATH_DEVNULL;
 my $tmp  = _PATH_TMP;

 open( FILE, "$tmp/file" ) || die $!;
 open( NULL, $null,      ) || die $!;
 
 flock FILE, O_SHLOCK;
 flock NULL, O_EXLOCK;
 
 print NULL $_ while <FILE>;
 
 close NULL;
 close FILE;
 
=head1 DESCRIPTION

This is alpha code.

This is alpha code.

This is alpha code.

This module will use L<h2ph> to convert your systems header files
into Perl header files.  It should be stated that h2ph isn't very
good at this, it has some bugs.  However, if you can handle a few
warnings every now and again, and you need access to information
contained in the header files, use this module.

First you need to build a repository of Perl header files.  This
requires having write access to the place where Sys::Headers is
installed.  This limitation will most likley change.

Once you've done that, you can use these headers at compile time
by listing the ones you want in similar fashion to C<#include> from
C.

=head2 EXPORT

It will export constants based on which header files you choose to
use.

=head1 AUTHOR

Casey West, E<lt>casey@geeknest.com<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Casey West. All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
