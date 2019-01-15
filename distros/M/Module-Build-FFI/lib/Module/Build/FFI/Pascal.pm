package Module::Build::FFI::Pascal;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use File::chdir;
use File::Copy qw( move );
use base qw( Module::Build::FFI );

# ABSTRACT: Build Perl extensions in Free Pascal with FFI
our $VERSION = '0.49'; # VERSION


__PACKAGE__->add_property( ffi_pascal_extra_compiler_flags =>
  default => [],
);

__PACKAGE__->add_property( ffi_pascal_extra_linker_flags =>
  default => [],
);

__PACKAGE__->add_property( ffi_pascal_lib =>
  default => ['ffi.pas','test.pas'],
);


sub ffi_have_compiler
{
  my($self) = @_;
  
  my $fpc = which('fpc');
  my $ppumove = which('ppumove');
  
  return (!!$fpc) && (!!$ppumove);
}


sub ffi_build_dynamic_lib
{
  my($self, $src_dir, $name, $target_dir) = @_;

  die "multiple directories not supported by ", __PACKAGE__
    if @$src_dir > 1;
    
  $src_dir = $src_dir->[0];
  my $lib;
  my %lib = map { $_ => 1 } @{ $self->ffi_pascal_lib };

  do {
    local $CWD = $src_dir;
    print "cd $CWD\n";
  
    $target_dir = $src_dir unless defined $target_dir;
    my @sources = bsd_glob("*.pas");
  
    return unless @sources;
  
    my $fpc = which('fpc');
    my $ppumove = which('ppumove');

    my @compiler_flags;
    my @linker_flags;

    # TODO: OSX not sure if checking ptrsize will actually work
    #       % arch -arch i386 /usr/bin/perl -V:ptrsize
    #       ptrsize='8';
    #       but the system perl is a universal binary
    #       or maybe I am using arch wrong.  who knows.
    # TODO: OSX make a universal binary if possible?
    # Fortunately most people are probably using OS X 64 bit intel by now anyway
    push @compiler_flags, '-Px86_64' if $^O eq 'darwin' && $Config{ptrsize} == 8;

    my @ppu;

    foreach my $src (@sources)
    {
      if($lib{$src})
      {
        die "Two or more libraries in $CWD" if defined $lib;
        $lib = $src;
        next;
      }
    
      my @cmd = (
        $fpc,
        @compiler_flags,
        @{ $self->ffi_pascal_extra_compiler_flags },
        $src
      );
    
      print "@cmd\n";
      system @cmd;
      exit 2 if $?;
    
      my $ppu = $src;
      $ppu =~ s{\.pas$}{.ppu};
    
      unless(-r $ppu)
      {
        print STDERR "unable to find $ppu after compile\n";
        exit 2;
      }
    
      push @ppu, $ppu;
    }

    if($lib)
    {
      my @cmd = (
        $fpc,
        @compiler_flags,
        @{ $self->ffi_pascal_extra_compiler_flags },
        $lib,
      );
      print "@cmd\n";
      system @cmd;
      exit 2 if $?;
      my @so = map { bsd_glob("*.$_") } Module::Build::FFI->ffi_dlext;
      die "multiple dylibs in $CWD" if @so > 1;
      die "no dylib in $CWD" if @so < 1;
    }
    else
    {
      my @cmd;

      if($^O eq 'darwin')
      {
        my @obj = map { s/\.ppu/\.o/; $_ } @ppu;
        @cmd = (
          'ld',
          $Config{dlext} eq 'bundle' ? '-bundle' : '-dylib',
          '-o' => "libmbFFIPlatypusPascal.$Config{dlext}",
          @obj,
        );
      }
      else
      {
        @cmd = (
          $ppumove,
          @linker_flags,
          @{ $self->ffi_pascal_extra_linker_flags },
          -o => 'mbFFIPlatypusPascal',
          -e => 'ppl',
          @ppu,
        );
      }
      print "@cmd\n";
      system @cmd;
      exit 2 if $?;
    }

  };
  
  print "cd $CWD\n";
  
  my($from) = map { bsd_glob("$src_dir/*.$_") } Module::Build::FFI->ffi_dlext;
  
  unless(defined $from)
  {
    print STDERR "unable to find shared library\n";
    exit 2;
  }
  
  print "chmod 0755 $from\n";
  chmod 0755, $from;
  
  my $ext = $Config{dlext};
  foreach my $try (Module::Build::FFI->ffi_dlext)
  {
    $ext = $1 if $from =~ /\.($try)/;
  }
  
  my $dll = File::Spec->catfile($target_dir, "$name.$ext");

  if($from ne $dll)
  {
    print "mv $from $dll\n";
    move($from => $dll) || do {
      print "error copying file $!";
      exit 2;
    };
  }
  
  $dll;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::FFI::Pascal - Build Perl extensions in Free Pascal with FFI

=head1 VERSION

version 0.49

=head1 DESCRIPTION

L<Module::Build::FFI> variant for writing Perl extensions in Pascal with
FFI (sans XS).

=head1 BASE CLASS

All methods, properties and actions are inherited from:

L<Module::Build::FFI>

=head1 PROPERTIES

=over 4

=item ffi_pascal_lib

Name of Pascal libraries.  Default is ['ffi.pas','test.pas']

=item ffi_pascal_extra_compiler_flags

Extra compiler flags to be passed to C<fpc>.

Must be a array reference.

=item ffi_pascal_extra_linker_flags

Extra linker flags to be passed to C<ppumove>.

Must be a array reference.

=back

=head1 BASE CLASS

=over

=item L<Module::Build::FFI>

=back

=head1 METHODS

=head2 ffi_have_compiler

 my $has_compiler = $mb->ffi_have_compiler;

Returns true if Free Pascal is available.

=head2 ffi_build_dynamic_lib

 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name, $target_dir);
 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name);

Compiles the Pascal source in the C<$src_dir> and link it into a dynamic
library with base name of C<$name.$Config{dlexe}>.  If C<$target_dir> is
specified then the dynamic library will be delivered into that directory.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
