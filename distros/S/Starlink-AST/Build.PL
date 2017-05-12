use strict;
use warnings;
use File::Spec;
use Module::Build;
use Config;

# On OSX we need to restrict the exported symbols in the bundle
# to prevent NDF linking against libast clashing with NDF loading
# Starlink::AST
my $linkflags = "";
if ($^O eq 'darwin') {
  $linkflags = "-exported_symbols_list exported_symbols.lis";
}

# On MSWin32 we are getting test failures indicating that sscanf
# is not working. Experiment with using the internal sscanf implementation.
my @defines;
if ($^O eq 'MSWin32') {
  push(@defines, "-DHAVE_NONANSI_SSCANF=1",
                 "-Dcminpack_EXPORTS");
}

my $file = File::Spec->catfile( "lib", "Starlink", "AST.pm" );

my $build = Module::Build->new
  (
   module_name => "Starlink::AST",
   license => "gpl_2",
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   meta_merge => {
               resources =>  {
                              repository => 'https://github.com/Starlink/perl-Starlink-AST.git',
                             },
                },
   recommends => {
                  "Tk" => 0,
                  "Tk::Zinc" => 0,
                  "Astro::FITS::CFITSIO" => 0,
                  "Astro::FITS::Header" => 0,
                 },
   build_requires => {
                      "perl" => 5.008,
                      "Test::More" => 0,
                      "Test::Deep" => 0,
                      "Test::Number::Delta" => 0,
                     },
   configure_requires => {
                          "Module::Build" => 0.3604,
                         },
   c_source => [ "src", "ast" ],
   extra_compiler_flags => [ "-Iextsrc", # we do not build these directly
                             "-DHAVE_DECL_ISNAN=1", # Assume we have NaN
                             "-DSIZEOF_LONG=". $Config{longsize},
                             "-DSIZEOF_LONG_LONG=". $Config{longlongsize},
                             @defines,
                           ],
   extra_linker_flags => $linkflags,
  );

$build->create_build_script;

