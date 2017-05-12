package SOOTBuilder;
use strict;
use warnings;
use File::Spec;
use Carp;
use Config;

use inc::latest 'Module::Build';
use inc::latest 'ExtUtils::ParseXS';
use ExtUtils::Typemaps;
use base 'Module::Build';
use File::Find ();

use Alien::ROOT;
use vars '$Alien';
BEGIN {
  $Alien = Alien::ROOT->new;
  if ($Alien->features !~ /\bexplicitlink\b/) {
    Carp::croak(
      "The version of ROOT that was found was not built with the"
      . " --explicitlink option, which is required for SOOT"
    );
  }
  $Alien->setup_environment;
}


##################

sub ACTION_code {
  my $self = shift;
  $self->depends_on('build_soot');

  $self->SUPER::ACTION_code(@_);
}

sub ACTION_build_dictionaries {
  my $self = shift;

  my $outfile = File::Spec->catfile('src', 'SOOTDictionary.cc');
  my @infiles = (
    File::Spec->catfile('src', 'TExecImpl.h'),
    File::Spec->catfile('src', 'LinkDef.h'),
  );
  my $latest = _latest_file_mod_time(@infiles);
  return if -f $outfile and -M $outfile < $latest;

  my $bindir = $Alien->bindir;
  my $rootcint = File::Spec->catfile($bindir, 'rootcint');
  if (not -x $rootcint) {
    die "Can't find or exec rootcint at $rootcint";
  }

  #my @dictfiles = glob(File::Spec->catfile('src', 'SOOTDictionary.*'));
  #unlink($_) for @dictfiles;

  print "Generating ROOT dictionary...\n";
  my @cmd = (
    $rootcint,
    '-f',
    $outfile,
    '-c',
    @infiles
  );
  system(@cmd)
    and die "Failed to run '@cmd'. Exit value: " . ($?>>8);
}

sub ACTION_build_soot {
  my $self = shift;
  $self->depends_on('gen_constants');
  $self->depends_on('gen_xsp_include');
  $self->depends_on('build_dictionaries');
  $self->depends_on('merge_typemaps');

  #my $p = $self->{properties};
  #local $p->{extra_compiler_flags} = [
  #  @{$self->extra_compiler_flags},
  #  '-Itools/puic',
  #  '-Itools/puic/perl',
  #];


  my @objects;
  my $files = $self->_find_file_by_type('cc', 'src');
  foreach my $file (keys %$files) {
    push(@objects, $self->compile_c($file));
  }

  #my $script_dir = File::Spec->catdir($self->blib, 'script');
  #File::Path::mkpath( $script_dir );

  #my $puic = File::Spec->catfile($script_dir, '/puic4');

  #unless($self->up_to_date(\@objects, [$puic])) {
  #  $self->_cbuilder->link_executable(
  #    exe_file => $puic,
  #    objects => \@objects,
  #    extra_linker_flags => $p->{extra_linker_flags},
  #  );
  #}

  $self->depends_on('config_data');
  $self->depends_on('gen_examples');
}

sub ACTION_gen_xsp_include {
  my $self = shift;
  #system($^X, '-I.', '-Iinc', File::Spec->catfile('buildtools', 'gen_root_xsp_include.pl')) and die $!;
  my $xsp_dir = 'ROOT_XSP';
  my $xsp_dir_compile = File::Spec->catdir(File::Spec->updir, 'ROOT_XSP');

  my @outfiles = (
    'rootclasses.xsinclude',
    'rootclasses.h',
    'rootclasses.map',
  );

  opendir my $dh, $xsp_dir or die $!;
  my @infiles = grep -f File::Spec->catfile($xsp_dir, $_), grep /\.xsp$/i, readdir($dh);

  my $latest_in    = _latest_file_mod_time(map File::Spec->catfile($xsp_dir, $_), @infiles);
  my $earliest_out = _earliest_file_mod_time(@outfiles);

  return 1 if defined $earliest_out and defined $latest_in and $earliest_out < $latest_in;

  print "Regenerating the XS++ include files...\n";
  open my $oh_xs, '>', 'rootclasses.xsinclude' or die $!;
  open my $oh_h, '>', 'rootclasses.h' or die $!;
  unlink('rootclasses.map');
  my $typemap = ExtUtils::Typemaps->new(file => 'rootclasses.map');

  while(defined(my $file = shift @infiles)) {
    next if $file !~ /^(.+)\.xsp$/i;
    my $basename = $1;
    my $full = File::Spec->catfile($xsp_dir_compile, $file);
    print $oh_xs <<ENDXSCODE;

INCLUDE_COMMAND: \$^X -MExtUtils::XSpp::Cmd -e xspp -- -t ../typemap.xsp $full

ENDXSCODE
    print $oh_h <<ENDHCODE;
#include <$basename.h>
ENDHCODE
    
    $typemap->add_typemap(ctype => "$basename *", xstype => 'O_OBJECT');
  }

  $typemap->write();
}

sub ACTION_gen_constants {
  my $self = shift;
  print "Regenerating constants...\n";
  system($^X, '-I.', '-Iinc', File::Spec->catfile('buildtools', 'genconstants.pl')) and die $!;
}

sub ACTION_gen_examples {
  my $self = shift;
  my @files;
  File::Find::find(
    sub { push @files, $File::Find::name if /\.pod$/i; },
    'lib'
  );
  chmod(0644, $_) for @files;

  system($^X, '-I.', '-Iinc', File::Spec->catfile('buildtools', 'gen_examples.pl')) and die $!;

  #chmod(0444, $_) for @files;
}

our @Typemaps = qw(
  perlobject.map
  custom.map
  rootclasses.map
  root_simple_types.map
);

sub ACTION_merge_typemaps {
  my $self = shift;
  $self->depends_on('gen_xsp_include');

  my $typemap = 'typemap';
  if (-f $typemap) { # lazy!
    my $latest_file = _latest_file(@Typemaps, $typemap);
    if ($latest_file eq $typemap) {
      return 1;
    }
    unlink $typemap;
  }

  print "Merging custom typemaps...\n";
  sleep 1;
  my $outmap = ExtUtils::Typemaps->new(file => 'typemap');
  foreach my $typemap_file (@Typemaps) {
    print "... merging $typemap_file\n";
    $outmap->merge(typemap => ExtUtils::Typemaps->new(file => $typemap_file));
  }
  print "Done merging typemaps.\n";
  $outmap->write();
  return 1;
}

# utilities...
##############
sub striprun {
  my $inc = `@_`;
  chomp $inc;
  return $inc;
}

# check if we can run some command (From Module::Install::Can)
sub can_run {
  my ($cmd) = @_;

  my $_cmd = $cmd;
  return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $_[1]);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

# Return the name of the newest file in the input list
sub _latest_file {
  my $latest;
  my $latest_file;
  foreach my $file (@_) {
    my $m = -M $file;
    next if not defined $m;
    $latest = $m, $latest_file = $file if not defined $latest or $m < $latest;
  }
  return $latest_file;
}

# Return the -M time of the newest file in the input list
sub _latest_file_mod_time {
  my $latest;
  foreach my $file (@_) {
    my $m = -M $file;
    next if not defined $m;
    $latest = $m if not defined $latest or $m < $latest;
  }
  return $latest;
}

# Return the -M time of the oldest file in the input list
sub _earliest_file_mod_time {
  my $earliest;
  foreach my $file (@_) {
    my $m = -M $file;
    next if not defined $m;
    $earliest = $m if not defined $earliest or $m > $earliest;
  }
  return $earliest;
}
