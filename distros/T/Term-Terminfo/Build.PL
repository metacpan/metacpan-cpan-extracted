use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new;

if( eval { require ExtUtils::PkgConfig } and
    ExtUtils::PkgConfig->atleast_version( unibilium => "0.1.0" ) ) {
   $cc->define( "HAVE_UNIBILIUM" ); # Not an officially exported EU::CC method

   $cc->push_extra_compiler_flags( split ' ', ExtUtils::PkgConfig->cflags( "unibilium" ) );
   $cc->push_extra_linker_flags  ( split ' ', ExtUtils::PkgConfig->libs( "unibilium" ) );
}
else {
   $cc->find_include_dirs_for(
      diag => "no term.h",
      dirs => [ [], [qw(/usr/include/ncurses)] ],
      source => <<'EOF' );
         #include <stdio.h>
         #include <term.h>
         int main(int argc, char *argv[]) {
           TERMINAL term;
           char *name = term._termname;
           return 0;
         }
EOF

   $cc->find_libs_for(
      diag => "cannot find lib curses",
      libs => [ "ncurses", "curses" ],
      source => <<'EOF' );
         #include <stdlib.h>
         #include <term.h>
         int main(int argc, char *argv[]) {
           setupterm(NULL, 0, NULL);
           return 0;
         }
EOF
}

my $build = $cc->new_module_build(
   module_name => 'Term::Terminfo',
   requires => {
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.02',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
