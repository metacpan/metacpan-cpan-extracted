use strict;
use warnings;

use Module::Build;
use ExtUtils::PkgConfig;

my $NEED_TERMKEY_VERSION = "0.16";
my $URL = "http://www.leonerd.org.uk/code/libtermkey/";

my $cflags;
my $libs;

if( eval { local *STDERR;
           open STDERR, ">", "/dev/null"; 
           ExtUtils::PkgConfig->find("termkey"); } and
        ExtUtils::PkgConfig->atleast_version("termkey", $NEED_TERMKEY_VERSION ) ) {
   $cflags = ExtUtils::PkgConfig->cflags("termkey");
   $libs   = ExtUtils::PkgConfig->libs("termkey");
}
elsif( eval { require Alien::libtermkey } and
         Alien::libtermkey->atleast_version( $NEED_TERMKEY_VERSION ) ) {
   $cflags = Alien::libtermkey->cflags;
   $libs   = Alien::libtermkey->libs;
}
else {
   die "OS unsupported - libtermkey unavailable\n" . <<"EOF";

This module requires libtermkey of at least version $NEED_TERMKEY_VERSION.

Please obtain it by either:

  1) Installing it from your OS vendor if it is supplied,

  2) Installing the Alien::libtermkey CPAN module, or

  3) Downloading and building it from:
     $URL

EOF
}

my $build = Module::Build->new(
   module_name => 'Term::TermKey',
   extra_compiler_flags => [ split( m/ +/, $cflags ) ],
   extra_linker_flags   => [ split( m/ +/, $libs ) ],
   configure_requires => {
      'Exporter' => '5.57',
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
   },
   # Note to downstream package maintainers:
   # We don't -actually- depend directly on this Alien module but it's far
   # easier to get CPAN smoketest machines to install it this way than
   # anything else.
   # This dependencies can be omitted if libtermkey is installed by some
   # other mechanism
   meta_merge => {
      configure_requires => {
         'Alien::libtermkey' => '0.13',
      },
   },
   build_requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
