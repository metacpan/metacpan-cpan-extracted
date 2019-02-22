use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Term::Terminfo',
   configure_requires => {
      'ExtUtils::CChecker' => '0.02',
      'Module::Build' => '0.4004',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

if( $build->try_pkgconfig( "unibilium",
      atleast_version => "0.1.0",
      alien           => "Alien::unibilium",
      no_late_alien   => 1,
   ) ) {
   $build->push_extra_compiler_flags( qw( -DHAVE_UNIBILIUM ) );
}
elsif( defined( my $cc = eval {
      require ExtUtils::CChecker;

      my $cc = ExtUtils::CChecker->new;

      print "Looking for <term.h>...\n";
      $cc->find_include_dirs_for(
         diag => "no term.h",
         dirs => [ [], [qw(/usr/include/ncurses)] ],
         source => q{
            #include <stdio.h>
            #include <term.h>
            int main(int argc, char *argv[]) {
              TERMINAL *term;
              return 0;
            }
         }
      );

      print "Looking for curses library...\n";
      $cc->find_libs_for(
         diag => "cannot find lib curses",
         libs => [ "ncurses", "curses" ],
         source => q{
            #include <stdlib.h>
            #include <term.h>
            int main(int argc, char *argv[]) {
              setupterm(NULL, 0, NULL);
              return 0;
            }
         }
      );

      $cc;
   } ) ) {
   $build->include_dirs( $cc->include_dirs );
   $build->push_extra_compiler_flags( @{ $cc->extra_compiler_flags } );
   $build->push_extra_linker_flags  ( @{ $cc->extra_linker_flags   } );
}
else {
   $build->use_late_alien( "Alien::unibilium",
      atleast_version => "0.1.0",
      alien_version   => "0.14",
   );
   $build->push_extra_compiler_flags( qw( -DHAVE_UNIBILIUM ) );
}

$build->create_build_script;
