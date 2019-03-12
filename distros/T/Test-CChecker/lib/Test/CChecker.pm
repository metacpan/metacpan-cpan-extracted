package Test::CChecker;

use strict;
use warnings;
use base qw( Test::Builder::Module );
use ExtUtils::CChecker;
use Capture::Tiny qw( capture_merged );
use Text::ParseWords qw( shellwords );
use Env qw( @LD_LIBRARY_PATH );
use File::Spec;
use FindBin ();
use File::Temp ();
use Scalar::Util qw( blessed );

our @EXPORT = qw(
  cc
  compile_ok
  compile_run_ok
  compile_with_alien
  compile_output_to_nowhere
  compile_output_to_diag
  compile_output_to_note
);

my $warn_deprecated = do {

  my $warned = 0;

  sub
  {
    return if $warned++;
    my $tb = __PACKAGE__->builder;
    $tb->diag('');
    $tb->diag('');
    $tb->diag('');
    $tb->diag(' ********************************************* ');
    $tb->diag(' * WARNING:                                  * ');
    $tb->diag(' * Test::CChecker has been deprecated!       * ');
    $tb->diag(' * Please use Test::Alien instead.           * ');
    $tb->diag(' ********************************************* ');
    $tb->diag('');
    $tb->diag('');
  }
};

# ABSTRACT: Test-time utilities for checking C headers, libraries, or OS features (DEPRECATED)
our $VERSION = '0.10'; # VERSION


do {
  my $cc;
  sub cc ()
  {
    $warn_deprecated->();
    $cc ||= ExtUtils::CChecker->new( quiet => 0 );
  }
};


my $output = '';

sub compile_run_ok ($;$)
{
  $warn_deprecated->();
  my($args, $message) = @_;
  $message ||= "compile ok";
  my $cc = cc();
  my $tb = __PACKAGE__->builder;
  
  my $ok;
  my $out = capture_merged { $ok = $cc->try_compile_run(ref($args) eq 'HASH' ? %$args : $args) };
  
  $tb->ok($ok, $message);
  if(!$ok || $output eq 'diag')
  {
    $tb->diag($out);
  }
  elsif($output eq 'note')
  {
    $tb->note($out);
  }
  
  $ok;
}


sub compile_ok ($;$)
{
  $warn_deprecated->();
  my($args, $message) = @_;
  $message ||= "compile ok";
  $args = ref $args ? $args : { source => $args };
  my $cc = cc();
  my $tb = __PACKAGE__->builder;

  my($fh, $filename) = File::Temp::tempfile("ccheckerXXXXX", SUFFIX => '.c');
  print $fh $args->{source};
  close $fh;
  my $obj;
  my %compile = ( source => $filename );
  $compile{extra_compiler_flags} = $args->{extra_compiler_flags} if defined $args->{extra_compiler_flags};
  my $err;
  my $out = capture_merged { $obj = eval { $cc->compile(%compile) }; $err = $@ };
  
  my $ok = !!$obj;
  unlink $filename if $ok;
  unlink $obj if defined $obj && -f $obj;
  $tb->ok($ok, $message);
  if(!$ok || $output eq 'diag')
  {
    $tb->diag($out);
  }
  elsif($output eq 'note')
  {
    $tb->note($out);
  }
  
  $tb->diag($err) if $err;
  
  $ok;
}


sub compile_with_alien ($)
{
  $warn_deprecated->();
  my $alien = shift;
  $alien = $alien->new unless ref $alien;

  if($alien->can('dist_dir'))
  {
    my $dir = eval { File::Spec->catdir($alien->dist_dir, 'lib') };
    unshift @LD_LIBRARY_PATH, $dir if defined $dir && -d $dir;
  }
  
  my $tdir = File::Spec->catdir($FindBin::Bin, File::Spec->updir, '_test');
  if(-d $tdir)
  {
    cc->push_extra_compiler_flags(map {
      /^-I(.*)$/ ? ("-I".File::Spec->catdir($tdir, $1), $_) : ($_)
    } shellwords $alien->cflags);
    cc->push_extra_linker_flags(map {
      /^-L(.*)$/ ? ( map { push @LD_LIBRARY_PATH, $_; "-L$_" } File::Spec->catdir($tdir, $1), $_) : ($_)
    } shellwords $alien->libs);
  }
  else
  {
    cc->push_extra_compiler_flags(shellwords $alien->cflags);
    cc->push_extra_linker_flags(shellwords $alien->libs);
  }

  return;
}


