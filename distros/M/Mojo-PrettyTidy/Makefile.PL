use v5.40.0;
use common::sense;

use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use File::Spec;
use File::HomeDir;

my $install_home_config = 0;
my $force_home_config   = 0;

my $home   = $ENV{HOME} // die "HOME is not set\n";
my $target = File::Spec->catfile( $ENV{HOME} // die( "HOME is not set\n" ),
                                  '.mojo-prettidy.json' );

@ARGV = grep {
  if    ( $_ eq '--install-home-config' ) { $install_home_config = 1; 0 }
  elsif ( $_ eq '--force-home-config' )   { $force_home_config = 1; 0 }
  else                                    {1}
} @ARGV;

die "--force-home-config requires --install-home-config\n"
    if $force_home_config && !$install_home_config;

WriteMakefile(
   NAME         => 'Mojo::PrettyTidy',
   VERSION_FROM => 'lib/Mojo/PrettyTidy.pm',
   ABSTRACT     => 'Conservative tidy tool for Mojolicious .html.ep templates',
   AUTHOR       => 'Harry Bennett',
   LICENSE      => 'perl',
   MIN_PERL_VERSION => '5.040000',
   EXE_FILES        => ['bin/mojo-prettytidy'],
   PREREQ_PM        => {
                 'common::sense'          => 0,
                 'Getopt::Long'           => 0,
                 'Pod::Usage'             => 0,
                 'Mojolicious'            => 0,
                 'JavaScript::Beautifier' => 0,
                 'Perl::Tidy'             => 0,
   },
   TEST_REQUIRES => {
                     'Test::More' => 0,
                     'File::Temp' => 0,
   },
   META_MERGE => {
     resources => {repository => 'https://github.com/Harryb382003/PrettyTidy',},
   }, );

if ( $install_home_config ) {
  my $source = '.mojo-prettytidy.json';

  die "Cannot install home config: '$source' not found\n"
      unless -f $source;

  my $home = File::HomeDir->my_home
      or die "Cannot determine home directory\n";

  my $target = File::Spec->catfile( $home, '.mojo-prettytidy.json' );

  if ( -e $target && !$force_home_config ) {
    die <<"MSG";
Home config already exists at:
  $target

Refusing to overwrite.
Re-run with:
  perl Makefile.PL --install-home-config --force-home-config
MSG
  }

  copy( $source, $target ) or die "Failed to copy '$source' to '$target': $!";

  print "Installed home config to $target\n";
}
