use strict;
use warnings;

use Module::Build;
use ExtUtils::PkgConfig;

my %build_args;

sub eu_pc_atleast_version
{
   my ( $module, $ver ) = @_;

   print "Checking pkg-config $module --atleast_version $ver... ";

   # Silence its scary errors
   open OLDERR, ">&", \*STDERR or die "Cannot dup STDERR: $!";
   open STDERR, ">>", "/dev/null" or die "Cannot reopen STDERR - $!";

   my $ret = eval { ExtUtils::PkgConfig->atleast_version( $module, $ver ) };

   open STDERR, ">&", OLDERR;
   close OLDERR;

   print $ret ? "yes\n" : "no\n";

   return $ret;
}

sub add_cflags_libs
{
   my ( $modname ) = @_;

   my $cflags = ExtUtils::PkgConfig->cflags( $modname );
   my $libs   = ExtUtils::PkgConfig->libs( $modname );

   push @{ $build_args{extra_compiler_flags} }, split( m/ +/, $cflags );

   push @{ $build_args{extra_linker_flags} }, split( m/ +/, $libs );
}

eu_pc_atleast_version( "vterm", 0 ) or
   die "OS unsupported - need libvterm";

add_cflags_libs "vterm";

my $build = Module::Build->new(
   module_name => 'Term::VTerm',
   %build_args,
   requires => {
   },
   configure_requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