sub compile_output_to_nowhere ()
{
  $warn_deprecated->();
  $output = '';
}


sub compile_output_to_diag ()
{
  $warn_deprecated->();
  $output = 'diag';
}


sub compile_output_to_note ()
{
  $warn_deprecated->();
  $output = 'note';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::CChecker - Test-time utilities for checking C headers, libraries, or OS features (DEPRECATED)

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Alien::Foo;
 use Test::CChecker;
 
 compile_with_alien 'Alien::Foo';
 
 compile_run_ok <<C_CODE, "basic compile test";
 int
 main(int argc, char *argv[])
 {
   return 0;
 }
 C_CODE

=head1 DESCRIPTION

B<DEPRECATED>: The intention of this module was always to test L<Alien> modules
(both L<Alien::Base> based and non-L<Alien::Base> based modules).  It has a number
of shortcomings that I believe to be better addressed by L<Test::Alien>,
so please consider using that for new projects, or even migrating existing code.

This module is a very thin convenience wrapper around L<ExtUtils::CChecker> to make
it useful for use in a test context.  It is intended for use with Alien modules
which need to verify that libraries work as intended with the Compiler and
flags used by Perl to build XS modules.

By default this module is very quiet, hiding all output using L<Capture::Tiny>
unless there is a failure, in which case you will see the commands, flags and
output used.

=head1 FUNCTIONS

All documented functions are exported into your test's namespace

=head2 cc

 my $cc = cc;

Returns the ExtUtils::CChecker object used for testing.

This is mainly useful for adding compiler or linker flags:

 cc->push_extra_compiler_flags('-DFOO=1');
 cc->push_extra_linker_flags('-L/foo/bar/baz', '-lfoo')

=head2 compile_run_ok

 compile_run_ok $c_source;
 compile_run_ok $c_source, $message;

 compile_run_ok {
   source => $c_source,
   extra_compiler_flags => \@cflags,
   extra_linker_flags => \@libs,
 }, $message;

This test attempts to compile the given c source and passes if it
runs with return value of zero.  The first argument can be either
a string containing the C source code, or a hashref (which will
be passed unmodified as a hash to L<ExtUtils::CChecker> C<try_compile_run>).

If the test fails, then the complete output will be reported using
L<Test::More> C<diag>.

You can have it report the output on success with L</compile_output_to_diag>
or L</compile_output_to_note>.

In addition to the pass/fail and diagnostic output, this function
will return true or false on success and failure respectively.

=head2 compile_ok

 compile_ok $c_source, $message;

 compile_ok {
   source => $c_source,
   extra_compiler_flags => \@cflags,
 }, $message;

This is like L</compile_run_ok>, except it stops after compiling and
does not attempt to link or run.

=head2 compile_with_alien

 use Alien::Foo;
 compile_with_alien 'Alien::Foo';

Specifies an Alien module to use to get compiler flags and libraries.  You
may pass in either the name of the class (it must already be loaded), or
an instance of that class.  The instance of the Alien class is expected to
implement C<cflags> and C<libs> methods that return the compiler and library
flags respectively.

If you are testing an Alien module after it has been built, but before it has
been installed (for example if you are writing the test suite FOR the Alien
module itself), you need to install to a temporary directory named C<_test>.
If you are using L<Alien::Base>, the easiest way to do this is to add a 
C<make install> with C<DISTDIR> set to C<_test>:

 Alien::Base::Module::Build->new(
   ...
   "alien_build_commands" => [
     "%pconfigure --prefix=%s",
     "make",
     "make DESTDIR=`pwd`/../../_test install",
   ],
   ...
 )->create_build_script;

or if you are using L<Dist::Zilla>, something like this:

 [Alien]
 build_command = %pconfigure --prefix=%s --disable-bsdtar --disable-bsdcpio
 build_command = make
 build_command = make DESTDIR=`pwd`/../../_test install

=head2 compile_output_to_nowhere

 compile_output_to_nowhere

Do not report output unless there is a failure.  This is the default behavior.

=head2 compile_output_to_diag

 compile_output_to_diag;

Report output using L<Test::More> C<diag> on success (output is always reported on failure using C<daig>).

=head2 compile_output_to_note

 compile_output_to_note;

Report output using L<Test::More> C<note> on success (output is always reported on failure using C<diag>).

=head1 SEE ALSO

Please consider using the official replacement:

L<Test::Alien>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
